/**
 * Chaos Experiment #3 : Latency Injection
 *
 * Objectif : Simuler une dégradation de la dépendance externe (dummyjson.com)
 * pour vérifier que :
 *   1. L'alerte SLO Latence se déclenche (Phase 4 — p99 > 800ms)
 *   2. Les traces OTel capturent la latence élevée sur GET /
 *   3. La page d'accueil se dégrade gracefully (fallback quote)
 *
 * Mécanisme : proxy local HTTP interceptant les appels à dummyjson.com et
 * injectant un délai artificiel avant de transférer la requête.
 *
 * Usage :
 *   node chaos-latency-inject.js --delay 2000 --port 8888
 *   # Puis configurer l'app pour pointer vers ce proxy
 *
 * Note : En lab Azure, on peut aussi utiliser Azure Chaos Studio
 * (experiment type: network-latency) sans modifier le code.
 */

const http = require('http');
const https = require('https');
const { URL } = require('url');

const INJECTED_DELAY_MS = parseInt(process.argv[2]) || 2000; // Délai injecté (ms)
const PROXY_PORT = parseInt(process.argv[3]) || 8888;
const TARGET_HOST = 'dummyjson.com';

console.log('===========================================');
console.log('CHAOS EXPERIMENT #3 : Latency Injection');
console.log('===========================================');
console.log(`Proxy port    : ${PROXY_PORT}`);
console.log(`Target host   : ${TARGET_HOST}`);
console.log(`Injected delay: ${INJECTED_DELAY_MS}ms`);
console.log(`Start         : ${new Date().toISOString()}`);
console.log('===========================================\n');

let requestCount = 0;
let totalInjectedMs = 0;

const server = http.createServer((clientReq, clientRes) => {
    requestCount++;
    const reqId = requestCount;
    const startTime = Date.now();

    console.log(`[${new Date().toISOString()}] #${reqId} Intercepted: ${clientReq.method} ${clientReq.url}`);

    // Injecter le délai artificiel
    setTimeout(() => {
        const targetUrl = new URL(`https://${TARGET_HOST}${clientReq.url}`);

        const options = {
            hostname: targetUrl.hostname,
            port: 443,
            path: targetUrl.pathname + targetUrl.search,
            method: clientReq.method,
            headers: {
                ...clientReq.headers,
                host: TARGET_HOST,
            },
        };

        const proxyReq = https.request(options, (proxyRes) => {
            clientRes.writeHead(proxyRes.statusCode, proxyRes.headers);
            proxyRes.pipe(clientRes);

            const totalTime = Date.now() - startTime;
            totalInjectedMs += INJECTED_DELAY_MS;

            console.log(
                `[${new Date().toISOString()}] #${reqId} Forwarded → HTTP ${proxyRes.statusCode} ` +
                `(delay: ${INJECTED_DELAY_MS}ms + real: ${totalTime - INJECTED_DELAY_MS}ms = ${totalTime}ms total)`
            );
        });

        proxyReq.on('error', (err) => {
            console.error(`[${new Date().toISOString()}] #${reqId} Proxy error: ${err.message}`);
            clientRes.writeHead(502);
            clientRes.end(`Proxy error: ${err.message}`);
        });

        clientReq.pipe(proxyReq);
    }, INJECTED_DELAY_MS);
});

server.listen(PROXY_PORT, () => {
    console.log(`Chaos proxy listening on http://localhost:${PROXY_PORT}`);
    console.log(`All requests to ${TARGET_HOST} will be delayed by ${INJECTED_DELAY_MS}ms\n`);
    console.log('Press Ctrl+C to stop the chaos and restore normal latency.\n');
});

// Résumé à l'arrêt
process.on('SIGINT', () => {
    console.log('\n===========================================');
    console.log('FIN DU CHAOS LATENCY INJECTION');
    console.log('===========================================');
    console.log(`Requêtes interceptées : ${requestCount}`);
    console.log(`Délai total injecté   : ${totalInjectedMs}ms`);
    console.log(`Fin                   : ${new Date().toISOString()}`);
    console.log('===========================================');
    console.log('\nVérifier dans Azure :');
    console.log('  - Application Insights → Performance → GET /');
    console.log('  - Log Analytics → AppServiceHTTPLogs | where TimeTaken > 2000');
    console.log('  - Azure Monitor → Alertes → slo-latency-breach');
    process.exit(0);
});
