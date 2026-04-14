# 01 — Scripts de Chaos Engineering

Ce dossier contient les scripts utilisés pour les expériences de Chaos Engineering de la Phase 5.

## Fichiers

| Fichier | Type | Description |
|---|---|---|
| `chaos-cpu-stress.sh` | Bash | Injecte une charge CPU via des requêtes concurrentes vers `/api/admin/stress` |
| `chaos-kill-instance.sh` | Bash | Simule la mort d'une instance via `az webapp restart` avec probe de disponibilité |
| `chaos-latency-inject.js` | Node.js | Proxy HTTP injectant un délai artificiel avant de transférer les requêtes |
| `azure-chaos-experiment.json` | JSON | Définition d'expérience Azure Chaos Studio (CPU Pressure + Stop) |

---

## Expérience #1 — CPU Stress

**Script :** `chaos-cpu-stress.sh`

**Hypothèse :** L'autoscaling (Phase 3) absorbe la charge CPU avant que le SLO de disponibilité ne soit breché.

**Mécanisme :**
```bash
# Lancement de N workers concurrents vers /api/admin/stress
# Chaque requête simule 2000ms de traitement CPU intensif
CONCURRENCY=20
STRESS_DURATION=600  # 10 minutes
```

**Usage :**
```bash
chmod +x chaos-cpu-stress.sh
./chaos-cpu-stress.sh \
  --url https://app-projet3-sre.azurewebsites.net \
  --concurrency 20 \
  --duration 600
```

**Variables d'environnement :**
```bash
APP_URL=https://app-projet3-sre.azurewebsites.net
CONCURRENCY=20
DURATION=600
STRESS_MS=2000
```

**Ce qu'on observe :**
- CPU% dans Azure Monitor (App Service Plan)
- Déclenchement autoscaling (Scale-out 1→2→3 instances)
- Alerte `alert-asp-cpu-high` (Sev2)
- Alerte `slo-latency-breach` (Sev2, p99 > 800ms)
- Résultats dans `../02-chaos-results/chaos-run-report.json`

---

## Expérience #2 — Kill Instance

**Script :** `chaos-kill-instance.sh`

**Hypothèse :** Après un restart forcé, le health check Azure rétablit le service en < 2 min.

**Mécanisme :**
```bash
# az webapp restart → indisponibilité temporaire
# Probe HTTP toutes les 5s pour mesurer le downtime
az webapp restart --resource-group $RESOURCE_GROUP --name $APP_NAME
```

**Usage :**
```bash
chmod +x chaos-kill-instance.sh
APP_NAME=app-projet3-sre-abc123 \
RESOURCE_GROUP=rg-projet3-sre \
./chaos-kill-instance.sh
```

**Ce qu'on observe :**
- Premières erreurs 503/502 après le restart
- Alerte `alert-webapp-5xx` (Sev2, > 5 erreurs 5xx)
- Alerte `slo-availability-breach` (Sev1, error rate > 1%)
- Durée d'indisponibilité mesurée par le probe (SLO : < 120s)

---

## Expérience #3 — Injection de Latence

**Script :** `chaos-latency-inject.js`

**Hypothèse :** L'alerte `slo-latency-breach` se déclenche quand les dépendances externes sont lentes.

**Mécanisme :**
```
Client → Proxy local (port 8888) → [délai INJECTED_DELAY_MS] → dummyjson.com
```

**Usage :**
```bash
# Démarrer le proxy avec 2000ms de délai
node chaos-latency-inject.js 2000 8888

# Configurer l'app pour passer par le proxy
APP_EXTERNAL_API_URL=http://localhost:8888 node server.js
```

**Ce qu'on observe :**
- Application Insights → Performance → GET / (latence élevée)
- Log Analytics → `AppServiceHTTPLogs | where TimeTaken > 2000`
- Alerte `slo-latency-breach`

---

## Azure Chaos Studio

**Fichier :** `azure-chaos-experiment.json`

Définition d'expérience Azure Chaos Studio en 5 étapes :

| Étape | Action | Durée |
|---|---|---|
| 1 — Baseline | Attente (mesure baseline) | 2 min |
| 2 — CPU Pressure | `cpuPressure/1.0` à 80% | 5 min |
| 3 — Recovery Check | Attente observation récupération | 5 min |
| 4 — Stop & Restart | `stop/1.0` (arrêt App Service) | Discret |
| 5 — Auto-recovery | Attente observation auto-redémarrage | 3 min |

**Déploiement :**
```bash
az rest --method PUT \
  --url '/subscriptions/{subscriptionId}/resourceGroups/rg-projet3-sre/providers/Microsoft.Chaos/experiments/chaos-exp-sre-full' \
  --body @azure-chaos-experiment.json \
  --api-version 2023-11-01
```

**Pré-requis :**
```bash
# Donner les permissions Chaos Studio sur la ressource cible
az role assignment create \
  --role "Website Contributor" \
  --assignee-object-id <chaos-experiment-principal-id> \
  --scope /subscriptions/{sub}/resourceGroups/rg-projet3-sre/providers/Microsoft.Web/sites/app-projet3-sre-abc123
```

---

## Résultats

Les résultats détaillés des expériences #1 et #2 sont dans :
- [`../02-chaos-results/chaos-run-report.json`](../02-chaos-results/chaos-run-report.json) — rapport complet
- [`../02-chaos-results/metrics-during-chaos.json`](../02-chaos-results/metrics-during-chaos.json) — métriques minute par minute

Le post-mortem est dans :
- [`../03-postmortem/postmortem-incident-001.md`](../03-postmortem/postmortem-incident-001.md)
