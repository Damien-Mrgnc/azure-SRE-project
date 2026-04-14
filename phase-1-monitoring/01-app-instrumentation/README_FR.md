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

## Fichiers Clés (Snapshot Phase 1)

| Fichier | Description |
|---|---|
| [`server.js`](./server.js) | Snapshot du code source instrumenté |
| [`metrics-output-example.txt`](./metrics-output-example.txt) | Sortie simulée de l'endpoint `/metrics` en production |

> Les fichiers source en production se trouvent dans [`app/src/server.js`](../../../app/src/server.js).

## Exemple de sortie `/metrics`

Extrait des métriques custom (voir [`metrics-output-example.txt`](./metrics-output-example.txt) pour la sortie complète) :

```
# HELP http_request_duration_ms Duration of HTTP requests in ms
# TYPE http_request_duration_ms histogram
http_request_duration_ms_bucket{le="10",method="GET",route="/",code="200"} 45
http_request_duration_ms_bucket{le="50",method="GET",route="/",code="200"} 88
http_request_duration_ms_count{method="GET",route="/",code="200"} 100

# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/",code="200"} 100
http_requests_total{method="GET",route="/api/config",code="401"} 5
```

## Résultat
L'application expose un endpoint `/metrics` complet au format Prometheus, prêt à être consommé par Azure Monitor ou tout collecteur compatible. Les 4 Golden Signals sont couverts côté applicatif.
