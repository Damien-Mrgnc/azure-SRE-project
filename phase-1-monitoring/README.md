# Phase 1: Observability (Monitoring & Metrics)

*Read the [French Version (Version Française)](README_FR.md) here.*

## Objective
Implement the first pillar of SRE: **Observability**. Instrument the application to expose custom metrics, deploy a complete monitoring stack (Azure Monitor + Managed Grafana) via Terraform, and build a health dashboard based on the **4 Golden Signals** (Traffic, Errors, Latency, Saturation).

## Structural Overview
This phase covers the full observability chain, from application code to visualization dashboards.

1. [**Step 1: App Side — Prometheus Instrumentation**](./01-app-instrumentation/README.md)
2. [**Step 2: Infra Side — Monitoring Stack Deployment**](./02-infra-monitoring/README.md)
3. [**Step 3: Visualization Side — Grafana as Code**](./03-visualisation-grafana/README.md)

---

## Snapshot Contents

This folder is a **snapshot** of the Phase 1 deliverables. It contains the key files as they existed at the end of this phase.

| Path | Description |
|---|---|
| `01-app-instrumentation/server.js` | Instrumented Node.js app (prom-client, /metrics endpoint) |
| `01-app-instrumentation/metrics-output-example.txt` | Simulated Prometheus output from /metrics |
| `02-infra-monitoring/monitoring.tf` | Terraform — Grafana, Log Analytics, App Insights |
| `02-infra-monitoring/alerts.tf` | Terraform — Azure Monitor alert rules |
| `03-visualisation-grafana/dashboards/webapp-health.json` | Grafana dashboard JSON (4 Golden Signals) |

---

## Tech Stack
- **prom-client**: Prometheus client for Node.js — custom metrics exposure.
- **response-time**: Middleware for automatic response time capture.
- **Azure Log Analytics**: Centralized log storage.
- **Azure Application Insights**: APM (Application Performance Monitoring).
- **Azure Managed Grafana**: SRE visualization and dashboards (deployed via Docker on App Service).
- **Terraform (azurerm ~> 4.0)**: Infrastructure as Code for the entire stack.

## Status: Complete
