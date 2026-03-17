const http = require('https');
const fs = require('fs');
const path = require('path');

/**
 * Time-based Load Testing Script for dev.daeng-map.store
 * Sends concurrent requests for a specified duration.
 */

const CONFIG = {
    BASE_URL: "daeng-map.store",
    //BASE_URL: 'localhost',
    // PORT: 8080,
    ACCESS_TOKEN: '',
    DEV_USER_ID: 3,
    CONCURRENCY: 2000,       // Number of concurrent workers
    DURATION_SECONDS: 60,  // How long to run the test in seconds
};

async function fetchAccessToken() {
    return new Promise((resolve, reject) => {
        const req = http.request({
            hostname: CONFIG.BASE_URL,
            // port: CONFIG.PORT,
            path: `/api/v3/auth/dev/token/${CONFIG.DEV_USER_ID}`,
            method: 'POST',
            headers: {'Content-Type': 'application/json'}
        }, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                const parsed = JSON.parse(body);
                if (parsed.data && parsed.data.accessToken) {
                    resolve(parsed.data.accessToken);
                } else {
                    reject(new Error(`Token fetch failed: ${body}`));
                }
            });
        });
        req.on('error', reject);
        req.end();
    });
}

const APIS = [
    {
        name: 'dev makes user',
        method: 'POST',
        path: '/api/v3/auth/dev/seed',
        body: JSON.stringify({
            "count": 1,
            "prefix": "string"
        })
    },
    // {
    //     name: 'Update Dog Profile',
    //     method: 'PATCH',
    //     path: '/api/v3/users/dogs',
    //     body: JSON.stringify({
    //         "name": "만보",
    //         "breedId": 2,
    //         "birthDate": "2023-12-22",
    //         "isBirthUnknown": true,
    //         "regionId": 23,
    //         "gender": "MALE",
    //         "isNeutered": true,
    //         "weight": 7.5,
    //         "profileImageUrl": "https://cdn.example.com/dogs/choco.png",
    //     })
    // },
    // {
    //     name: 'Get Blocks',
    //     method: 'GET',
    //     path: '/api/v3/blocks?lat=38.0691&lng=127.7745&radius=1000'
    // },
    // {
    //     name: 'Get Regions',
    //     method: 'GET',
    //     path: '/api/v3/regions?regionId=1'
    // }
];

async function sendRequest(api) {
    return new Promise((resolve) => {
        const startTime = Date.now();
        const options = {
            hostname: CONFIG.BASE_URL,
            port: CONFIG.PORT,
            path: api.path,
            method: api.method,
            headers: {
                'Authorization': `Bearer ${CONFIG.ACCESS_TOKEN}`,
                'Content-Type': 'application/json',
                'User-Agent': 'LoadTest-Agent/1.0'
            }
        };

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                resolve({
                    name: api.name,
                    statusCode: res.statusCode,
                    responseTime: Date.now() - startTime
                });
            });
        });

        req.on('error', (err) => {
            resolve({
                name: api.name,
                error: err.message,
                responseTime: Date.now() - startTime
            });
        });

        if (api.body) req.write(api.body);
        req.end();
    });
}

/**
 * Worker function that keeps sending requests until duration is reached
 */
async function worker(workerId, endTime, results) {
    let requestCount = 0;
    while (Date.now() < endTime) {
        const api = APIS[Math.floor(Math.random() * APIS.length)];
        const result = await sendRequest(api);
        result.id = `${workerId}-${++requestCount}`;
        results.push(result);

        const status = result.error ? `ERROR: ${result.error}` : result.statusCode;
        console.log(`[Worker ${workerId}] Request ${requestCount} | ${result.name.padEnd(20)} | Status: ${status} | Time: ${result.responseTime}ms`);
    }
}

async function runLoadTest() {
    console.log('🔑 Fetching access token...');
    // CONFIG.ACCESS_TOKEN = await fetchAccessToken();
    CONFIG.ACCESS_TOKEN = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI3IiwiaWF0IjoxNzcyNjkzODc5LCJleHAiOjE3NzI2OTU2NzksInN0YXR1cyI6IkFDVElWRSJ9.myWyWHDzyDfOUYqIc8IM8EL05V1YEvOVZsRMB1mRZr8";
    console.log('✅ Access token acquired!\n');

    const startTime = Date.now();
    const endTime = startTime + (CONFIG.DURATION_SECONDS * 1000);

    console.log(`🚀 Starting Time-based Load Test on ${CONFIG.BASE_URL}`);
    console.log(`📊 Concurrency: ${CONFIG.CONCURRENCY}, Duration: ${CONFIG.DURATION_SECONDS}s\n`);

    const results = [];
    const workers = [];

    // Launch concurrent workers
    for (let i = 1; i <= CONFIG.CONCURRENCY; i++) {
        workers.push(worker(i, endTime, results));
    }

    await Promise.all(workers);

    const actualDuration = Date.now() - startTime;
    const summary = buildSummary(results, actualDuration);
    printSummary(summary);
    saveLogFile(results, summary);
}

function percentile(sortedArr, p) {
    const idx = Math.ceil((p / 100) * sortedArr.length) - 1;
    return sortedArr[Math.max(0, idx)];
}

function buildSummary(results, durationMs) {
    const total = results.length;
    const success = results.filter(r => r.statusCode >= 200 && r.statusCode < 300).length;
    const rateLimited = results.filter(r => r.statusCode === 429).length;
    const errors = results.filter(r => r.error || (r.statusCode >= 400 && r.statusCode !== 429)).length;
    const rps = (total / (durationMs / 1000)).toFixed(2);

    const times = results.map(r => r.responseTime).sort((a, b) => a - b);
    const avgTime = total > 0 ? Math.round(times.reduce((s, t) => s + t, 0) / total) : 0;
    const minTime = times[0] || 0;
    const maxTime = times[times.length - 1] || 0;
    const p50 = percentile(times, 50);
    const p90 = percentile(times, 90);
    const p95 = percentile(times, 95);
    const p99 = percentile(times, 99);

    // Status code distribution
    const statusCodes = {};
    results.forEach(r => {
        const key = r.error ? 'ERROR' : r.statusCode;
        statusCodes[key] = (statusCodes[key] || 0) + 1;
    });

    // Per-API statistics
    const apiStats = {};
    results.forEach(r => {
        if (!apiStats[r.name]) apiStats[r.name] = {times: [], statuses: {}};
        apiStats[r.name].times.push(r.responseTime);
        const key = r.error ? 'ERROR' : r.statusCode;
        apiStats[r.name].statuses[key] = (apiStats[r.name].statuses[key] || 0) + 1;
    });

    const perApi = {};
    for (const [name, stat] of Object.entries(apiStats)) {
        const sorted = stat.times.sort((a, b) => a - b);
        perApi[name] = {
            count: sorted.length,
            avg: Math.round(sorted.reduce((s, t) => s + t, 0) / sorted.length),
            min: sorted[0],
            max: sorted[sorted.length - 1],
            p50: percentile(sorted, 50),
            p95: percentile(sorted, 95),
            p99: percentile(sorted, 99),
            statuses: stat.statuses,
        };
    }

    return {
        durationMs, total, success, rateLimited, errors, rps,
        avgTime, minTime, maxTime, p50, p90, p95, p99,
        statusCodes, perApi,
    };
}

function printSummary(s) {
    const log = console.log;
    log('\n' + '='.repeat(60));
    log('  LOAD TEST SUMMARY');
    log('='.repeat(60));
    log(`  Total Requests:    ${s.total}`);
    log(`  Total Duration:    ${(s.durationMs / 1000).toFixed(2)}s`);
    log(`  Requests/Sec:      ${s.rps}`);
    log(`  Successful:        ${s.success}`);
    log(`  Rate Limited(429): ${s.rateLimited}`);
    log(`  Failed/Errors:     ${s.errors}`);
    log('');
    log('  Response Time (ms)');
    log(`    Avg: ${s.avgTime}  Min: ${s.minTime}  Max: ${s.maxTime}`);
    log(`    P50: ${s.p50}  P90: ${s.p90}  P95: ${s.p95}  P99: ${s.p99}`);
    log('');
    log('  Status Code Distribution');
    for (const [code, count] of Object.entries(s.statusCodes)) {
        log(`    ${code}: ${count} (${((count / s.total) * 100).toFixed(1)}%)`);
    }
    log('');
    log('  Per-API Statistics');
    log('-'.repeat(60));
    for (const [name, stat] of Object.entries(s.perApi)) {
        log(`  [${name}]`);
        log(`    Count: ${stat.count}  Avg: ${stat.avg}ms  Min: ${stat.min}ms  Max: ${stat.max}ms`);
        log(`    P50: ${stat.p50}ms  P95: ${stat.p95}ms  P99: ${stat.p99}ms`);
        const statusStr = Object.entries(stat.statuses).map(([k, v]) => `${k}=${v}`).join(', ');
        log(`    Statuses: ${statusStr}`);
    }
    log('='.repeat(60));
}

function saveLogFile(results, summary) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const logDir = path.join(__dirname, 'logs');
    if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, {recursive: true});

    // Save raw results as JSON
    const rawFile = path.join(logDir, `loadtest-${timestamp}.json`);
    fs.writeFileSync(rawFile, JSON.stringify({config: CONFIG, summary, results}, null, 2));

    // Save human-readable summary
    const txtFile = path.join(logDir, `loadtest-${timestamp}.txt`);
    const lines = [];
    lines.push(`Load Test Report - ${new Date().toISOString()}`);
    lines.push(`Target: ${CONFIG.BASE_URL}`);
    lines.push(`Concurrency: ${CONFIG.CONCURRENCY}, Duration: ${CONFIG.DURATION_SECONDS}s`);
    lines.push('');
    lines.push(`Total Requests:    ${summary.total}`);
    lines.push(`Total Duration:    ${(summary.durationMs / 1000).toFixed(2)}s`);
    lines.push(`Requests/Sec:      ${summary.rps}`);
    lines.push(`Successful:        ${summary.success}`);
    lines.push(`Rate Limited(429): ${summary.rateLimited}`);
    lines.push(`Failed/Errors:     ${summary.errors}`);
    lines.push('');
    lines.push('Response Time (ms)');
    lines.push(`  Avg: ${summary.avgTime}  Min: ${summary.minTime}  Max: ${summary.maxTime}`);
    lines.push(`  P50: ${summary.p50}  P90: ${summary.p90}  P95: ${summary.p95}  P99: ${summary.p99}`);
    lines.push('');
    lines.push('Status Code Distribution');
    for (const [code, count] of Object.entries(summary.statusCodes)) {
        lines.push(`  ${code}: ${count} (${((count / summary.total) * 100).toFixed(1)}%)`);
    }
    lines.push('');
    lines.push('Per-API Statistics');
    for (const [name, stat] of Object.entries(summary.perApi)) {
        lines.push(`  [${name}]`);
        lines.push(`    Count: ${stat.count}  Avg: ${stat.avg}ms  Min: ${stat.min}ms  Max: ${stat.max}ms`);
        lines.push(`    P50: ${stat.p50}ms  P95: ${stat.p95}ms  P99: ${stat.p99}ms`);
        const statusStr = Object.entries(stat.statuses).map(([k, v]) => `${k}=${v}`).join(', ');
        lines.push(`    Statuses: ${statusStr}`);
    }
    fs.writeFileSync(txtFile, lines.join('\n'));

    console.log(`\nLog files saved:`);
    console.log(`  JSON: ${rawFile}`);
    console.log(`  TXT:  ${txtFile}`);
}

runLoadTest().catch(console.error);
