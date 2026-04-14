# Step 2: Alerting (Azure Monitor + SLO Alerts)

*Lire la [Version Française](README_FR.md) ici.*

## Objective

Configure alerts directly tied to the SLOs defined in Step 1, complementing the existing infrastructure alerts (Phase 1). Alerts must distinguish **warnings** (early degradation) from **critical incidents** (SLO breach).

## Alerting Architecture

```
Azure Monitor Metrics / Log Analytics
         ↓
azurerm_monitor_metric_alert          → Metric alerts (CPU, 5xx count)
azurerm_monitor_scheduled_query_rules → KQL alerts (error rate %, p99 latency)
         ↓
azurerm_monitor_action_group          → Email (var.alert_email)
```

## Configured Alerts

### SLO Alerts (Phase 4 — New)

| Alert | Type | Condition | Severity |
|---|---|---|---|
| `slo-availability-breach` | Log (KQL) | 5xx rate > 1% over 5 min | Sev1 (Error) |
| `slo-latency-breach` | Log (KQL) | p99 latency > 800ms over 10 min | Sev2 (Warning) |

### Infrastructure Alerts (Phase 1 — Existing)

| Alert | Type | Condition | Severity |
|---|---|---|---|
| `alert-asp-cpu-high` | Metric | CPU > 80% (avg 5 min) | Sev2 |
| `alert-webapp-5xx` | Metric | Http5xx > 5 (total 5 min) | Sev2 |
| `alert-sql-storage-low` | Metric | SQL storage > 90% | Sev2 |

### Phase 1 vs Phase 4 Difference

- **Phase 1**: Alert on **absolute count** (`Http5xx > 5`) — fires even under low traffic
- **Phase 4**: Alert on **relative rate** (`errors / total > 1%`) — correctly reflects SLO semantics

## Sample Notification

See [`alert-notification-example.json`](./alert-notification-example.json) for 4 complete scenarios:
1. Availability SLO breached (Sev1) — 5xx rate > 1%
2. Latency SLO warning (Sev2) — p99 > 800ms
3. CPU infrastructure alert (Sev2) — CPU 82.4%
4. Auto-resolution — alert closed after metric returns below threshold

## Files in This Step

| File | Description |
|---|---|
| [`alerts.tf`](./alerts.tf) | Snapshot — Phase 1 infra alerts + Phase 4 SLO alerts |
| [`alert-notification-example.json`](./alert-notification-example.json) | Example received payloads (Common Alert Schema) |

> Live source: [`terraform/alerts.tf`](../../../terraform/alerts.tf)
