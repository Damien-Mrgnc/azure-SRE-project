# Step 2: Infra Side — Monitoring Stack Deployment

## Concept
Application instrumentation is useless without infrastructure capable of **collecting, storing, and exposing** the data. This step deploys the entire Azure observability stack via Terraform: Log Analytics, Application Insights, Azure Monitor Workspace, and Managed Grafana, along with the required RBAC roles.

## Implementation Details
All monitoring resources are defined in `terraform/monitoring.tf` and deployed automatically through CI/CD.

### Deployed Resources
1. **Azure Log Analytics Workspace**: Centralized log storage with 30-day retention (SKU `PerGB2018`).
2. **Azure Application Insights**: APM connected to Log Analytics for application performance tracking (type `web`).
3. **Azure Monitor Workspace**: Workspace for native Prometheus metrics, integrating directly with Managed Grafana.
4. **Azure Managed Grafana (v11, Standard SKU)**:
   - `SystemAssigned` Managed Identity for secure data access.
   - Native integration with Azure Monitor Workspace.
   - API key support enabled (`api_key_enabled = true`) for future automation.

### RBAC Configuration
1. **`Monitoring Reader`**: Assigned to Grafana's Managed Identity on the Resource Group → allows reading Azure Monitor metrics and logs.
2. **`Grafana Admin`**: Assigned to the deploying principal (CI/CD Service Principal) → allows dashboard and data source management.

### Compatibility Fixes (azurerm v4)
The `azurerm` provider was upgraded from `~> 3.90.0` to `~> 4.0` to support Grafana v11. Breaking changes fixed:
- `health_check_eviction_time_in_min` added to the App Service (`compute.tf`).
- `DOCKER_REGISTRY_SERVER_URL` removed from `app_settings` (now managed natively by `site_config`).
- `enable_non_ssl_port` replaced by `non_ssl_port_enabled` in Redis (`redis.tf`).
- Registered the `Microsoft.Dashboard` resource provider on the subscription.
- Assigned `Role Based Access Control Administrator` role to the CI Service Principal.

## Key Files (Phase 1 Snapshot)

| File | Description |
|---|---|
| [`monitoring.tf`](./monitoring.tf) | Snapshot — Monitoring stack: Log Analytics, App Insights, Grafana, dashboard deployment |
| [`alerts.tf`](./alerts.tf) | Snapshot — Azure Monitor alerts: CPU, HTTP 5xx, SQL storage |

> Live source files are located at [`terraform/monitoring.tf`](../../../terraform/monitoring.tf) and [`terraform/alerts.tf`](../../../terraform/alerts.tf).

### Configured Alerts (`alerts.tf`)

| Alert | Target Resource | Condition | Notification |
|---|---|---|---|
| `alert-asp-cpu-high` | App Service Plan | CPU > 80% (average) | Email via Action Group |
| `alert-webapp-5xx` | Web App | HTTP 5xx > 5 (total) | Email via Action Group |
| `alert-sql-storage-low` | SQL Database | Storage > 90% (average) | Email via Action Group |

## Result
The observability infrastructure is fully defined in Terraform. Grafana is deployed on App Service with the Azure Monitor plugin pre-installed. Alerts cover critical incidents (CPU saturation, service unavailability, storage exhaustion).
