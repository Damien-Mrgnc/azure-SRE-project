# 🗺️ Plan de route : Projet 3 — SRE Engineer

Ce document définit les étapes clés pour implémenter la couche SRE (Site Reliability Engineering) sur l'infrastructure et l'application existantes (issues du projet DevSecOps).

L'objectif est de structurer le projet en plusieurs phases distinctes, avec une documentation et une sauvegarde ("snapshot") de chaque phase dans des dossiers séparés, exactement comme pour le Projet 2.

## 📁 Plan de l'arborescence finale visée

Tout au long du projet, nous allons créer des dossiers pour "sauvegarder" chaque grande avancée :

```text
Projet3-SRE/
├── .github/                       # Workflows CI/CD existants et nouveaux (tests charge, chaos)
├── app/                           # L'application instrumentée (métriques, logs, traces)
├── terraform/                     # L'infrastructure + stack SRE (Prometheus, Grafana, etc.)
├── phase-0-initialisation/        # Backup de l'état de départ
├── phase-1-monitoring/            # Sauvegarde: Prometheus, Grafana, Métriques custom
├── phase-2-logs-tracing/          # Sauvegarde: Centralisation Logs + Jaeger/Tempo
├── phase-3-autoscaling/           # Sauvegarde: Règles d'autoscaling et résilience
├── phase-4-alerting-slo/          # Sauvegarde: Alertes, SLI, SLO, Error Budgets
├── phase-5-chaos-engineering/     # Sauvegarde: Scripts et tests de chaos
├── .gitignore                     # Fichier d'exclusion
├── PLAN.md                        # Ce fichier
├── README.md                      # Documentation globale
└── sonar-project.properties       # Propriétés SonarCloud
```

---

## 🛡️ Plan du `.gitignore`

Il est important de bien ignorer les bons fichiers (secrets, fichiers de build, plugins Terraform locaux). Le fichier devrait ignorer :

- **Terraform** : `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `.terraform.tfstate.lock.info`
- **Application (Node/Python/etc.)** : `node_modules/`, `__pycache__/`, dossiers `dist/`, `build/`
- **Environnement & Secrets** : `.env`, `*.pem`, `secrets/`
- **IDE** : `.vscode/`, `.idea/`, `*.swp`
- **SRE (Local)** : Bases de données locales de Prometheus/Grafana si lancés en local (`data/`, `prometheus_data/`)

---

## 🚀 Les Phases du Projet

Voici le déroulé pas-à-pas, inspiré de la `roadmap_projets.md`.

### Phase 0 : Initialisation et Préparation
🟡 **Difficulté : Facile**
- Initialiser le dépôt Git (ou le faire hériter du monorepo).
- Créer le `.gitignore` adapté aux outils SRE.
- Copier l'infrastructure Terraform et l'application du Projet 2 (Fait ✅).
- S'assurer que le pipeline CI/CD pré-existant déploie bien l'application sur l'infrastructure.
- *Livrable : Dossier `phase-0-initialisation` créé, et README.md initialisé.*

### Phase 1 : Observabilité (Monitoring & Métriques)
🟠 **Difficulté : Moyenne**
- **Côté App** : Instrumenter le code de `app/` pour exposer des "Custom Metrics" (nombre de requêtes, temps de traitement, compteurs d'erreurs).
- **Côté Infra** : Mettre à jour les fichiers Terraform pour y inclure/déployer un système de monitoring (Azure Monitor, ou déploiement d'un conteneur Prometheus).
- **Côté Visualisation** : Déployer Grafana et le connecter aux métriques (Azure Monitor ou Prometheus).
- Construire un premier Dashboard de santé de l'application.
- *Livrable : Dossier `phase-1-monitoring`.*

### Phase 2 : Logs et Tracing Distribué
🔴 **Difficulté : Difficile**
- **Côté Logs** : Centraliser les logs de l'application et de l'infrastructure (Log Analytics Azure ou stack Loki/ELK).
- **Côté Tracing** : Implémenter le tracing distribué (par ex. OpenTelemetry ou Application Insights) dans le code pour suivre le trajet d'une requête de bout en bout.
- Configurer les vues Grafana ou le portail Azure pour croiser Traces / Logs / Metrics.
- *Livrable : Dossier `phase-2-logs-tracing`.*

### Phase 3 : Fiabilité & Autoscaling
🟠 **Difficulté : Moyenne**
- Configurer des règles d'autoscaling (ex: via Virtual Machine Scale Sets VMSS ou Azure App Service Autoscaling).
- Lier le déclenchement de ce scaling aux métriques récoltées en Phase 1 (ex: Scale-out si CPU > 75% ou requêtes/sec > 1000).
- Tester manuellement la charge pour voir l'infrastructure s'agrandir et se réduire.
- *Livrable : Dossier `phase-3-autoscaling`.*

### Phase 4 : SLO, SLI et Alerting
🟠 **Difficulté : Moyenne**
- Définir des SLI (Service Level Indicators) : ex. 99% des requêtes en moins de 200ms.
- Définir des SLO (Service Level Objectives) pertinents (Error Budgets associées).
- Configurer et tester des alertes critiques (CPU élevé, Endpoint inaccessible - 50x) pour envoyer une notification (Slack / Discord / Email).
- *Livrable : Dossier `phase-4-alerting-slo`, incluant le document de définition des SLO.*

### Phase 5 : Chaos Engineering & Post-mortem
🔴 **Difficulté : Difficile**
- Écrire des scripts ou utiliser un outil (ex: Azure Chaos Studio ou scripts persos) pour :
  - Tuer volontairement une instance applicative ou un pod.
  - Injecter de la latence réseau artificielle.
  - Surcharger le CPU / Mémoire d'une VM.
- Analyser comment l'infrastructure réagit (est-ce que l'alerte de Phase 4 sonne ? est-ce que l'autoscaling de Phase 3 marche ?).
- Rédiger un "Post-mortem" (rapport d'incident) simulant une vraie panne.
- *Livrable : Dossier `phase-5-chaos-engineering`.*
