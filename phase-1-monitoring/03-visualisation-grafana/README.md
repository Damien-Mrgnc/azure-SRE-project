# Step 3: Visualization Side — Grafana as Code

## Concept
Having metrics and a monitoring stack is not enough: you need **actionable dashboards** to turn raw data into operational decisions. The "Grafana as Code" approach ensures dashboards are versioned, reproducible, and deployed idempotently through CI/CD.

## Implementation Details
A JSON dashboard is stored in the repository and automatically deployed to Azure Managed Grafana via a Terraform `null_resource` using Azure CLI.

### "Application Health (SRE)" Dashboard — 4 Golden Signals
The dashboard follows Google SRE's **4 Golden Signals** methodology:

1. **Traffic**: Total HTTP requests over time (Time Series panel) — detects load spikes and dips.
2. **Errors**:
   - HTTP 4xx errors (Stat panel) — client errors.
   - HTTP 5xx errors (Time Series panel) — critical server errors.
3. **Latency**: Average response time over time (Time Series panel, unit: seconds) — detects performance degradation.
4. **Saturation**:
   - CPU Time (Gauge panel) — App Service processor load.
   - Memory Working Set (Gauge panel, unit: bytes) — memory consumption.

### Idempotent Deployment
- **Mechanism**: `null_resource` with `local-exec` provisioner running `az grafana dashboard create --overwrite true`.
- **Trigger**: Based on the JSON file's MD5 hash (`filemd5()`). The dashboard is only redeployed when its definition changes.
- **Dependency**: Deployment waits for the `Grafana Admin` role to be assigned (`depends_on`).

### Azure CLI Command
```bash
az extension add -n amg --upgrade && \
az grafana dashboard create \
  --name <grafana-instance> \
  --resource-group <rg> \
  --definition @terraform/dashboards/webapp-health.json \
  --overwrite true
```

## Key Files (Phase 1 Snapshot)

| File | Description |
|---|---|
| [`dashboards/webapp-health.json`](./dashboards/webapp-health.json) | Snapshot — Full JSON dashboard definition (4 Golden Signals) |

> Live source file is at [`terraform/dashboards/webapp-health.json`](../../../terraform/dashboards/webapp-health.json).
> Terraform provisioning is in [`02-infra-monitoring/monitoring.tf`](../02-infra-monitoring/monitoring.tf) (`null_resource.grafana_dashboard_webapp`).

### Dashboard Panels

| Panel | Type | Signal | Azure Monitor Metric |
|---|---|---|---|
| Total Traffic (Requests) | Time Series | Traffic | `Requests` |
| Client Errors (400) | Stat | Errors | `Http4xx` |
| Server Errors (500) | Time Series | Errors | `Http 5xx` |
| Average Response Time | Time Series | Latency | `Average Response Time` |
| CPU Saturation | Gauge | Saturation | `CpuTime` |
| Memory Usage | Gauge | Saturation | `MemoryWorkingSet` |

### Deployment via Grafana REST API

The dashboard is pushed automatically via Grafana's REST API after Terraform starts the container:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -u "admin:<password>" \
  -d '{"dashboard": <json>, "overwrite": true, "folderId": 0}' \
  https://<grafana-host>/api/dashboards/db
```

## Result
The dashboard is versioned with the code and deployed automatically. The SRE team has a unified view of all 4 Golden Signals from the very first deployment.
