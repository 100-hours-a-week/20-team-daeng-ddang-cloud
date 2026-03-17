const https = require('https');
const fs = require('fs');
const path = require('path');

/**
 * Staged Load Test for K8s resource sizing
 * 단계별로 동시 요청 수를 올리며 성능 변화를 측정합니다.
 * CloudWatch/Prometheus에서 각 단계별 서버 CPU/메모리를 함께 확인하세요.
 */

const CONFIG = {
    BASE_URL: "daeng-map.store",
    PATH: "/footprints/walk/60",
    STAGES: [
        { concurrency: 50,   duration: 30 },
        { concurrency: 100,  duration: 30 },
        { concurrency: 200,  duration: 30 },
        { concurrency: 500,  duration: 30 },
        { concurrency: 1000, duration: 30 },
    ],
    COOLDOWN_SECONDS: 10,
};

async function sendRequest() {
    return new Promise((resolve) => {
        const startTime = Date.now();
        const req = https.request({
            hostname: CONFIG.BASE_URL,
            path: CONFIG.PATH,
            method: 'GET',
            headers: { 'User-Agent': 'LoadTest-Agent/1.0' }
        }, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    responseTime: Date.now() - startTime,
                    bodyLength: body.length
                });
            });
        });

        req.on('error', (err) => {
            resolve({
                error: err.message,
                responseTime: Date.now() - startTime
            });
        });

        req.end();
    });
}

async function worker(workerId, endTime, results) {
    let requestCount = 0;
    while (Date.now() < endTime) {
        const result = await sendRequest();
        result.id = `${workerId}-${++requestCount}`;
        results.push(result);
    }
}

function percentile(sortedArr, p) {
    const idx = Math.ceil((p / 100) * sortedArr.length) - 1;
    return sortedArr[Math.max(0, idx)];
}

function analyzeResults(results, durationMs) {
    const total = results.length;
    const success = results.filter(r => r.statusCode >= 200 && r.statusCode < 400).length;
    const errors = results.filter(r => r.error || r.statusCode >= 400).length;
    const rps = (total / (durationMs / 1000)).toFixed(2);

    const times = results.map(r => r.responseTime).sort((a, b) => a - b);
    const avgTime = total > 0 ? Math.round(times.reduce((s, t) => s + t, 0) / total) : 0;

    const statusCodes = {};
    results.forEach(r => {
        const key = r.error ? 'ERROR' : r.statusCode;
        statusCodes[key] = (statusCodes[key] || 0) + 1;
    });

    return {
        total, success, errors, rps, avgTime,
        minTime: times[0] || 0,
        maxTime: times[times.length - 1] || 0,
        p50: percentile(times, 50),
        p90: percentile(times, 90),
        p95: percentile(times, 95),
        p99: percentile(times, 99),
        errorRate: total > 0 ? ((errors / total) * 100).toFixed(1) : '0.0',
        statusCodes
    };
}

async function runStage(stage, stageNum, totalStages) {
    const { concurrency, duration } = stage;
    const startTime = Date.now();
    const endTime = startTime + (duration * 1000);

    console.log(`\n[${'='.repeat(50)}]`);
    console.log(`  STAGE ${stageNum}/${totalStages} | Concurrency: ${concurrency} | Duration: ${duration}s`);
    console.log(`  Started at: ${new Date().toISOString()}`);
    console.log(`[${'='.repeat(50)}]`);

    const results = [];
    const workers = [];

    for (let i = 1; i <= concurrency; i++) {
        workers.push(worker(i, endTime, results));
    }

    await Promise.all(workers);

    const actualDuration = Date.now() - startTime;
    const stats = analyzeResults(results, actualDuration);

    console.log(`  Requests: ${stats.total} | RPS: ${stats.rps} | Errors: ${stats.errorRate}%`);
    console.log(`  Avg: ${stats.avgTime}ms | P50: ${stats.p50}ms | P95: ${stats.p95}ms | P99: ${stats.p99}ms`);

    return { concurrency, duration, actualDuration, ...stats };
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function runLoadTest() {
    console.log(`Staged SSR Load Test: https://${CONFIG.BASE_URL}${CONFIG.PATH}`);
    console.log(`Stages: ${CONFIG.STAGES.map(s => s.concurrency).join(' -> ')} concurrent`);
    console.log(`Cooldown between stages: ${CONFIG.COOLDOWN_SECONDS}s`);

    const stageResults = [];

    for (let i = 0; i < CONFIG.STAGES.length; i++) {
        const stats = await runStage(CONFIG.STAGES[i], i + 1, CONFIG.STAGES.length);
        stageResults.push(stats);

        if (i < CONFIG.STAGES.length - 1) {
            console.log(`\n  Cooldown ${CONFIG.COOLDOWN_SECONDS}s...`);
            await sleep(CONFIG.COOLDOWN_SECONDS * 1000);
        }
    }

    // Final summary table
    console.log('\n' + '='.repeat(80));
    console.log('  STAGED LOAD TEST SUMMARY');
    console.log('='.repeat(80));
    console.log(`  Target: https://${CONFIG.BASE_URL}${CONFIG.PATH}`);
    console.log('');
    console.log('  Concurrency | Requests |   RPS  | Avg(ms) | P50(ms) | P95(ms) | P99(ms) | Err%');
    console.log('  ' + '-'.repeat(76));

    for (const s of stageResults) {
        console.log(
            `  ${String(s.concurrency).padStart(11)} |` +
            ` ${String(s.total).padStart(8)} |` +
            ` ${String(s.rps).padStart(6)} |` +
            ` ${String(s.avgTime).padStart(7)} |` +
            ` ${String(s.p50).padStart(7)} |` +
            ` ${String(s.p95).padStart(7)} |` +
            ` ${String(s.p99).padStart(7)} |` +
            ` ${String(s.errorRate).padStart(4)}%`
        );
    }
    console.log('='.repeat(80));

    // Save log
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const logDir = path.join(__dirname, 'logs');
    if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });

    const logFile = path.join(logDir, `ssr-staged-${timestamp}.json`);
    fs.writeFileSync(logFile, JSON.stringify({ config: CONFIG, stageResults }, null, 2));
    console.log(`\nLog saved: ${logFile}`);

    // Recommendation
    console.log('\n  [How to use]');
    console.log('  1. 각 단계 시작 시간에 맞춰 CloudWatch/Prometheus에서 CPU, 메모리 확인');
    console.log('  2. P95 응답시간이 급격히 올라가는 단계 = 서버 한계점');
    console.log('  3. 해당 단계의 서버 CPU/메모리 = K8s resource limit 기준');
    console.log('  4. 정상 운영 단계의 CPU/메모리 = K8s resource request 기준');
}

runLoadTest().catch(console.error);
