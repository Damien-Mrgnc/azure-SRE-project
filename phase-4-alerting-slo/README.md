# Phase 4: SLO, SLI, and Alerting

*Lire la [Version Française](README_FR.md) ici.*

## Objective

Formalize reliability commitments (SLO/SLI/Error Budget) and configure corresponding alerts in Azure Monitor. This phase turns the observability from previous phases into **concrete operational decisions**.

## Structural Overview

1. [**Step 1: SLI/SLO/Error Budget Definitions**](./01-slo-definitions/README.md)
2. [**Step 2: Azure Monitor Alerting**](./02-alerting/README.md)

---

## Connection to Other Phases

| Phase | Contribution to Phase 4 |
|---|---|
| Phase 1 | Prometheus + Azure Monitor metrics → SLI sources |
| Phase 2 | Log Analytics logs → KQL queries for SLO alerts |
| Phase 3 | Autoscaling at 75% → acts **before** the 80% CPU SLO alert |
| Phase 4 | **SLOs defined + alerts configured** |
| Phase 5 | Chaos Engineering validates that alerts fire correctly |

## Snapshot Contents

| Path | Description |
|---|---|
| `01-slo-definitions/slo-definitions.md` | 4 SLOs: availability (99.9%), p95 latency (< 500ms), errors (< 1%), CPU (< 80%) |
| `02-alerting/alerts.tf` | Infrastructure alerts (Phase 1) + KQL SLO alerts (Phase 4) |
| `02-alerting/alert-notification-example.json` | 4 example received payloads (Common Alert Schema) |

---

## Tech Stack

- **`azurerm_monitor_scheduled_query_rules_alert_v2`**: KQL-based alerts (error rate %, p99 latency)
- **`azurerm_monitor_metric_alert`**: Direct metric alerts (CPU, Http5xx count)
- **`azurerm_monitor_action_group`**: Notification routing to email
- **KQL**: Query language for Log Analytics-based alerts
- **Common Alert Schema**: Unified Azure notification payload format

## Status: Complete ✅
