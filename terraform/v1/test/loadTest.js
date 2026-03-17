const https = require('https');

/**
 * Time-based Load Testing Script for dev.daeng-map.store
 * Sends concurrent requests for a specified duration.
 */

const CONFIG = {
    BASE_URL: 'dev.daeng-map.store',
    ACCESS_TOKEN: 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiaWF0IjoxNzcwODUzODk2LCJleHAiOjE3NzEwMzM4OTYsInN0YXR1cyI6IkFDVElWRSJ9.HVIENukyprt4dy9mrU6x7ErySxP6zWBf6YNxDXX5uJ8',
    CONCURRENCY: 1000,       // Number of concurrent workers
    DURATION_SECONDS: 300,  // How long to run the test in seconds
};

const APIS = [
    {
        name: 'Get Blocks',
        method: 'GET',
        path: '/api/v3/blocks?lat=38.0691&lng=127.7745&radius=1000'
    },
    {
        name: 'Get Regions',
        method: 'GET',
        path: '/api/v3/regions?regionId=23'
    },
    {
        name: 'Update Dog Profile',
        method: 'PATCH',
        path: '/api/v3/users/dogs',
        body: JSON.stringify({
            "name": "만보",
            "breedId": 2,
            "birthDate": "2023-12-22",
            "isBirthUnknown": true,
            "regionId": 23,
            "gender": "MALE",
            "isNeutered": true,
            "weight": 7.5,
            "profileImageUrl": "https://cdn.example.com/dogs/choco.png",
        })
    }
];

async function sendRequest(api) {
    return new Promise((resolve) => {
        const startTime = Date.now();
        const options = {
            hostname: CONFIG.BASE_URL,
            path: api.path,
            method: api.method,
            headers: {
                'Authorization': `Bearer ${CONFIG.ACCESS_TOKEN}`,
                'Content-Type': 'application/json',
                'User-Agent': 'LoadTest-Agent/1.0'
            }
        };

        const req = https.request(options, (res) => {
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
    printSummary(results, actualDuration);
}

function printSummary(results, durationMs) {
    const success = results.filter(r => r.statusCode >= 200 && r.statusCode < 300).length;
    const rateLimited = results.filter(r => r.statusCode === 429).length;
    const errors = results.filter(r => r.error || (r.statusCode >= 400 && r.statusCode !== 429)).length;
    const avgTime = results.length > 0
        ? Math.round(results.reduce((sum, r) => sum + r.responseTime, 0) / results.length)
        : 0;
    const rps = (results.length / (durationMs / 1000)).toFixed(2);

    console.log('\n' + '='.repeat(50));
    console.log('📈 LOAD TEST SUMMARY (TIME-BASED)');
    console.log('='.repeat(50));
    console.log(`Total Requests:    ${results.length}`);
    console.log(`Total Duration:    ${(durationMs / 1000).toFixed(2)}s`);
    console.log(`Requests/Sec:      ${rps}`);
    console.log(`Successful:        ${success}`);
    console.log(`Rate Limited:      ${rateLimited}`);
    console.log(`Failed/Errors:     ${errors}`);
    console.log(`Avg Response Time: ${avgTime}ms`);
    console.log('='.repeat(50));
}

runLoadTest().catch(console.error);
