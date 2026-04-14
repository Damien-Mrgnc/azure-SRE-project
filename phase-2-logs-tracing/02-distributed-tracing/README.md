# Step 2: Distributed Tracing (OpenTelemetry)

*Lire la [Version Française](README_FR.md) ici.*

## Objective

Implement **distributed tracing** with OpenTelemetry to follow the exact path of a request across all services (HTTP → Express → Redis → SQL), and export traces to **Azure Application Insights**.

## Why Tracing?

Logs tell you *what happened*. Metrics tell you *how often*. Tracing tells you *exactly where* time was spent in a request:

```
GET /api/config (28ms total)
├── redis.get appConfig (5ms)  ← Cache HIT, request ends here
└── [SQL not executed]

POST /api/admin/config (150ms total)
├── redis.get appConfig (5ms)  ← Cache MISS
├── prisma:query findMany (25ms)
├── prisma:$transaction upsert+audit (88ms)
└── redis.del appConfig (7ms)
```

Without tracing, you know `/api/admin/config` takes 150ms. With tracing, you know **59%** of that time is in the SQL transaction.

## Architecture

```
Node.js App
    ↓ (OTel auto-instrumentation)
tracing.js → NodeSDK
    ↓
AzureMonitorTraceExporter
    ↓ (APPLICATIONINSIGHTS_CONNECTION_STRING)
Azure Application Insights
    ↓
Azure Monitor / Grafana (Logs + Traces + Metrics correlation)
```

## Implementation — tracing.js

### SDK Initialization

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

### Auto-instrumentation Enabled

| Library | What is traced automatically |
|---|---|
| `http` | All incoming and outgoing HTTP requests |
| `express` | Duration of each route, middleware |
| `prisma` | Every SQL query (operation, table, duration) |
| `redis` | Every Redis command (GET, SET, DEL, duration) |

### Critical Rule: First Import in server.js

```javascript
// MUST be the first require — before express, prisma, etc.
require('./config/tracing');

const express = require('express');
// ...
```

The OTel SDK must initialize before modules are loaded so it can patch them (monkey-patching) and inject tracing automatically.

## New Dependencies (package.json)

```json
"@azure/monitor-opentelemetry-exporter": "^1.0.0",
"@opentelemetry/auto-instrumentations-node": "^0.56.0",
"@opentelemetry/resources": "^1.30.1",
"@opentelemetry/sdk-node": "^0.57.2",
"@opentelemetry/semantic-conventions": "^1.30.0"
```

## Trace Examples

See [`trace-output-example.json`](./trace-output-example.json) for 3 complete scenarios:

1. **Cache HIT** — `GET /api/config` → Redis (5ms) → response in 28ms
2. **Cache MISS** — `POST /api/admin/config` → Redis MISS → SQL findMany → SQL $transaction → Redis DEL → 150ms total
3. **SQL Error** — `GET /api/config` → Redis MISS → SQL timeout (730ms) → HTTP 500 with traced exception

## Logs + Traces + Metrics Correlation

Application Insights automatically correlates all three signals via `traceId` / `correlationId`:

| Signal | Tool | What you see |
|---|---|---|
| Metrics | Grafana (Azure Monitor) | CPU 82%, sudden 5xx spike |
| Logs | Log Analytics (KQL) | `"level":"error"`, `correlationId: xyz` |
| Traces | Application Insights | SQL timeout span (730ms) on `/api/config` |

## Files in This Step

| File | Description |
|---|---|
| [`tracing.js`](./tracing.js) | Snapshot — OTel SDK initialization + AzureMonitorExporter |
| [`server.js`](./server.js) | Snapshot — server.js with `require('./config/tracing')` as first import |
| [`trace-output-example.json`](./trace-output-example.json) | OTel trace examples (3 scenarios: cache hit, cache miss, SQL error) |
