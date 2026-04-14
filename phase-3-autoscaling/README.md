# Phase 3: Reliability & Autoscaling

*Lire la [Version Française](README_FR.md) ici.*

## Objective

Configure **horizontal autoscaling** for the App Service Plan and validate its behavior under real load using a k6 test. Autoscaling is linked to the CPU metrics collected in Phase 1, completing a full feedback loop: Observability → Action.

## Structural Overview

1. [**Step 1: Autoscaling Rules (Terraform)**](./01-autoscaling-rules/README.md)
2. [**Step 2: Load Testing (k6)**](./02-load-testing/README.md)

---

## The Full SRE Loop

```
Phase 1: CPU metrics exposed (Prometheus + Azure Monitor)
       ↓
Phase 3: Autoscaling triggered by CPU > 75%
       ↓
Phase 4: Alerts if CPU > 80% (SLO breach)
       ↓
Phase 5: Chaos Engineering — validate everything holds under failure
```

## Snapshot Contents

| Path | Description |
|---|---|
| `01-autoscaling-rules/autoscaling.tf` | Terraform rules: scale-out (+1 instance if CPU > 75% / 5min), scale-in (-1 if CPU < 25% / 10min) |
| `02-load-testing/load-test.js` | k6 script — 20 min, 150 VUs max, 3 endpoints, SLO thresholds |
| `02-load-testing/load-test-report.json` | Simulated report: 2 scale-outs, 2 scale-ins, all SLOs met |

---

## Tech Stack

- **`azurerm_monitor_autoscale_setting`**: Terraform resource for App Service Plan autoscaling
- **`CpuPercentage`**: Azure Monitor metric driving the scaling rules
- **k6**: Load testing tool (JS scenarios, Prometheus metrics, SLO thresholds)
- **`/api/admin/stress`**: Chaos route built into the app to simulate CPU load

## Key Results

| Metric | Result | SLO |
|---|---|---|
| p95 Latency at 150 VUs | **312 ms** | < 500 ms ✅ |
| Error rate | **0.18%** | < 1% ✅ |
| Scale-out triggered | **T+7min12s** | CPU 78% > 75% |
| Max instances reached | **3 instances** | max = 3 |

## Status: Complete ✅
