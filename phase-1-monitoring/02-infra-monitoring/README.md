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

## Key Files
- `terraform/monitoring.tf` — Full monitoring stack definition (Log Analytics, App Insights, Monitor Workspace, Grafana, RBAC).
- `terraform/providers.tf` — azurerm provider upgrade (`~> 4.0`).
- `terraform/compute.tf` — App Service compatibility fixes.
- `terraform/redis.tf` — Redis deprecation fix.

## Result
The observability infrastructure is fully deployed and managed by Terraform. Grafana has the necessary permissions to read all Azure Monitor data from the Resource Group. CI/CD can manage dashboards autonomously.
