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

## Key Files
- `terraform/dashboards/webapp-health.json` — Full JSON dashboard definition (4 Golden Signals).
- `terraform/monitoring.tf` — `null_resource` for idempotent dashboard deployment.

## Result
The dashboard is versioned with the code, automatically deployed on each `terraform apply`, and takes no action if the JSON file hasn't changed. The SRE team gets a unified view of all 4 Golden Signals from the very first deployment.
