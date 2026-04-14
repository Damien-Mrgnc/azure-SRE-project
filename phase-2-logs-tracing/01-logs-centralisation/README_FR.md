# Étape 1 : Centralisation des Logs

*Read the [English Version](README.md) here.*

## Objectif

Centraliser les logs de l'application et de l'infrastructure dans **Azure Log Analytics**, afin de disposer d'une vue unifiée et interrogeable via KQL (Kusto Query Language).

## Architecture de la chaîne de logs

```
App Node.js (Winston JSON → stdout)
        ↓
Azure App Service (capture stdout/stderr)
        ↓ [Diagnostic Settings]
Azure Log Analytics Workspace
        ↓ [KQL]
Grafana / Azure Portal (visualisation)
```

## Côté Application — Winston + Correlation ID

### logger.js

Le logger est configuré avec `winston` en format **JSON structuré**, obligatoire pour que Log Analytics puisse parser et indexer les champs automatiquement.

```javascript
const logger = winston.createLogger({
    level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()  // JSON mandatory for Azure
    ),
    defaultMeta: { service: 'runtime-governance-app' },
    transports: [new winston.transports.Console()], // stdout → capturé par Azure
});
```

**Pourquoi JSON ?** Log Analytics ingère le champ `ResultDescription` comme texte brut. Si le log est en JSON, il peut être parsé avec `parse_json()` en KQL, rendant chaque champ (`level`, `correlationId`, `statusCode`) filtrable.

### requestLogger.js — Correlation ID

Chaque requête reçoit un **Correlation ID** unique (`x-correlation-id` header ou UUID généré). Ce même ID est propagé dans tous les logs de la requête, permettant de retrouver l'historique complet d'une transaction dans Log Analytics.

```javascript
req.correlationId = req.headers['x-correlation-id'] || require('crypto').randomUUID();
logger.info('Incoming Request', { correlationId: req.correlationId, ... });
// ... traitement ...
logger.info('Response Sent', { correlationId: req.correlationId, statusCode: res.statusCode });
```

## Côté Infrastructure — Diagnostic Settings Terraform

`diagnostics.tf` active l'envoi automatique des logs de chaque ressource Azure vers le Log Analytics Workspace.

| Ressource | Catégories de logs |
|---|---|
| App Service | `AppServiceConsoleLogs` (stdout), `AppServiceHTTPLogs` (accès HTTP), `AppServiceAppLogs` |
| SQL Database | `SQLInsights` (requêtes lentes), `Errors` |
| Redis Cache | `ConnectedClientList` (connexions) |

## Requêtes KQL utiles

```kusto
// Retrouver tous les logs d'une requête par correlation ID
AppServiceConsoleLogs
| where ResultDescription has 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
| order by TimeGenerated asc

// Taux d'erreurs par intervalle de 5 minutes
AppServiceConsoleLogs
| where ResultDescription has '"level":"error"'
| summarize ErrorCount = count() by bin(TimeGenerated, 5m)
| render timechart

// Requêtes HTTP lentes (> 500ms)
AppServiceHTTPLogs
| where TimeTaken > 500
| project TimeGenerated, CsUriStem, TimeTaken, ScStatus
| order by TimeTaken desc

// Erreurs HTTP 5xx
AppServiceHTTPLogs
| where ScStatus >= 500
| summarize count() by bin(TimeGenerated, 1m), ScStatus
```

## Fichiers de cette étape

| Fichier | Description |
|---|---|
| [`logger.js`](./logger.js) | Snapshot — Configuration Winston (JSON structuré) |
| [`requestLogger.js`](./requestLogger.js) | Snapshot — Middleware correlation ID + logs entrée/sortie |
| [`diagnostics.tf`](./diagnostics.tf) | Snapshot — Diagnostic Settings Terraform (App Service, SQL, Redis → Log Analytics) |
| [`log-output-example.json`](./log-output-example.json) | Exemple de résultats d'une requête KQL sur Log Analytics |

## Étape suivante

Les logs permettent de savoir **ce qui s'est passé**. Le [Tracing Distribué](../02-distributed-tracing/README_FR.md) permet de comprendre **pourquoi et où** en suivant le chemin exact d'une requête à travers tous les services.
