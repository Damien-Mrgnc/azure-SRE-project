# Step 1: Log Centralization

*Lire la [Version Française](README_FR.md) ici.*

## Objective

Centralize application and infrastructure logs into **Azure Log Analytics**, providing a unified, queryable view via KQL (Kusto Query Language).

## Log Pipeline Architecture

```
Node.js App (Winston JSON → stdout)
        ↓
Azure App Service (captures stdout/stderr)
        ↓ [Diagnostic Settings]
Azure Log Analytics Workspace
        ↓ [KQL]
Grafana / Azure Portal (visualization)
```

## Application Side — Winston + Correlation ID

### logger.js

The logger is configured with `winston` in **structured JSON format**, required for Log Analytics to automatically parse and index fields.

```javascript
const logger = winston.createLogger({
    level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()  // JSON mandatory for Azure
    ),
    defaultMeta: { service: 'runtime-governance-app' },
    transports: [new winston.transports.Console()], // stdout → captured by Azure
});
```

**Why JSON?** Log Analytics ingests the `ResultDescription` field as raw text. If the log is in JSON, it can be parsed with `parse_json()` in KQL, making each field (`level`, `correlationId`, `statusCode`) filterable.

### requestLogger.js — Correlation ID

Each request receives a unique **Correlation ID** (`x-correlation-id` header or generated UUID). The same ID is propagated through all logs for that request, enabling retrieval of a complete transaction history in Log Analytics.

```javascript
req.correlationId = req.headers['x-correlation-id'] || require('crypto').randomUUID();
logger.info('Incoming Request', { correlationId: req.correlationId, ... });
// ... processing ...
logger.info('Response Sent', { correlationId: req.correlationId, statusCode: res.statusCode });
```

## Infrastructure Side — Diagnostic Settings Terraform

`diagnostics.tf` enables automatic log forwarding from each Azure resource to the Log Analytics Workspace.

| Resource | Log Categories |
|---|---|
| App Service | `AppServiceConsoleLogs` (stdout), `AppServiceHTTPLogs` (HTTP access), `AppServiceAppLogs` |
| SQL Database | `SQLInsights` (slow queries), `Errors` |
| Redis Cache | `ConnectedClientList` (connections) |

## Useful KQL Queries

```kusto
// Find all logs for a request by correlation ID
AppServiceConsoleLogs
| where ResultDescription has 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
| order by TimeGenerated asc

// Error rate per 5-minute interval
AppServiceConsoleLogs
| where ResultDescription has '"level":"error"'
| summarize ErrorCount = count() by bin(TimeGenerated, 5m)
| render timechart

// Slow HTTP requests (> 500ms)
AppServiceHTTPLogs
| where TimeTaken > 500
| project TimeGenerated, CsUriStem, TimeTaken, ScStatus
| order by TimeTaken desc

// HTTP 5xx errors
AppServiceHTTPLogs
| where ScStatus >= 500
| summarize count() by bin(TimeGenerated, 1m), ScStatus
```

## Files in This Step

| File | Description |
|---|---|
| [`logger.js`](./logger.js) | Snapshot — Winston configuration (structured JSON) |
| [`requestLogger.js`](./requestLogger.js) | Snapshot — Correlation ID middleware + request/response logs |
| [`diagnostics.tf`](./diagnostics.tf) | Snapshot — Terraform Diagnostic Settings (App Service, SQL, Redis → Log Analytics) |
| [`log-output-example.json`](./log-output-example.json) | Example KQL query results from Log Analytics |

## Next Step

Logs tell you **what happened**. [Distributed Tracing](../02-distributed-tracing/README.md) shows you **why and where** by following the exact path of a request across all services.
