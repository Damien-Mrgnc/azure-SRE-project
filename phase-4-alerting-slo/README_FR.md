# Phase 4 : SLO, SLI et Alerting

*Read the [English Version](README.md) here.*

## Objectif

Formaliser les engagements de fiabilité (SLO/SLI/Error Budget) et configurer les alertes correspondantes dans Azure Monitor. Cette phase transforme l'observabilité des phases précédentes en **décisions opérationnelles concrètes**.

## Aperçu Structurel

1. [**Étape 1 : Définitions SLI/SLO/Error Budget**](./01-slo-definitions/README_FR.md)
2. [**Étape 2 : Alerting Azure Monitor**](./02-alerting/README_FR.md)

---

## Connexion avec les autres phases

| Phase | Contribution à la Phase 4 |
|---|---|
| Phase 1 | Métriques Prometheus + Azure Monitor → sources des SLI |
| Phase 2 | Logs Log Analytics → requêtes KQL pour alertes SLO |
| Phase 3 | Autoscaling à 75% → agit **avant** l'alerte SLO CPU à 80% |
| Phase 4 | **SLO définis + alertes configurées** |
| Phase 5 | Chaos Engineering valide que les alertes sonnent correctement |

## Contenu du Snapshot

| Chemin | Description |
|---|---|
| `01-slo-definitions/slo-definitions.md` | 4 SLO définis : disponibilité (99.9%), latence p95 (< 500ms), erreurs (< 1%), CPU (< 80%) |
| `02-alerting/alerts.tf` | Alertes infrastructure (Phase 1) + alertes SLO KQL (Phase 4) |
| `02-alerting/alert-notification-example.json` | 4 exemples de payloads reçus (Common Alert Schema) |

---

## Stack Technique

- **`azurerm_monitor_scheduled_query_rules_alert_v2`** : Alertes basées sur requêtes KQL (taux d'erreurs %, latence p99)
- **`azurerm_monitor_metric_alert`** : Alertes métriques directes (CPU, Http5xx count)
- **`azurerm_monitor_action_group`** : Routage des notifications vers email
- **KQL** : Langage de requête pour les alertes basées sur Log Analytics
- **Common Alert Schema** : Format unifié des payloads de notification Azure

## Statut : Terminé ✅
