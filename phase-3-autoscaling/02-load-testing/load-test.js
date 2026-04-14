/**
 * Load Test Script — k6
 * Phase 3 : Autoscaling
 *
 * Objectif : Simuler une montée en charge progressive pour déclencher
 * l'autoscaling Azure App Service (CPU > 75% → scale-out).
 *
 * Usage :
 *   k6 run load-test.js
 *   k6 run --env BASE_URL=https://app-projet3-sre.azurewebsites.net load-test.js
 *
 * Installation k6 : https://k6.io/docs/getting-started/installation/
 *   Windows : winget install k6
 *   Linux   : sudo apt install k6
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// --- Métriques custom k6 ---
const errorRate = new Rate('error_rate');
const requestDuration = new Trend('request_duration', true);

// --- Configuration du test ---
export const options = {
    // Scénario en 4 étapes : montée, pic, maintien, descente
    stages: [
        { duration: '2m', target: 10 },   // Rampe douce : 0 → 10 VUs en 2 min
        { duration: '3m', target: 50 },   // Montée : 10 → 50 VUs en 3 min (charge normale)
        { duration: '5m', target: 150 },  // Pic : 50 → 150 VUs en 5 min (trigger scale-out)
        { duration: '5m', target: 150 },  // Maintien à 150 VUs pendant 5 min
        { duration: '3m', target: 20 },   // Descente : 150 → 20 VUs (trigger scale-in progressif)
        { duration: '2m', target: 0 },    // Fin : retour à 0
    ],

    // Seuils SLO — le test échoue si ces seuils sont dépassés
    thresholds: {
        http_req_duration: ['p(95)<500', 'p(99)<1000'], // 95% < 500ms, 99% < 1s
        error_rate: ['rate<0.01'],                       // Moins de 1% d'erreurs
        http_req_failed: ['rate<0.01'],
    },
};

const BASE_URL = __ENV.BASE_URL || 'https://app-projet3-sre.azurewebsites.net';

// Données de test pour les requêtes POST
const ADMIN_HEADERS = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer test-token',
    'x-correlation-id': `k6-load-test-${Date.now()}`,
};

// --- Scénario principal (exécuté par chaque VU) ---
export default function () {
    // 70% : lecture publique (GET /api/config) — charge légère
    if (Math.random() < 0.7) {
        const res = http.get(`${BASE_URL}/api/config`, {
            tags: { name: 'GET /api/config' },
        });

        const success = check(res, {
            'status is 200': (r) => r.status === 200,
            'response time < 500ms': (r) => r.timings.duration < 500,
            'body contains siteTitle': (r) => r.body.includes('siteTitle'),
        });

        errorRate.add(!success);
        requestDuration.add(res.timings.duration);

    // 20% : page d'accueil (GET /) — charge modérée (SSR + appel API externe)
    } else if (Math.random() < 0.9) {
        const res = http.get(`${BASE_URL}/`, {
            tags: { name: 'GET /' },
        });

        const success = check(res, {
            'status is 200': (r) => r.status === 200,
            'response time < 1000ms': (r) => r.timings.duration < 1000,
        });

        errorRate.add(!success);
        requestDuration.add(res.timings.duration);

    // 10% : endpoint de stress CPU (POST /api/admin/stress) — charge CPU intentionnelle
    } else {
        const res = http.post(
            `${BASE_URL}/api/admin/stress`,
            JSON.stringify({ duration: 2000 }), // Bloquer le CPU 2 secondes
            { headers: ADMIN_HEADERS, tags: { name: 'POST /api/admin/stress' } }
        );

        const success = check(res, {
            'stress status is 200 or 401': (r) => r.status === 200 || r.status === 401,
        });

        errorRate.add(!success);
        requestDuration.add(res.timings.duration);
    }

    // Pause réaliste entre requêtes (simule un utilisateur humain)
    sleep(Math.random() * 2 + 0.5); // entre 0.5s et 2.5s
}

// --- Hook de fin de test ---
export function handleSummary(data) {
    return {
        'load-test-summary.json': JSON.stringify(data, null, 2),
        stdout: textSummary(data, { indent: ' ', enableColors: true }),
    };
}

function textSummary(data) {
    const metrics = data.metrics;
    const duration = metrics['http_req_duration'];
    const errors = metrics['http_req_failed'];
    const reqs = metrics['http_reqs'];

    return `
=== RÉSUMÉ DU TEST DE CHARGE ===
Durée totale      : ${Math.round(data.state.testRunDurationMs / 1000)}s
Requêtes totales  : ${reqs ? reqs.values.count : 'N/A'}
Requêtes/sec (avg): ${reqs ? reqs.values.rate.toFixed(2) : 'N/A'} req/s
Latence p50       : ${duration ? duration.values['p(50)'].toFixed(2) : 'N/A'} ms
Latence p95       : ${duration ? duration.values['p(95)'].toFixed(2) : 'N/A'} ms
Latence p99       : ${duration ? duration.values['p(99)'].toFixed(2) : 'N/A'} ms
Taux d'erreurs    : ${errors ? (errors.values.rate * 100).toFixed(2) : 'N/A'}%
================================
`;
}
