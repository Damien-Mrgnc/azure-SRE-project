# Phase 1 : Observabilité (Monitoring & Métriques)

*Read the [English Version](README.md) here.*

## Objectif
Implémenter le premier pilier du SRE : l'**Observabilité**. Instrumenter l'application pour exposer des métriques custom, déployer une stack de monitoring complète (Azure Monitor + Managed Grafana) via Terraform, et construire un tableau de bord de santé basé sur les **4 Golden Signals** (Trafic, Erreurs, Latence, Saturation).

## Aperçu Structurel
Cette phase couvre l'ensemble de la chaîne d'observabilité, du code applicatif jusqu'aux dashboards de visualisation.

1. [**Étape 1 : Côté App — Instrumentation Prometheus**](./01-app-instrumentation/README_FR.md)
2. [**Étape 2 : Côté Infra — Déploiement de la Stack Monitoring**](./02-infra-monitoring/README_FR.md)
3. [**Étape 3 : Côté Visualisation — Grafana as Code**](./03-visualisation-grafana/README_FR.md)

---

## Contenu du Snapshot

Ce dossier est un **snapshot** des livrables de la Phase 1. Il contient les fichiers clés tels qu'ils existaient à la fin de cette phase.

| Chemin | Description |
|---|---|
| `01-app-instrumentation/server.js` | App Node.js instrumentée (prom-client, endpoint /metrics) |
| `01-app-instrumentation/metrics-output-example.txt` | Sortie Prometheus simulée de /metrics |
| `02-infra-monitoring/monitoring.tf` | Terraform — Grafana, Log Analytics, App Insights |
| `02-infra-monitoring/alerts.tf` | Terraform — Règles d'alertes Azure Monitor |
| `03-visualisation-grafana/dashboards/webapp-health.json` | Dashboard Grafana JSON (4 Golden Signals) |

---

## Stack Technique
- **prom-client** : Client Prometheus pour Node.js — exposition des métriques custom.
- **response-time** : Middleware de capture automatique des temps de réponse.
- **Azure Log Analytics** : Stockage centralisé des logs.
- **Azure Application Insights** : APM (Application Performance Monitoring).
- **Azure Managed Grafana** : Visualisation et dashboards SRE (déployé via Docker sur App Service).
- **Terraform (azurerm ~> 4.0)** : Infrastructure as Code pour l'ensemble de la stack.

## Statut : Terminé ✅
