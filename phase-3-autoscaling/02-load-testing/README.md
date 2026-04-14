# Step 2: Load Testing (k6)

*Lire la [Version Française](README_FR.md) ici.*

## Objective

Validate autoscaling behavior under real load using **k6**, a modern load testing tool. The test simulates a progressive ramp-up to 150 virtual users to trigger the scale-out rules defined in Step 1.

## Tool: k6

k6 is an open-source load testing tool written in Go, with scenarios defined in JavaScript. It generates precise metrics (latencies, error rates) and allows defining **SLOs as test failure thresholds**.

**Installation:**
```bash
# Windows
winget install k6

# Linux/Ubuntu
sudo apt install k6

# macOS
brew install k6
```

## Test Scenario

The test runs 6 stages over 20 minutes:

| Stage | Duration | VUs | Goal |
|---|---|---|---|
| Warm-up | 2 min | 0 → 10 | Verify baseline health |
| Ramp | 3 min | 10 → 50 | Normal load |
| Peak | 5 min | 50 → 150 | **Trigger scale-out** |
| Sustained | 5 min | 150 | Observe multi-instance stability |
| Ramp-down | 3 min | 150 → 20 | **Trigger scale-in** |
| End | 2 min | 20 → 0 | Return to idle |

## Request Mix

| Endpoint | % of traffic | Reason |
|---|---|---|
| `GET /api/config` | 70% | Light load, represents real traffic |
| `GET /` | 20% | SSR + external API call, moderate load |
| `POST /api/admin/stress` | 10% | **Intentional CPU burn** — triggers scale-out |

The `/api/admin/stress` route (added in Phase 1 for Chaos Engineering) intentionally blocks the CPU for 2 seconds, simulating intensive processing.

## SLO Thresholds

The test **automatically fails** if these thresholds are exceeded:

```javascript
thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'], // Latency
    error_rate: ['rate<0.01'],                        // Errors < 1%
}
```

## Running the Test

```bash
# Basic run
k6 run load-test.js

# With custom target URL
k6 run --env BASE_URL=https://app-projet3-sre.azurewebsites.net load-test.js

# With InfluxDB output (for real-time Grafana dashboard)
k6 run --out influxdb=http://localhost:8086/k6 load-test.js
```

## Results (Simulated)

See [`load-test-report.json`](./load-test-report.json) for the full report. Key highlights:

| Metric | Result | SLO | Verdict |
|---|---|---|---|
| p95 Latency | 312 ms | < 500 ms | ✅ PASS |
| p99 Latency | 748 ms | < 1000 ms | ✅ PASS |
| Error rate | 0.18% | < 1% | ✅ PASS |
| Availability | 99.82% | > 99.9% | ⚠️ BORDERLINE |

### Autoscaling Timeline

```
T+07m12s: SCALE-OUT → 2 instances  (CPU 78% > 75%)
T+12m45s: SCALE-OUT → 3 instances  (CPU 82% > 75%)
T+26m30s: SCALE-IN  → 2 instances  (CPU 18% < 25%)
T+36m31s: SCALE-IN  → 1 instance   (CPU 13% < 25%)
```

Autoscaling absorbed the traffic peak without breaching latency SLOs. The 99.82% availability (slightly below the 99.9% target) is due to a few requests dropped during the initial scale-out — a pre-warming strategy could improve this.

## Files in This Step

| File | Description |
|---|---|
| [`load-test.js`](./load-test.js) | k6 script — 6-stage scenario, 3 endpoints, SLO thresholds |
| [`load-test-report.json`](./load-test-report.json) | Full simulated report — metrics, autoscaling events, CPU timeline |
