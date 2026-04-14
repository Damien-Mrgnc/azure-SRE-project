# SRE Enterprise Cloud Project (Azure & GitHub Actions)

Bienvenue dans le projet de fiabilisation et d'observabilité (Projet 3 - SRE). Ce dépôt vise à implémenter la couche SRE (Site Reliability Engineering) sur une infrastructure et une application existantes (issues du projet DevSecOps précédent).

L'objectif est d'ajouter des capacités avancées de monitoring, de centralisation des logs, de tracing, d'autoscaling, de gestion des SLO/SLI, et de chaos engineering pour garantir une résilience maximale.

*Read the [English Version](README.md) here.*

## Les Phases du Projet
Ce projet est structuré logiquement en plusieurs phases progressives :

### [Phase 0 : Initialisation et Préparation](./phase-0-initialisation/README_FR.md)
Initialisation du dépôt SRE, mise en place et vérification de la CI/CD existante (DevSecOps) et de la connexion OIDC avec Azure. Préparation du terrain pour les briques SRE.

### [Phase 1 : Observabilité (Monitoring & Métriques)](./phase-1-monitoring/README_FR.md)
Instrumentation de l'application avec Prometheus (`prom-client`), déploiement de la stack monitoring Azure (Log Analytics, Application Insights, Monitor Workspace, Managed Grafana v11) et création de dashboards SRE basés sur les 4 Golden Signals.

### Phase 2 : Logs et Tracing Distribué
*Section à venir : Centralisation des logs de l'application et de l'infrastructure, et implémentation du tracing distribué (OpenTelemetry / Application Insights).*

### Phase 3 : Fiabilité & Autoscaling
*Section à venir : Configuration des règles d'autoscaling et liaison avec les métriques récoltées lors de la phase 1.*

### Phase 4 : SLO, SLI et Alerting
*Section à venir : Définition des SLI, SLO et Error Budgets. Configuration et tests des alertes critiques.*

### Phase 5 : Chaos Engineering & Post-mortem
*Section à venir : Tests de résilience via l'injection de pannes (Chaos Studio), analyse du comportement de l'infrastructure et rédaction de rapports post-mortem.*

---
## Stack Technologique SRE
- **Cloud Provider :** Microsoft Azure
- **Infrastructure as Code :** Terraform
- **Observabilité :** Prometheus, Grafana, OpenTelemetry, Azure Monitor (à définir en cours de projet)
- **Application :** Node.js, Docker
- **CI/CD :** GitHub Actions
