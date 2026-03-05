# SRE Enterprise Cloud Project (Azure & GitHub Actions)

Welcome to the reliability and observability project (Project 3 - SRE). This repository aims to implement the SRE (Site Reliability Engineering) layer on top of an existing infrastructure and application (from the previous DevSecOps project).

The goal is to add advanced capabilities for monitoring, log centralization, tracing, autoscaling, SLO/SLI management, and chaos engineering to ensure maximum resilience.

*Read the [French Version (Version Française)](README_FR.md) here.*

## Project Phases
This project is deeply documented and structured logically into progressive phases:

### [Phase 0: Initialization and Preparation](./phase-0-initialisation/README.md)
Initialization of the SRE repository, setup and verification of the existing CI/CD (DevSecOps) and the OIDC connection with Azure. Preparing the groundwork for SRE components.

### [Phase 1: Observability (Monitoring & Metrics)](./phase-1-monitoring/README.md)
Application instrumentation with Prometheus (`prom-client`), deployment of the Azure monitoring stack (Log Analytics, Application Insights, Monitor Workspace, Managed Grafana v11), and creation of SRE dashboards based on the 4 Golden Signals.

### Phase 2: Logs and Distributed Tracing
*Upcoming section: Centralization of application and infrastructure logs, and implementation of distributed tracing (OpenTelemetry / Application Insights).*

### Phase 3: Reliability & Autoscaling
*Upcoming section: Configuration of autoscaling rules and linking with the metrics collected during phase 1.*

### Phase 4: SLO, SLI, and Alerting
*Upcoming section: Definition of SLIs, SLOs, and Error Budgets. Configuration and testing of critical alerts.*

### Phase 5: Chaos Engineering & Post-mortem
*Upcoming section: Resilience testing via fault injection (Chaos Studio), analysis of infrastructure behavior, and writing post-mortem reports.*

---
## SRE Technology Stack
- **Cloud Provider:** Microsoft Azure
- **Infrastructure as Code:** Terraform
- **Observability:** Prometheus, Grafana, OpenTelemetry, Azure Monitor (to be defined during the project)
- **Application:** Node.js, Docker
- **CI/CD:** GitHub Actions
