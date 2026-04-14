# ---
# 9. Autoscaling — Azure Monitor Autoscale Setting
# ---
# Prérequis : le SKU de l'App Service Plan doit être Standard (S1+) ou Premium (P1v2+).
# Le SKU B1 (Basic) ne supporte pas l'autoscaling.
# Pour activer : changer app_service_sku = "S1" dans variables.tf / terraform.tfvars.
#
# Logique :
#   Scale-OUT : CPU moyen > 75% pendant 5 min → +1 instance (max 3)
#   Scale-IN  : CPU moyen < 25% pendant 10 min → -1 instance (min 1)
# ---

resource "azurerm_monitor_autoscale_setting" "app_service" {
  name                = "autoscale-${var.project_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_service_plan.main.id
  enabled             = true

  profile {
    name = "default"

    capacity {
      default = 1
      minimum = 1
      maximum = var.autoscale_max_instances
    }

    # --- Règle Scale-OUT (charge élevée) ---
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        metric_namespace   = "Microsoft.Web/serverfarms"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M" # Attendre 5 min avant le prochain scale-out
      }
    }

    # --- Règle Scale-IN (charge faible) ---
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        metric_namespace   = "Microsoft.Web/serverfarms"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT10M" # Attendre 10 min avant le prochain scale-in (éviter le flapping)
      }
    }
  }

  # Notification email lors d'un événement de scaling
  notification {
    email {
      send_to_subscription_administrator    = false
      send_to_subscription_co_administrator = false
      custom_emails                         = [var.alert_email]
    }
  }

  tags = local.tags
}
