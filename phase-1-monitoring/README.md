# Phase 1: Observability (Monitoring & Metrics)

*Read the [French Version (Version Française)](README_FR.md) here.*

## Objective
Implement the first pillar of SRE: **Observability**. Instrument the application to expose custom metrics, deploy a complete monitoring stack (Azure Monitor + Managed Grafana) via Terraform, and build a health dashboard based on the **4 Golden Signals** (Traffic, Errors, Latency, Saturation).

## Structural Overview
This phase covers the full observability chain, from application code to visualization dashboards.

1. [**Step 1: App Side — Prometheus Instrumentation**](./01-app-instrumentation/README.md) *
2. [**Step 2: Infra Side — Monitoring Stack Deployment**](./02-infra-monitoring/README.md) *
3. [**Step 3: Visualization Side — Grafana as Code**](./03-visualisation-grafana/README.md) *

---

## Tech Stack
- **prom-client**: Prometheus client for Node.js — custom metrics exposure.
- **response-time**: Middleware for automatic response time capture.
- **Azure Log Analytics**: Centralized log storage.
- **Azure Application Insights**: APM (Application Performance Monitoring).
- **Azure Monitor Workspace**: Native Prometheus metrics integration.
- **Azure Managed Grafana (v11)**: SRE visualization and dashboards.
- **Terraform (azurerm ~> 4.0)**: Infrastructure as Code for the entire stack.
