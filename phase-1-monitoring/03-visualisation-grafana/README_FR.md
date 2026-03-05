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

## Fichiers Clés
- `terraform/dashboards/webapp-health.json` — Définition JSON complète du dashboard (4 Golden Signals).
- `terraform/monitoring.tf` — Ressource `null_resource` pour le déploiement idempotent du dashboard.

## Résultat
Le dashboard est versionné avec le code, déployé automatiquement sur chaque `terraform apply`, et ne génère aucune action si le fichier JSON n'a pas changé. L'équipe SRE dispose d'une vue unifiée des 4 Golden Signals dès le déploiement.
