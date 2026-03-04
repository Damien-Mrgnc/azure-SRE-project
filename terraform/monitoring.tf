# ---
# 6. Observability (Log Analytics & App Insights)
# ---

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${random_id.server_suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project_name}-${random_id.server_suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = local.tags
}

# ---
# 7. SRE Observability (Azure Monitor Managed Service & Managed Grafana)
# ---

# Espace de travail Azure Monitor (nécessaire pour stocker les métriques Prometheus si utilisées, 
# et s'intègre nativement à Managed Grafana)
resource "azurerm_monitor_workspace" "main" {
  name                = "amw-${var.project_name}-${random_id.server_suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.tags
}

# Azure Managed Grafana
resource "azurerm_dashboard_grafana" "main" {
  name                              = "grf-${random_id.server_suffix.hex}"
  location                          = azurerm_resource_group.main.location
  resource_group_name               = azurerm_resource_group.main.name
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true
  sku                               = "Standard"
  zone_redundancy_enabled           = false

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.main.id
  }

  tags = local.tags
}

# Autoriser Grafana à lire les données Azure Monitor (Metrics / App Insights / Log Analytics)
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.main.identity[0].principal_id
}

# Accorder les droits d'administrateur Grafana à l'utilisateur lançant le script (toi/la CI)
resource "azurerm_role_assignment" "grafana_admin" {
  scope                = azurerm_dashboard_grafana.main.id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}
