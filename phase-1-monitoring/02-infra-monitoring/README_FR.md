# Étape 2 : Côté Infra — Déploiement de la Stack Monitoring

## Concept
L'instrumentation applicative ne sert à rien sans une infrastructure capable de **collecter, stocker et exposer** les données. Cette étape déploie via Terraform toute la stack d'observabilité Azure : Log Analytics, Application Insights, Azure Monitor Workspace et Managed Grafana, avec les rôles RBAC nécessaires.

## Détails d'Implémentation
L'ensemble des ressources de monitoring est défini dans `terraform/monitoring.tf` et déployé automatiquement via la CI/CD.

### Ressources Déployées
1. **Azure Log Analytics Workspace** : Stockage centralisé des logs avec rétention de 30 jours (SKU `PerGB2018`).
2. **Azure Application Insights** : APM connecté à Log Analytics pour le suivi des performances applicatives (type `web`).
3. **Azure Monitor Workspace** : Espace de travail pour les métriques Prometheus natives, s'intégrant directement à Managed Grafana.
4. **Azure Managed Grafana (v11, SKU Standard)** :
   - Identité Managée `SystemAssigned` pour l'accès sécurisé aux données.
   - Intégration native avec l'Azure Monitor Workspace.
   - Support des clés API activé (`api_key_enabled = true`) pour l'automatisation future.

### Configuration RBAC
1. **`Monitoring Reader`** : Attribué à l'Identité Managée de Grafana sur le Resource Group → permet la lecture des métriques et logs Azure Monitor.
2. **`Grafana Admin`** : Attribué au principal déployant (Service Principal CI/CD) → permet la gestion des dashboards et des sources de données.

### Corrections de Compatibilité (azurerm v4)
Le provider `azurerm` a été mis à jour de `~> 3.90.0` à `~> 4.0` pour supporter Grafana v11. Les breaking changes corrigés :
- `health_check_eviction_time_in_min` ajouté à l'App Service (`compute.tf`).
- `DOCKER_REGISTRY_SERVER_URL` supprimé des `app_settings` (géré nativement par `site_config`).
- `enable_non_ssl_port` remplacé par `non_ssl_port_enabled` dans Redis (`redis.tf`).
- Enregistrement du resource provider `Microsoft.Dashboard` sur la souscription.
- Attribution du rôle `Role Based Access Control Administrator` au Service Principal CI.

## Fichiers Clés
- `terraform/monitoring.tf` — Définition complète de la stack monitoring (Log Analytics, App Insights, Monitor Workspace, Grafana, RBAC).
- `terraform/providers.tf` — Mise à jour du provider azurerm (`~> 4.0`).
- `terraform/compute.tf` — Corrections de compatibilité App Service.
- `terraform/redis.tf` — Correction de la dépréciation Redis.

## Résultat
L'infrastructure d'observabilité est entièrement déployée et gérée par Terraform. Grafana dispose des permissions nécessaires pour lire toutes les données Azure Monitor du Resource Group. La CI/CD peut gérer les dashboards de manière autonome.
