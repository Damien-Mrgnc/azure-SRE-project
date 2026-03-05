# Étape 1 : Côté App — Instrumentation Prometheus

## Concept
Pour rendre un système observable, il faut d'abord que l'application **émette des signaux**. Sans métriques exposées par le code, aucun outil externe ne peut mesurer la santé réelle de l'application. L'instrumentation Prometheus transforme l'application en une source de données structurée pour le monitoring SRE.

## Détails d'Implémentation
L'application Node.js (Express) a été instrumentée avec la librairie `prom-client` pour exposer des métriques au format Prometheus sur un endpoint dédié.

### Métriques Custom Implémentées
1. **`http_request_duration_ms` (Histogram)** : Mesure la durée de chaque requête HTTP en millisecondes. Utilise des buckets prédéfinis (`10, 50, 100, 200, 500, 1000, 2000, 5000`) pour catégoriser les temps de réponse et calculer les percentiles (p50, p95, p99).
2. **`http_requests_total` (Counter)** : Compteur cumulatif du nombre total de requêtes HTTP. Ventilé par labels `method`, `route` et `code` pour permettre le filtrage fin (ex : taux d'erreurs 5xx par route).
3. **Métriques par défaut Node.js** : `collectDefaultMetrics()` expose automatiquement les métriques runtime (heap, event loop, GC, etc.).

### Middleware `response-time`
Le middleware `response-time` intercepte toutes les requêtes et alimente les métriques Prometheus avec le temps de réponse réel. La route `/metrics` est exclue du tracking pour éviter la pollution des données.

### Endpoint `/metrics`
- **Route** : `GET /metrics`
- **Format** : `text/plain` au format Prometheus (compatible scraping).
- **Accès** : Public (non protégé par l'auth) pour permettre le scraping par les collecteurs.

## Fichiers Clés
- `app/src/server.js` — Instrumentation Prometheus, déclaration des métriques, middleware et endpoint `/metrics`.

## Résultat
L'application expose désormais un endpoint `/metrics` complet, prêt à être consommé par Azure Monitor, Prometheus ou tout collecteur compatible. Les 4 Golden Signals sont couverts côté applicatif.
