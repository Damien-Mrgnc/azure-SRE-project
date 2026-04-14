# Étape 3 : Côté Visualisation — Grafana as Code

## Concept
Avoir des métriques et une stack de monitoring ne suffit pas : il faut des **dashboards exploitables** pour transformer les données brutes en décisions opérationnelles. L'approche "Grafana as Code" garantit que les dashboards sont versionnés, reproductibles et déployés de manière idempotente via la CI/CD.

## Détails d'Implémentation
Un dashboard JSON est stocké dans le dépôt et déployé automatiquement sur Azure Managed Grafana via un `null_resource` Terraform utilisant Azure CLI.

### Dashboard "Application Health (SRE)" — 4 Golden Signals
Le dashboard suit la méthodologie des **4 Golden Signals** de Google SRE :

1. **Trafic** : Total des requêtes HTTP dans le temps (panneau Time Series) — permet de détecter les pics et les creux de charge.
2. **Erreurs** : 
   - Erreurs HTTP 4xx (panneau Stat) — erreurs client.
   - Erreurs HTTP 5xx (panneau Time Series) — erreurs serveur critiques.
3. **Latence** : Temps de réponse moyen dans le temps (panneau Time Series, unité : secondes) — détecte les dégradations de performance.
4. **Saturation** :
   - CPU Time (panneau Gauge) — charge processeur de l'App Service.
   - Memory Working Set (panneau Gauge, unité : bytes) — consommation mémoire.

### Déploiement Idempotent
- **Mécanisme** : `null_resource` avec provisioner `local-exec` exécutant `az grafana dashboard create --overwrite true`.
- **Trigger** : Basé sur le MD5 du fichier JSON (`filemd5()`). Le dashboard n'est redéployé que lorsque sa définition change.
- **Dépendance** : Le déploiement attend que le rôle `Grafana Admin` soit attribué (`depends_on`).

### Commande Azure CLI
```bash
az extension add -n amg --upgrade && \
az grafana dashboard create \
  --name <grafana-instance> \
  --resource-group <rg> \
  --definition @terraform/dashboards/webapp-health.json \
  --overwrite true
```

## Fichiers Clés (Snapshot Phase 1)

| Fichier | Description |
|---|---|
| [`dashboards/webapp-health.json`](./dashboards/webapp-health.json) | Snapshot — Définition JSON complète du dashboard (4 Golden Signals) |

> Le fichier source en production se trouve dans [`terraform/dashboards/webapp-health.json`](../../../terraform/dashboards/webapp-health.json).
> Le provisionnement Terraform est dans [`02-infra-monitoring/monitoring.tf`](../02-infra-monitoring/monitoring.tf) (`null_resource.grafana_dashboard_webapp`).

### Panneaux du Dashboard

| Panneau | Type | Signal | Métrique Azure Monitor |
|---|---|---|---|
| Total Traffic (Requêtes) | Time Series | Trafic | `Requests` |
| Erreurs Client (400) | Stat | Erreurs | `Http4xx` |
| Erreurs Serveur (500) | Time Series | Erreurs | `Http 5xx` |
| Temps de Réponse Moyen | Time Series | Latence | `Average Response Time` |
| Saturation CPU | Gauge | Saturation | `CpuTime` |
| Utilisation Mémoire | Gauge | Saturation | `MemoryWorkingSet` |

### Déploiement via API REST Grafana

Le dashboard est poussé automatiquement via l'API REST de Grafana après que Terraform ait démarré le conteneur :

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -u "admin:<password>" \
  -d '{"dashboard": <json>, "overwrite": true, "folderId": 0}' \
  https://<grafana-host>/api/dashboards/db
```

## Résultat
Le dashboard est versionné avec le code et déployé automatiquement. L'équipe SRE dispose d'une vue unifiée des 4 Golden Signals dès le premier déploiement.
