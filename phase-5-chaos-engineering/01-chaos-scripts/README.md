# 01 — Chaos Engineering Scripts

This folder contains the scripts used for the Phase 5 Chaos Engineering experiments.

## Files

| File | Type | Description |
|---|---|---|
| `chaos-cpu-stress.sh` | Bash | Injects CPU load via concurrent requests to `/api/admin/stress` |
| `chaos-kill-instance.sh` | Bash | Simulates instance death via `az webapp restart` with availability probe |
| `chaos-latency-inject.js` | Node.js | HTTP proxy injecting artificial delay before forwarding requests |
| `azure-chaos-experiment.json` | JSON | Azure Chaos Studio experiment definition (CPU Pressure + Stop) |

---

## Experiment #1 — CPU Stress

**Script:** `chaos-cpu-stress.sh`

**Hypothesis:** Autoscaling (Phase 3) absorbs CPU load before the availability SLO is breached.

**Mechanism:**
```bash
# Launch N concurrent workers to /api/admin/stress
# Each request simulates 2000ms of CPU-intensive processing
CONCURRENCY=20
STRESS_DURATION=600  # 10 minutes
```

**Usage:**
```bash
chmod +x chaos-cpu-stress.sh
./chaos-cpu-stress.sh \
  --url https://app-projet3-sre.azurewebsites.net \
  --concurrency 20 \
  --duration 600
```

**Environment variables:**
```bash
APP_URL=https://app-projet3-sre.azurewebsites.net
CONCURRENCY=20
DURATION=600
STRESS_MS=2000
```

**What to observe:**
- CPU% in Azure Monitor (App Service Plan)
- Autoscaling trigger (Scale-out 1→2→3 instances)
- `alert-asp-cpu-high` alert (Sev2)
- `slo-latency-breach` alert (Sev2, p99 > 800ms)
- Results in `../02-chaos-results/chaos-run-report.json`

---

## Experiment #2 — Kill Instance

**Script:** `chaos-kill-instance.sh`

**Hypothesis:** After a forced restart, the Azure health check restores service in < 2 minutes.

**Mechanism:**
```bash
# az webapp restart → temporary unavailability
# HTTP probe every 5s to measure downtime duration
az webapp restart --resource-group $RESOURCE_GROUP --name $APP_NAME
```

**Usage:**
```bash
chmod +x chaos-kill-instance.sh
APP_NAME=app-projet3-sre-abc123 \
RESOURCE_GROUP=rg-projet3-sre \
./chaos-kill-instance.sh
```

**What to observe:**
- First 503/502 errors after restart
- `alert-webapp-5xx` alert (Sev2, > 5 5xx errors)
- `slo-availability-breach` alert (Sev1, error rate > 1%)
- Downtime duration measured by probe (SLO: < 120s)

---

## Experiment #3 — Latency Injection

**Script:** `chaos-latency-inject.js`

**Hypothesis:** The `slo-latency-breach` alert fires when external dependencies are slow.

**Mechanism:**
```
Client → Local proxy (port 8888) → [INJECTED_DELAY_MS delay] → dummyjson.com
```

**Usage:**
```bash
# Start proxy with 2000ms delay
node chaos-latency-inject.js 2000 8888

# Configure app to route through proxy
APP_EXTERNAL_API_URL=http://localhost:8888 node server.js
```

**What to observe:**
- Application Insights → Performance → GET / (high latency)
- Log Analytics → `AppServiceHTTPLogs | where TimeTaken > 2000`
- `slo-latency-breach` alert

---

## Azure Chaos Studio

**File:** `azure-chaos-experiment.json`

Azure Chaos Studio experiment definition with 5 steps:

| Step | Action | Duration |
|---|---|---|
| 1 — Baseline | Wait (measure baseline) | 2 min |
| 2 — CPU Pressure | `cpuPressure/1.0` at 80% | 5 min |
| 3 — Recovery Check | Wait and observe recovery | 5 min |
| 4 — Stop & Restart | `stop/1.0` (stop App Service) | Discrete |
| 5 — Auto-recovery | Wait for auto-restart observation | 3 min |

**Deployment:**
```bash
az rest --method PUT \
  --url '/subscriptions/{subscriptionId}/resourceGroups/rg-projet3-sre/providers/Microsoft.Chaos/experiments/chaos-exp-sre-full' \
  --body @azure-chaos-experiment.json \
  --api-version 2023-11-01
```

**Prerequisites:**
```bash
# Grant Chaos Studio permissions on the target resource
az role assignment create \
  --role "Website Contributor" \
  --assignee-object-id <chaos-experiment-principal-id> \
  --scope /subscriptions/{sub}/resourceGroups/rg-projet3-sre/providers/Microsoft.Web/sites/app-projet3-sre-abc123
```

---

## Results

Detailed experiment results are in:
- [`../02-chaos-results/chaos-run-report.json`](../02-chaos-results/chaos-run-report.json) — full report
- [`../02-chaos-results/metrics-during-chaos.json`](../02-chaos-results/metrics-during-chaos.json) — minute-by-minute metrics

Post-mortem:
- [`../03-postmortem/postmortem-incident-001.md`](../03-postmortem/postmortem-incident-001.md)
