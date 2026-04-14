# Étape 1 : Définitions SLI / SLO / Error Budget

*Read the [English Version](README.md) here.*

## Objectif

Formaliser les **engagements de fiabilité** du service sous forme de SLI, SLO et Error Budgets. Ces définitions sont la boussole de l'équipe SRE : elles dictent quand agir, quand déployer, et quand geler les changements.

## Les 4 SLO définis

### SLO 1 — Disponibilité ≥ 99.9%
- **SLI** : `(requêtes non-5xx / requêtes totales) × 100`
- **Error Budget** : 43 minutes d'indisponibilité par mois
- **Source** : Azure Monitor (`Http5xx` / `Requests`)

### SLO 2 — Latence p95 < 500ms
- **SLI** : Percentile 95 du temps de réponse HTTP
- **Error Budget** : 5% des requêtes peuvent dépasser 500ms
- **Source** : Prometheus `http_request_duration_ms`

### SLO 3 — Taux d'erreurs < 1%
- **SLI** : `(requêtes 4xx + 5xx) / total × 100`
- **Error Budget** : 1% de requêtes en erreur tolérées
- **Source** : Prometheus `http_requests_total{code=~"4..|5.."}`

### SLO 4 — CPU < 80% (Saturation)
- **SLI** : CPU% moyen sur fenêtre 5 min
- **Action** : Autoscaling à 75% (Phase 3) agit avant ce seuil
- **Source** : Azure Monitor `CpuPercentage`

## Règle opérationnelle Error Budget

| Budget restant | Politique |
|---|---|
| > 50% | Déploiements normaux autorisés |
| 10 – 50% | Déploiements avec feature flags uniquement |
| < 10% | **Gel des déploiements** — focus fiabilité |

## Fichiers de cette étape

| Fichier | Description |
|---|---|
| [`slo-definitions.md`](./slo-definitions.md) | Document complet SLI/SLO/Error Budget avec requêtes KQL |
