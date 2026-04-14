# Step 1: Autoscaling Rules

*Lire la [Version Française](README_FR.md) ici.*

## Objective

Configure **horizontal autoscaling** for the App Service Plan via Terraform, linking trigger rules to the CPU metrics collected in Phase 1.

## SKU Prerequisite

> **Important**: The B1 (Basic) SKU **does not support** autoscaling. Switch to `S1` (Standard) or `P1v2` (Premium) in `variables.tf`:
> ```hcl
> variable "app_service_sku" {
>   default = "S1"  # Change from "B1" to "S1"
> }
> ```

## Autoscaling Logic

```
CPU > 75% for 5 min  →  Scale-OUT: +1 instance  (max 3)
                         Cooldown: 5 min

CPU < 25% for 10 min →  Scale-IN:  -1 instance  (min 1)
                         Cooldown: 10 min
```

**Cooldown** prevents *flapping* (rapid oscillation between scale-out and scale-in). Scale-in has a longer cooldown (10 min) to ensure load has genuinely dropped before reducing instances.

## Terraform Implementation

```hcl
resource "azurerm_monitor_autoscale_setting" "app_service" {
  target_resource_id = azurerm_service_plan.main.id

  profile {
    capacity {
      default = 1
      minimum = 1
      maximum = var.autoscale_max_instances  # default: 3
    }

    # Scale-OUT
    rule {
      metric_trigger {
        metric_name = "CpuPercentage"
        time_window = "PT5M"
        threshold   = 75
        operator    = "GreaterThan"
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
        metric_name = "CpuPercentage"
        time_window = "PT10M"
        threshold   = 25
        operator    = "LessThan"
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

## New Variable Added (variables.tf)

```hcl
variable "autoscale_max_instances" {
  description = "Maximum number of App Service instances (requires S1+ SKU)"
  type        = number
  default     = 3
}
```

## Link to Phase 1

The `CpuPercentage` metric used here is the **same source** as:
- The `alert-asp-cpu-high` alert (Phase 1 — triggers notification at 80%)
- The "CPU Saturation" panel on the Grafana dashboard (Phase 1)

Autoscaling fires at 75% (before the 80% alert) to proactively absorb load before it becomes an incident.

## Files in This Step

| File | Description |
|---|---|
| [`autoscaling.tf`](./autoscaling.tf) | Snapshot — Terraform autoscaling rules (scale-out/in, cooldowns, notification) |

> Live source: [`terraform/autoscaling.tf`](../../../terraform/autoscaling.tf)
