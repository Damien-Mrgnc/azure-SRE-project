# Phase 2 : Logs et Tracing Distribué

*Read the [English Version](README.md) here.*

## Objectif

Implémenter le deuxième pilier de l'observabilité SRE : **Logs + Traces**. Centraliser les logs applicatifs et infrastructure dans Azure Log Analytics, et instrumenter le code avec OpenTelemetry pour suivre chaque requête de bout en bout à travers tous les services.

## Aperçu Structurel

1. [**Étape 1 : Centralisation des Logs**](./01-logs-centralisation/README_FR.md)
2. [**Étape 2 : Tracing Distribué (OpenTelemetry)**](./02-distributed-tracing/README_FR.md)

---

## Les 3 Piliers de l'Observabilité

Cette phase complète le triangle de l'observabilité SRE :

| Pilier | Outil | Phase |
|---|---|---|
| **Métriques** | Prometheus + Grafana | Phase 1 ✅ |
| **Logs** | Winston + Log Analytics | Phase 2 ✅ |
| **Traces** | OpenTelemetry + Application Insights | Phase 2 ✅ |

## Contenu du Snapshot

| Chemin | Description |
|---|---|
| `01-logs-centralisation/logger.js` | Configuration Winston (JSON structuré → stdout) |
| `01-logs-centralisation/requestLogger.js` | Middleware correlation ID |
| `01-logs-centralisation/diagnostics.tf` | Terraform — envoi logs Azure vers Log Analytics |
| `01-logs-centralisation/log-output-example.json` | Exemple de résultats KQL sur Log Analytics |
| `02-distributed-tracing/tracing.js` | Initialisation OTel SDK + Azure Monitor Exporter |
| `02-distributed-tracing/server.js` | server.js avec tracing comme premier import |
| `02-distributed-tracing/trace-output-example.json` | Exemples de traces (3 scénarios : hit cache, miss cache, erreur SQL) |

---

## Stack Technique

- **winston** : Logger structuré JSON → stdout → capturé par Azure App Service
- **Correlation ID** : UUID propagé à travers tous les logs d'une même requête
- **OpenTelemetry SDK** (`@opentelemetry/sdk-node`) : Framework de tracing standard
- **Auto-instrumentations** : HTTP, Express, Prisma (SQL), Redis — sans modifier le code métier
- **Azure Monitor Exporter** (`@azure/monitor-opentelemetry-exporter`) : Export des traces vers Application Insights
- **Diagnostic Settings Terraform** : Envoi automatique des logs App Service / SQL / Redis vers Log Analytics
- **KQL** : Langage de requête pour interroger les logs dans Log Analytics

## Statut : Terminé ✅
