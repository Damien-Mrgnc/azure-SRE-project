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
🟡 **Difficulté : Facile** — ✅ **TERMINÉ**
- Initialiser le dépôt Git (ou le faire hériter du monorepo).
- Créer le `.gitignore` adapté aux outils SRE.
- Copier l'infrastructure Terraform et l'application du Projet 2.
- S'assurer que le pipeline CI/CD pré-existant déploie bien l'application sur l'infrastructure.
- *Livrable : Dossier `phase-0-initialisation` créé, et README.md initialisé.*

### Phase 1 : Observabilité (Monitoring & Métriques)
🟠 **Difficulté : Moyenne** — ✅ **TERMINÉ**
- **Côté App** ✅ : Instrumentation Prometheus (`prom-client`) — métriques `http_request_duration_ms` (Histogram) et `http_requests_total` (Counter), endpoint `/metrics`.
- **Côté Infra** ✅ : Stack monitoring Terraform — Log Analytics Workspace, Application Insights, Grafana sur App Service (Docker).
- **Côté Visualisation** ✅ : Dashboard "Application Health (SRE)" couvrant les 4 Golden Signals (Trafic, Erreurs, Latence, Saturation). Déploiement via API REST Grafana.
- **Alerting** ✅ : Alertes Azure Monitor — CPU > 80%, HTTP 5xx > 5, stockage SQL > 90%.
- *Livrable : Dossier `phase-1-monitoring` avec snapshot complet.*

### Phase 2 : Logs et Tracing Distribué
🔴 **Difficulté : Difficile** — ✅ **TERMINÉ**
- **Côté Logs** ✅ : Winston JSON structuré → stdout → App Service → Log Analytics via Diagnostic Settings Terraform. Correlation ID propagé sur chaque requête.
- **Côté Tracing** ✅ : OpenTelemetry SDK (`@opentelemetry/sdk-node`) avec auto-instrumentation HTTP/Express/Prisma/Redis. Export vers Application Insights via `@azure/monitor-opentelemetry-exporter`.
- **Corrélation** ✅ : Logs + Traces + Metrics croisés via `traceId` / `correlationId` dans Application Insights.
- *Livrable : Dossier `phase-2-logs-tracing` avec snapshot complet.*

### Phase 3 : Fiabilité & Autoscaling
🟠 **Difficulté : Moyenne** — ✅ **TERMINÉ**
- **Autoscaling** ✅ : `azurerm_monitor_autoscale_setting` Terraform — scale-out si CPU > 75% / 5min (+1 instance, max 3), scale-in si CPU < 25% / 10min. Variable `autoscale_max_instances` ajoutée.
- **Load Testing** ✅ : Script k6 — 20 min, 150 VUs max, 6 étapes (rampe → pic → descente), seuils SLO embarqués (p95 < 500ms, erreurs < 1%).
- **Rapport simulé** ✅ : 2 scale-out (T+7min, T+12min), 2 scale-in (T+26min, T+36min). SLO latence et erreurs respectés.
- *Livrable : Dossier `phase-3-autoscaling` avec snapshot complet.*

### Phase 4 : SLO, SLI et Alerting
🟠 **Difficulté : Moyenne** — ✅ **TERMINÉ**
- **SLO définis** ✅ : 4 SLO formalisés — Disponibilité (≥ 99.9%), Latence p95 (< 500ms), Taux d'erreurs (< 1%), CPU (< 80%). Error Budget calculé + politique opérationnelle (gel/déploiement).
- **Alertes SLO** ✅ : `azurerm_monitor_scheduled_query_rules_alert_v2` — alerte KQL si taux 5xx > 1% (Sev1) et si p99 > 800ms (Sev2).
- **Notifications** ✅ : Common Alert Schema — exemples de payloads pour 4 scénarios (breach, warning, infra, résolution).
- *Livrable : Dossier `phase-4-alerting-slo` avec snapshot complet.*

### Phase 5 : Chaos Engineering & Post-mortem
🔴 **Difficulté : Difficile** — ✅ **TERMINÉ**
- **Scripts de chaos** ✅ : 3 scripts d'injection — `chaos-cpu-stress.sh` (20 workers concurrents vers `/api/admin/stress`), `chaos-kill-instance.sh` (`az webapp restart` + probe de disponibilité), `chaos-latency-inject.js` (proxy Node.js avec délai artificiel).
- **Azure Chaos Studio** ✅ : Définition d'expérience JSON (`azure-chaos-experiment.json`) — 5 étapes : baseline, CPU pressure 80% / 5min, recovery, stop, auto-recovery observation.
- **Résultats simulés** ✅ : `chaos-run-report.json` (rapport complet : 2 expériences, CPU peak 87%, 2 scale-outs, kill 94s downtime, 4 alertes correctes, error budget 13.6% consommé) + `metrics-during-chaos.json` (timeline minute par minute : CPU%, HTTP 2xx/4xx/5xx, latence p50/p95/p99, mémoire).
- **Post-mortem Google SRE** ✅ : `postmortem-incident-001.md` — timeline détaillée, analyse 5 Whys (3 causes racines), ce qui a fonctionné/pas fonctionné, 9 action items (P1/P2/P3), error budget impact, leçons apprises.
- **Documentation** ✅ : READMEs FR/EN pour chaque sous-dossier et la phase entière.
- *Livrable : Dossier `phase-5-chaos-engineering` complet.*
