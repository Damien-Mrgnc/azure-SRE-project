# Étape 2 : Alerting (Azure Monitor + SLO Alerts)

*Read the [English Version](README.md) here.*

## Objectif

Configurer des alertes liées directement aux SLO définis en Étape 1, en complément des alertes infrastructure existantes (Phase 1). Les alertes doivent distinguer les **warnings** (dégradation précoce) des **incidents critiques** (SLO breach).

## Architecture d'alerting

```
Métriques Azure Monitor / Log Analytics
         ↓
azurerm_monitor_metric_alert          → Alertes métriques (CPU, 5xx count)
azurerm_monitor_scheduled_query_rules → Alertes KQL (taux d'erreurs %, latence p99)
         ↓
azurerm_monitor_action_group          → Email (var.alert_email)
```

## Alertes configurées

### Alertes SLO (Phase 4 — Nouvelles)

| Alerte | Type | Condition | Sévérité |
|---|---|---|---|
| `slo-availability-breach` | Log (KQL) | Taux 5xx > 1% sur 5 min | Sev1 (Error) |
| `slo-latency-breach` | Log (KQL) | p99 latence > 800ms sur 10 min | Sev2 (Warning) |

### Alertes Infrastructure (Phase 1 — Existantes)

| Alerte | Type | Condition | Sévérité |
|---|---|---|---|
| `alert-asp-cpu-high` | Métrique | CPU > 80% (moyenne 5 min) | Sev2 |
| `alert-webapp-5xx` | Métrique | Http5xx > 5 (total 5 min) | Sev2 |
| `alert-sql-storage-low` | Métrique | Stockage SQL > 90% | Sev2 |

### Différence Phase 1 vs Phase 4

- **Phase 1** : Alerte sur le **count absolu** (`Http5xx > 5`) — déclenche même si le trafic est faible
- **Phase 4** : Alerte sur le **taux relatif** (`erreurs / total > 1%`) — respecte la sémantique SLO

## Notification reçue (exemple)

Voir [`alert-notification-example.json`](./alert-notification-example.json) pour 4 scénarios complets :
1. SLO Disponibilité breached (Sev1) — taux 5xx > 1%
2. SLO Latence warning (Sev2) — p99 > 800ms
3. Alerte CPU infrastructure (Sev2) — CPU 82.4%
4. Résolution automatique — alerte fermée après retour à la normale

## Fichiers de cette étape

| Fichier | Description |
|---|---|
| [`alerts.tf`](./alerts.tf) | Snapshot — alertes infrastructure Phase 1 + alertes SLO Phase 4 |
| [`alert-notification-example.json`](./alert-notification-example.json) | Exemples de payloads reçus (Common Alert Schema) |

> Fichier source en production : [`terraform/alerts.tf`](../../../terraform/alerts.tf)
