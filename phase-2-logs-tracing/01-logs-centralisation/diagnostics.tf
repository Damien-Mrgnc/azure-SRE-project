# ---
# 8. Diagnostic Settings — Centralisation des logs vers Log Analytics
# ---
# Ces ressources activent l'envoi automatique des logs de chaque service Azure
# (App Service, SQL, Redis) vers le Log Analytics Workspace de la Phase 1.
# Les logs sont ensuite interrogeables via KQL (Kusto Query Language).

# --- App Service (Application Web) ---
resource "azurerm_monitor_diagnostic_setting" "app_service" {
  name                       = "diag-app-${var.project_name}"
  target_resource_id         = azurerm_linux_web_app.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Logs applicatifs (stdout/stderr de l'app Node.js)
  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  # Logs HTTP Access (toutes les requêtes entrantes)
  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  # Logs d'erreurs de la plateforme App Service
  enabled_log {
    category = "AppServiceAppLogs"
  }

  # Métriques (CPU, Mémoire, Requêtes) vers Log Analytics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# --- SQL Database ---
resource "azurerm_monitor_diagnostic_setting" "sql_database" {
  name                       = "diag-sql-${var.project_name}"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Logs des requêtes SQL lentes (> seuil configurable)
  enabled_log {
    category = "SQLInsights"
  }

  # Logs des erreurs et blocages SQL
  enabled_log {
    category = "Errors"
  }

  metric {
    category = "Basic"
    enabled  = true
  }
}

# --- Azure Cache for Redis ---
resource "azurerm_monitor_diagnostic_setting" "redis" {
  name                       = "diag-redis-${var.project_name}"
  target_resource_id         = azurerm_redis_cache.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Connexions et erreurs Redis
  enabled_log {
    category = "ConnectedClientList"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
