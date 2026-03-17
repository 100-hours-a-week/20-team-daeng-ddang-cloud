const https = require('https');

/**
 * Caddy Rate Limit Verification Test
 *
 * Zone 1 (ip_limit):        IP당 분당 300회 제한
 * Zone 2 (user_path_limit): Authorization+Path 조합당 분당 100회 제한
 *
 * 테스트 시나리오:
 *   1) 단일 경로 집중 요청 → user_path_limit(100회) 먼저 걸리는지 확인
 *   2) 경로 분산 요청     → ip_limit(300회) 걸리는지 확인
 *   3) SlowLoris 방어     → 느린 전송 시 서버가 연결을 끊는지 확인
 */

const CONFIG = {
    BASE_URL: 'dev.daeng-map.store',
    ACCESS_TOKEN: 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiaWF0IjoxNzczMDE1ODQ3LCJleHAiOjE3NzMxOTU4NDcsInN0YXR1cyI6IkFDVElWRSJ9.USNG2AqxAl7RwuwSgiJ_pUYUdvPqdCB-n3oR3How0no',
    CONCURRENCY: 10,
};

const APIS = [
    { name: 'Get Blocks',  method: 'GET', path: '/api/v3/blocks?lat=38.0691&lng=127.7745&radius=1000' },
    { name: 'Get Regions', method: 'GET', path: '/api/v3/regions?regionId=23' },
    { name: 'Update Dog',  method: 'PATCH', path: '/api/v3/users/dogs', body: JSON.stringify({
        name: "만보", breedId: 2, birthDate: "2023-12-22",
        isBirthUnknown: true, regionId: 23, gender: "MALE",
        isNeutered: true, weight: 7.5,
        profileImageUrl: "https://cdn.example.com/dogs/choco.png",
    })},
];

// ─── 공통 요청 함수 ────────────────────────────────────────────

function sendRequest(api) {
    return new Promise((resolve) => {
        const startTime = Date.now();
        const options = {
            hostname: CONFIG.BASE_URL,
            path: api.path,
            method: api.method,
            headers: {
                'Authorization': `Bearer ${CONFIG.ACCESS_TOKEN}`,
                'Content-Type': 'application/json',
                'User-Agent': 'RateLimitTest-Agent/1.0',
            },
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                resolve({
                    name: api.name,
                    statusCode: res.statusCode,
                    responseTime: Date.now() - startTime,
                });
            });
        });

        req.on('error', (err) => {
            resolve({
                name: api.name,
                error: err.message,
                responseTime: Date.now() - startTime,
            });
        });

        if (api.body) req.write(api.body);
        req.end();
    });
}

// ─── 테스트 1: user_path_limit 검증 ────────────────────────────
// 단일 경로에 집중 요청 → 100회 부근에서 429 발생해야 함

async function testUserPathLimit() {
    const TARGET_API = APIS[0]; // Get Blocks 단일 경로
    const TOTAL_REQUESTS = 150;

    console.log('='.repeat(60));
    console.log('[테스트 1] user_path_limit 검증 (단일 경로 집중)');
    console.log(`  경로: ${TARGET_API.path}`);
    console.log(`  총 요청: ${TOTAL_REQUESTS}회 (동시 ${CONFIG.CONCURRENCY}개)`);
    console.log('='.repeat(60));

    const results = [];
    let sent = 0;

    // 배치 단위로 동시 요청 전송
    while (sent < TOTAL_REQUESTS) {
        const batchSize = Math.min(CONFIG.CONCURRENCY, TOTAL_REQUESTS - sent);
        const batch = Array.from({ length: batchSize }, () => sendRequest(TARGET_API));
        const batchResults = await Promise.all(batch);

        for (const r of batchResults) {
            sent++;
            results.push({ ...r, seq: sent });
            const status = r.error ? `ERROR: ${r.error}` : r.statusCode;
            if (r.statusCode === 429) {
                console.log(`  #${sent} | ${r.name} | ${status} | ${r.responseTime}ms  <-- RATE LIMITED`);
            }
        }
    }

    printResult('user_path_limit', results, 100);
}

// ─── 테스트 2: ip_limit 검증 ───────────────────────────────────
// 여러 경로에 분산 요청 → user_path_limit은 안 걸리고 ip_limit(300회)에서 걸려야 함

async function testIpLimit() {
    const TOTAL_REQUESTS = 400;

    console.log('\n' + '='.repeat(60));
    console.log('[테스트 2] ip_limit 검증 (경로 분산)');
    console.log(`  총 요청: ${TOTAL_REQUESTS}회 (동시 ${CONFIG.CONCURRENCY}개)`);
    console.log(`  경로 ${APIS.length}개에 라운드로빈 분산`);
    console.log('='.repeat(60));

    const results = [];
    let sent = 0;

    while (sent < TOTAL_REQUESTS) {
        const batchSize = Math.min(CONFIG.CONCURRENCY, TOTAL_REQUESTS - sent);
        const batch = Array.from({ length: batchSize }, (_, i) => {
            const api = APIS[(sent + i) % APIS.length];
            return sendRequest(api);
        });
        const batchResults = await Promise.all(batch);

        for (const r of batchResults) {
            sent++;
            results.push({ ...r, seq: sent });
            const status = r.error ? `ERROR: ${r.error}` : r.statusCode;
            if (r.statusCode === 429) {
                console.log(`  #${sent} | ${r.name} | ${status} | ${r.responseTime}ms  <-- RATE LIMITED`);
            }
        }
    }

    printResult('ip_limit', results, 300);
}

// ─── 테스트 3: SlowLoris 방어 검증 ─────────────────────────────
// 헤더를 아주 천천히 보내 연결을 점유 → Caddy의 read_header 5s 타임아웃으로 끊겨야 함

async function testSlowLoris() {
    const net = require('net');
    const SLOW_CONNECTIONS = 5;
    const HEADER_DELAY_MS = 2000; // 헤더 조각 간 2초 간격

    console.log('\n' + '='.repeat(60));
    console.log('[테스트 3] SlowLoris 방어 검증');
    console.log(`  느린 연결 ${SLOW_CONNECTIONS}개 시도`);
    console.log(`  헤더 조각 전송 간격: ${HEADER_DELAY_MS}ms`);
    console.log(`  예상: Caddy read_header 5s 타임아웃으로 연결 종료`);
    console.log('='.repeat(60));

    const results = await Promise.all(
        Array.from({ length: SLOW_CONNECTIONS }, (_, i) => slowLorisConnection(i + 1, HEADER_DELAY_MS))
    );

    const killed = results.filter(r => r.closedByServer).length;
    const survived = results.filter(r => !r.closedByServer).length;

    console.log(`\n  결과: 서버가 끊은 연결 ${killed}/${SLOW_CONNECTIONS}`);
    console.log(`  방어 ${killed === SLOW_CONNECTIONS ? 'SUCCESS' : 'PARTIAL'}`);
}

function slowLorisConnection(id, delayMs) {
    return new Promise((resolve) => {
        const tls = require('tls');
        const socket = tls.connect(443, CONFIG.BASE_URL, { servername: CONFIG.BASE_URL }, () => {
            // 헤더를 조각조각 천천히 전송
            const headerParts = [
                `GET /api/v3/blocks HTTP/1.1\r\n`,
                `Host: ${CONFIG.BASE_URL}\r\n`,
                `User-Agent: SlowLoris-Test\r\n`,
                `Accept: */*\r\n`,
                // 의도적으로 \r\n\r\n (헤더 종료)를 보내지 않고 계속 지연
            ];

            let partIndex = 0;
            const startTime = Date.now();

            const interval = setInterval(() => {
                if (partIndex < headerParts.length) {
                    socket.write(headerParts[partIndex]);
                    console.log(`  [SlowLoris #${id}] 헤더 조각 ${partIndex + 1}/${headerParts.length} 전송 (${Date.now() - startTime}ms)`);
                    partIndex++;
                } else {
                    // 헤더 다 보낸 뒤에도 종료 시그널(\r\n) 안 보내고 무의미한 헤더 계속 전송
                    socket.write(`X-Padding-${Date.now()}: ${'A'.repeat(20)}\r\n`);
                    console.log(`  [SlowLoris #${id}] 패딩 헤더 전송 (${Date.now() - startTime}ms)`);
                }
            }, delayMs);

            socket.on('close', () => {
                clearInterval(interval);
                const elapsed = Date.now() - startTime;
                console.log(`  [SlowLoris #${id}] 연결 종료 (${elapsed}ms)`);
                resolve({ id, closedByServer: true, elapsed });
            });

            socket.on('error', (err) => {
                clearInterval(interval);
                const elapsed = Date.now() - startTime;
                console.log(`  [SlowLoris #${id}] 에러: ${err.message} (${elapsed}ms)`);
                resolve({ id, closedByServer: true, elapsed });
            });

            // 안전장치: 30초 지나면 강제 종료
            setTimeout(() => {
                clearInterval(interval);
                socket.destroy();
                resolve({ id, closedByServer: false, elapsed: Date.now() - startTime });
            }, 30000);
        });

        socket.on('error', (err) => {
            console.log(`  [SlowLoris #${id}] 연결 실패: ${err.message}`);
            resolve({ id, closedByServer: true, elapsed: 0 });
        });
    });
}

// ─── 결과 출력 ─────────────────────────────────────────────────

function printResult(zoneName, results, expectedLimit) {
    const success = results.filter(r => r.statusCode >= 200 && r.statusCode < 300).length;
    const rateLimited = results.filter(r => r.statusCode === 429).length;
    const errors = results.filter(r => r.error || (r.statusCode >= 400 && r.statusCode !== 429)).length;
    const avgTime = results.length > 0
        ? Math.round(results.reduce((sum, r) => sum + r.responseTime, 0) / results.length)
        : 0;

    // 429가 처음 발생한 요청 번호
    const first429 = results.find(r => r.statusCode === 429);
    const first429Seq = first429 ? first429.seq : 'N/A';

    console.log(`\n  --- ${zoneName} 결과 ---`);
    console.log(`  총 요청:          ${results.length}`);
    console.log(`  성공 (2xx):       ${success}`);
    console.log(`  Rate Limited(429): ${rateLimited}`);
    console.log(`  기타 에러:        ${errors}`);
    console.log(`  평균 응답시간:    ${avgTime}ms`);
    console.log(`  첫 429 발생:      #${first429Seq} (예상: ~${expectedLimit})`);

    if (rateLimited > 0) {
        console.log(`  판정: PASS - Rate Limit 정상 동작`);
    } else {
        console.log(`  판정: FAIL - 429 응답 없음. Rate Limit 미적용 가능성`);
    }
}

// ─── 실행 ──────────────────────────────────────────────────────

async function main() {
    const args = process.argv.slice(2);
    const testNum = args[0];

    console.log(`\nCaddy Rate Limit & SlowLoris 방어 테스트`);
    console.log(`대상: ${CONFIG.BASE_URL}\n`);

    if (!testNum || testNum === '1') {
        await testUserPathLimit();
    }

    if (!testNum || testNum === '2') {
        // 테스트 1과 분리하기 위해 윈도우 리셋 대기
        if (!testNum) {
            console.log('\n--- ip_limit 테스트를 위해 60초 대기 (윈도우 리셋) ---');
            await new Promise(r => setTimeout(r, 60000));
        }
        await testIpLimit();
    }

    if (!testNum || testNum === '3') {
        await testSlowLoris();
    }

    console.log('\n모든 테스트 완료.');
}

main().catch(console.error);
