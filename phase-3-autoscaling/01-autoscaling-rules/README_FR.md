# Étape 1 : Règles d'Autoscaling

*Read the [English Version](README.md) here.*

## Objectif

Configurer l'**autoscaling horizontal** de l'App Service Plan via Terraform, en liant les règles de déclenchement aux métriques CPU collectées en Phase 1.

## Prérequis SKU

> **Important** : Le SKU B1 (Basic) **ne supporte pas** l'autoscaling. Passer à `S1` (Standard) ou `P1v2` (Premium) dans `variables.tf` :
> ```hcl
> variable "app_service_sku" {
>   default = "S1"  # Changer de "B1" à "S1"
> }
> ```

## Logique d'Autoscaling

```
CPU > 75% pendant 5 min  →  Scale-OUT : +1 instance  (max 3)
                             Cooldown : 5 min

CPU < 25% pendant 10 min →  Scale-IN  : -1 instance  (min 1)
                             Cooldown : 10 min
```

Le **cooldown** est essentiel pour éviter le *flapping* (oscillations rapides entre scale-out et scale-in). Le scale-in a un cooldown plus long (10 min) pour s'assurer que la charge est durablement redescendue avant de réduire les instances.

## Implémentation Terraform

```hcl
resource "azurerm_monitor_autoscale_setting" "app_service" {
  target_resource_id = azurerm_service_plan.main.id

  profile {
    capacity {
      default = 1
      minimum = 1
      maximum = var.autoscale_max_instances  # défaut : 3
    }

    # Scale-OUT
    rule {
      metric_trigger {
        metric_name      = "CpuPercentage"
        time_window      = "PT5M"
        threshold        = 75
        operator         = "GreaterThan"
      }
      scale_action {
        direction = "Increase"
        value     = 1
        cooldown  = "PT5M"
      }
    }

    # Scale-IN
    rule {
      metric_trigger {
        metric_name      = "CpuPercentage"
        time_window      = "PT10M"
        threshold        = 25
        operator         = "LessThan"
      }
      scale_action {
        direction = "Decrease"
        value     = 1
        cooldown  = "PT10M"
      }
    }
  }

  notification {
    email {
      custom_emails = [var.alert_email]
    }
  }
}
```

## Nouvelle variable ajoutée (variables.tf)

```hcl
variable "autoscale_max_instances" {
  description = "Maximum number of App Service instances (requires S1+ SKU)"
  type        = number
  default     = 3
}
```

## Lien avec la Phase 1

La métrique `CpuPercentage` utilisée ici est la **même source** que celle surveillée par :
- L'alerte `alert-asp-cpu-high` (Phase 1 — déclenche une notification à 80%)
- Le panel "Saturation CPU" du dashboard Grafana (Phase 1)

L'autoscaling agit à 75% (avant l'alerte à 80%) pour absorber la charge proactivement.

## Fichiers de cette étape

| Fichier | Description |
|---|---|
| [`autoscaling.tf`](./autoscaling.tf) | Snapshot — Règles d'autoscaling Terraform (scale-out/in, cooldowns, notification) |

> Fichier source en production : [`terraform/autoscaling.tf`](../../../terraform/autoscaling.tf)
