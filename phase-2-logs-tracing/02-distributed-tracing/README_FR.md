# Étape 2 : Tracing Distribué (OpenTelemetry)

*Read the [English Version](README.md) here.*

## Objectif

Implémenter le **tracing distribué** avec OpenTelemetry pour suivre le chemin exact d'une requête à travers tous les services (HTTP → Express → Redis → SQL), et exporter les traces vers **Azure Application Insights**.

## Pourquoi le Tracing ?

Les logs disent *ce qui s'est passé*. Les métriques disent *combien de fois*. Le tracing dit *où exactement* le temps a été passé dans une requête :

```
GET /api/config (28ms total)
├── redis.get appConfig (5ms)  ← Cache HIT, fin de la requête
└── [SQL non exécuté]

POST /api/admin/config (150ms total)
├── redis.get appConfig (5ms)  ← Cache MISS
├── prisma:query findMany (25ms)
├── prisma:$transaction upsert+audit (88ms)
└── redis.del appConfig (7ms)
```

Sans tracing, on sait que `/api/admin/config` prend 150ms. Avec le tracing, on sait que **59%** de ce temps est dans la transaction SQL.

## Architecture

```
App Node.js
    ↓ (auto-instrumentation OTel)
tracing.js → NodeSDK
    ↓
AzureMonitorTraceExporter
    ↓ (APPLICATIONINSIGHTS_CONNECTION_STRING)
Azure Application Insights
    ↓
Azure Monitor / Grafana (corrélation Logs + Traces + Metrics)
```

## Implémentation — tracing.js

### Initialisation du SDK

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { AzureMonitorTraceExporter } = require('@azure/monitor-opentelemetry-exporter');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const sdk = new NodeSDK({
    resource: new Resource({
        [ATTR_SERVICE_NAME]: 'runtime-governance-app',
        [ATTR_SERVICE_VERSION]: '1.0.0',
    }),
    traceExporter: new AzureMonitorTraceExporter(),
    instrumentations: [getNodeAutoInstrumentations({ ... })],
});

sdk.start();
```

### Auto-instrumentation activée

| Bibliothèque | Ce qui est tracé automatiquement |
|---|---|
| `http` | Toutes les requêtes HTTP entrantes et sortantes |
| `express` | Durée de chaque route, middleware |
| `prisma` | Chaque requête SQL (opération, table, durée) |
| `redis` | Chaque commande Redis (GET, SET, DEL, durée) |

### Règle critique : premier import dans server.js

```javascript
// DOIT être le premier require — avant express, prisma, etc.
require('./config/tracing');

const express = require('express');
// ...
```

L'OTel SDK doit s'initialiser avant que les modules soient chargés pour pouvoir les "patcher" (monkey-patching) et injecter le tracing automatiquement.

## Nouvelles dépendances (package.json)

```json
"@azure/monitor-opentelemetry-exporter": "^1.0.0",
"@opentelemetry/auto-instrumentations-node": "^0.56.0",
"@opentelemetry/resources": "^1.30.1",
"@opentelemetry/sdk-node": "^0.57.2",
"@opentelemetry/semantic-conventions": "^1.30.0"
```

## Exemple de traces

Voir [`trace-output-example.json`](./trace-output-example.json) pour 3 scénarios complets :

1. **Cache HIT** — `GET /api/config` → Redis (5ms) → réponse en 28ms
2. **Cache MISS** — `POST /api/admin/config` → Redis MISS → SQL findMany → SQL $transaction → Redis DEL → 150ms total
3. **Erreur SQL** — `GET /api/config` → Redis MISS → SQL timeout (730ms) → HTTP 500 avec exception tracée

## Corrélation Logs + Traces + Metrics

Application Insights corrèle automatiquement les trois signaux via le `traceId` / `correlationId` :

| Signal | Outil | Ce qu'on voit |
|---|---|---|
| Metrics | Grafana (Azure Monitor) | CPU 82%, 5xx soudain |
| Logs | Log Analytics (KQL) | `"level":"error"`, `correlationId: xyz` |
| Traces | Application Insights | Span SQL timeout (730ms) sur `/api/config` |

## Fichiers de cette étape

| Fichier | Description |
|---|---|
| [`tracing.js`](./tracing.js) | Snapshot — Initialisation OTel SDK + AzureMonitorExporter |
| [`server.js`](./server.js) | Snapshot — server.js avec `require('./config/tracing')` en premier |
| [`trace-output-example.json`](./trace-output-example.json) | Exemples de traces OTel (3 scénarios : cache hit, cache miss, erreur SQL) |
