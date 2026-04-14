# Phase 2: Logs and Distributed Tracing

*Lire la [Version Française](README_FR.md) ici.*

## Objective

Implement the second pillar of SRE observability: **Logs + Traces**. Centralize application and infrastructure logs in Azure Log Analytics, and instrument the code with OpenTelemetry to track every request end-to-end across all services.

## Structural Overview

1. [**Step 1: Log Centralization**](./01-logs-centralisation/README.md)
2. [**Step 2: Distributed Tracing (OpenTelemetry)**](./02-distributed-tracing/README.md)

---

## The 3 Pillars of Observability

This phase completes the SRE observability triangle:

| Pillar | Tool | Phase |
|---|---|---|
| **Metrics** | Prometheus + Grafana | Phase 1 ✅ |
| **Logs** | Winston + Log Analytics | Phase 2 ✅ |
| **Traces** | OpenTelemetry + Application Insights | Phase 2 ✅ |

## Snapshot Contents

| Path | Description |
|---|---|
| `01-logs-centralisation/logger.js` | Winston configuration (structured JSON → stdout) |
| `01-logs-centralisation/requestLogger.js` | Correlation ID middleware |
| `01-logs-centralisation/diagnostics.tf` | Terraform — Azure log forwarding to Log Analytics |
| `01-logs-centralisation/log-output-example.json` | Example KQL query results from Log Analytics |
| `02-distributed-tracing/tracing.js` | OTel SDK initialization + Azure Monitor Exporter |
| `02-distributed-tracing/server.js` | server.js with tracing as first import |
| `02-distributed-tracing/trace-output-example.json` | Trace examples (3 scenarios: cache hit, cache miss, SQL error) |

---

## Tech Stack

- **winston**: Structured JSON logger → stdout → captured by Azure App Service
- **Correlation ID**: UUID propagated through all logs for a single request
- **OpenTelemetry SDK** (`@opentelemetry/sdk-node`): Standard tracing framework
- **Auto-instrumentations**: HTTP, Express, Prisma (SQL), Redis — no business code changes needed
- **Azure Monitor Exporter** (`@azure/monitor-opentelemetry-exporter`): Exports traces to Application Insights
- **Terraform Diagnostic Settings**: Automatic log forwarding from App Service / SQL / Redis to Log Analytics
- **KQL**: Query language to interrogate logs in Log Analytics

## Status: Complete ✅
