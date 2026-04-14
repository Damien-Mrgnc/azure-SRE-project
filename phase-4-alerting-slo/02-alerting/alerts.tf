# ---
# 7. Alerting (Action Groups & Metric Alerts)
# ---

# 1. Action Group (Who to notify)
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.project_name}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "p1-alerts"

  email_receiver {
    name                    = "admin-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = local.tags
}

# 2. App Service Plan - High CPU Alert (>80%)
resource "azurerm_monitor_metric_alert" "asp_cpu" {
  name                = "alert-asp-cpu-high"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_service_plan.main.id]
  description         = "Action will be triggered when CPU percentage is greater than 80."

  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.tags
}

# 3. Web App - Service Unavailable (HTTP 5xx)
resource "azurerm_monitor_metric_alert" "app_http_5xx" {
  name                = "alert-webapp-5xx"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_web_app.main.id]
  description         = "Action will be triggered when HTTP 5xx errors occur."

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.tags
}

# ---
# Phase 4 — Alertes SLO
# ---

# SLO Disponibilité : alerte si HTTP 5xx > 1% du trafic sur 5 min (Log Analytics query)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "slo_availability" {
  name                = "slo-availability-breach"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  description         = "SLO Breach: HTTP 5xx error rate exceeded 1% — availability SLO at risk."
  severity            = 1 # 0=Critical, 1=Error, 2=Warning

  scopes = [azurerm_log_analytics_workspace.main.id]

  evaluation_frequency = "PT5M"  # Évaluer toutes les 5 min
  window_duration      = "PT5M"  # Fenêtre d'analyse de 5 min

  criteria {
    query = <<-EOT
      AppServiceHTTPLogs
      | where TimeGenerated > ago(5m)
      | summarize total = count(), errors5xx = countif(ScStatus >= 500)
      | extend error_rate_pct = (toreal(errors5xx) / toreal(total)) * 100
      | where error_rate_pct > 1.0
    EOT

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.main.id]
    custom_properties = {
      slo       = "Availability"
      threshold = "99.9%"
    }
  }

  tags = local.tags
}

# SLO Latence : alerte si temps de réponse moyen > 800ms sur 10 min
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "slo_latency" {
  name                = "slo-latency-breach"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  description         = "SLO Breach: Average response time exceeded 800ms — latency SLO at risk."
  severity            = 2 # Warning

  scopes = [azurerm_log_analytics_workspace.main.id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT10M"

  criteria {
    query = <<-EOT
      AppServiceHTTPLogs
      | where TimeGenerated > ago(10m)
      | summarize p99 = percentile(TimeTaken, 99)
      | where p99 > 800
    EOT

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 2
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.main.id]
    custom_properties = {
      slo       = "Latency"
      threshold = "p99 < 1000ms"
    }
  }

  tags = local.tags
}

# ---
# Alertes infrastructure existantes (Phase 1)
# ---

# 4. SQL Database - Low Storage Space
resource "azurerm_monitor_metric_alert" "sql_storage" {
  name                = "alert-sql-storage-low"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_mssql_database.main.id]
  description         = "Action will be triggered when SQL storage usage is high."

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.tags
}
