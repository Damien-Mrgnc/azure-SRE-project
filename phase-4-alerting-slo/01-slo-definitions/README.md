# Step 1: SLI / SLO / Error Budget Definitions

*Lire la [Version Française](README_FR.md) ici.*

## Objective

Formalize the service's **reliability commitments** as SLIs, SLOs, and Error Budgets. These definitions are the SRE team's compass: they dictate when to act, when to deploy, and when to freeze changes.

## The 4 Defined SLOs

### SLO 1 — Availability ≥ 99.9%
- **SLI**: `(non-5xx requests / total requests) × 100`
- **Error Budget**: 43 minutes of downtime per month
- **Source**: Azure Monitor (`Http5xx` / `Requests`)

### SLO 2 — p95 Latency < 500ms
- **SLI**: 95th percentile of HTTP response time
- **Error Budget**: 5% of requests may exceed 500ms
- **Source**: Prometheus `http_request_duration_ms`

### SLO 3 — Error Rate < 1%
- **SLI**: `(4xx + 5xx requests) / total × 100`
- **Error Budget**: 1% of requests allowed to be errors
- **Source**: Prometheus `http_requests_total{code=~"4..|5.."}`

### SLO 4 — CPU < 80% (Saturation)
- **SLI**: Average CPU% over 5-min window
- **Action**: Autoscaling at 75% (Phase 3) acts before this threshold
- **Source**: Azure Monitor `CpuPercentage`

## Error Budget Policy

| Budget Remaining | Policy |
|---|---|
| > 50% | Normal deployments allowed |
| 10 – 50% | Feature-flagged deployments only |
| < 10% | **Deployment freeze** — reliability focus |

## Files in This Step

| File | Description |
|---|---|
| [`slo-definitions.md`](./slo-definitions.md) | Full SLI/SLO/Error Budget document with KQL queries |
