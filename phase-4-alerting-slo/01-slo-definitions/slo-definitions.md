# Définitions SLI / SLO / Error Budget
# Runtime Governance App — Projet 3 SRE

**Date de définition :** 2026-04-13
**Révision :** v1.0
**Propriétaire :** Équipe SRE

---

## Concepts clés

| Terme | Définition |
|---|---|
| **SLI** (Service Level Indicator) | La métrique brute mesurée (ex : p99 de latence) |
| **SLO** (Service Level Objective) | L'objectif cible sur le SLI (ex : p99 < 1s sur 30 jours) |
| **SLA** (Service Level Agreement) | L'engagement contractuel externe (sous-ensemble du SLO) |
| **Error Budget** | La tolérance à l'échec = 100% - SLO. Budget consommable pour déployer, tester, etc. |

---

## SLO 1 — Disponibilité (Availability)

**Description :** Proportion des requêtes HTTP ayant reçu une réponse non-5xx.

| Champ | Valeur |
|---|---|
| **SLI** | `(requêtes_totales - requêtes_5xx) / requêtes_totales × 100` |
| **Source** | Azure Monitor — métrique `Http5xx` / `Requests` sur `Microsoft.Web/sites` |
| **Fenêtre** | Glissante sur 30 jours |
| **SLO** | **≥ 99.9%** de requêtes non-5xx |
| **Error Budget** | **0.1%** = ~43 minutes d'indisponibilité par mois |
| **Alerte** | Si error budget consommé à > 50% sur 7 jours → Warning |
| **Alerte critique** | Si error budget consommé à > 90% sur 7 jours → Page on-call |

**Requête KQL (Log Analytics) :**
```kusto
AppServiceHTTPLogs
| where TimeGenerated > ago(30d)
| summarize
    total = count(),
    errors5xx = countif(ScStatus >= 500)
| extend availability_pct = (1.0 - (toreal(errors5xx) / toreal(total))) * 100
| project availability_pct, error_budget_remaining_pct = availability_pct - 99.9
```

---

## SLO 2 — Latence (Latency)

**Description :** 95% des requêtes doivent être traitées en moins de 500ms.

| Champ | Valeur |
|---|---|
| **SLI** | Percentile 95 du temps de réponse HTTP |
| **Source** | Prometheus — `http_request_duration_ms` (Histogram) via `/metrics` |
| **Fenêtre** | Glissante sur 30 jours |
| **SLO** | **p95 < 500 ms** et **p99 < 1000 ms** |
| **Error Budget** | 5% des requêtes peuvent dépasser 500ms |
| **Alerte** | Si p99 > 800ms pendant 5 min → Warning |
| **Alerte critique** | Si p95 > 500ms pendant 10 min → Page on-call |

**Requête KQL :**
```kusto
AppServiceHTTPLogs
| where TimeGenerated > ago(30d)
| summarize
    p50 = percentile(TimeTaken, 50),
    p95 = percentile(TimeTaken, 95),
    p99 = percentile(TimeTaken, 99)
| extend slo_p95_met = p95 < 500, slo_p99_met = p99 < 1000
```

---

## SLO 3 — Taux d'erreurs (Error Rate)

**Description :** Moins de 1% des requêtes doivent retourner une erreur (4xx ou 5xx).

| Champ | Valeur |
|---|---|
| **SLI** | `(requêtes_4xx + requêtes_5xx) / requêtes_totales × 100` |
| **Source** | Prometheus — `http_requests_total{code=~"4..|5.."}` |
| **Fenêtre** | Glissante sur 7 jours |
| **SLO** | **< 1%** de requêtes en erreur |
| **Error Budget** | 1% = ~100 requêtes sur 10 000 peuvent être en erreur |
| **Alerte** | Si taux d'erreurs > 0.5% sur 10 min → Warning |
| **Alerte critique** | Si taux d'erreurs > 1% sur 5 min → Page on-call |

---

## SLO 4 — Saturation (Saturation)

**Description :** Les ressources ne doivent pas être saturées au point d'impacter le service.

| Champ | Valeur |
|---|---|
| **SLI** | % CPU moyen de l'App Service Plan |
| **Source** | Azure Monitor — `CpuPercentage` sur `Microsoft.Web/serverfarms` |
| **Fenêtre** | Fenêtre glissante 5 min |
| **SLO** | CPU moyen **< 80%** sur toute fenêtre de 5 min |
| **Action** | Autoscaling à 75% (Phase 3) — agit avant que le SLO soit atteint |
| **Alerte** | Si CPU > 80% et autoscaling au max → Page on-call |

---

## Calcul de l'Error Budget — Exemple mensuel

```
SLO Disponibilité : 99.9%
Durée mois        : 30 jours = 43 200 minutes
Error Budget       : 0.1% × 43 200 = 43.2 minutes d'indisponibilité tolérées

--- Consommation ce mois ---
Incident 1 (2026-04-05) : 8 minutes (SQL timeout)
Incident 2 (2026-04-11) : 3 minutes (deploy rollback)
Total consommé           : 11 minutes
Budget restant           : 32.2 minutes (74.5% restant)
Statut                   : VERT ✅ — déploiements autorisés
```

**Règle opérationnelle :**
- Budget > 50% restant → Déploiements normaux autorisés
- Budget 10–50% restant → Déploiements avec feature flags uniquement
- Budget < 10% restant → Gel des déploiements, focus fiabilité

---

## Tableau récapitulatif

| SLO | Indicateur | Objectif | Error Budget | Alerte Warning | Alerte Critique |
|---|---|---|---|---|---|
| Disponibilité | HTTP non-5xx | ≥ 99.9% | 43 min/mois | Budget > 50% consommé (7j) | Budget > 90% consommé (7j) |
| Latence p95 | Temps de réponse p95 | < 500 ms | 5% requêtes | p99 > 800ms / 5min | p95 > 500ms / 10min |
| Taux d'erreurs | HTTP 4xx+5xx | < 1% | 1% requêtes | > 0.5% / 10min | > 1% / 5min |
| Saturation CPU | CPU% App Service | < 80% | N/A | — | CPU > 80% + autoscale max |
