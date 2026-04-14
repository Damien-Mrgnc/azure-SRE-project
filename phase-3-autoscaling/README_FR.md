# Phase 3 : Fiabilité & Autoscaling

*Read the [English Version](README.md) here.*

## Objectif

Configurer l'**autoscaling horizontal** de l'App Service Plan et valider son comportement sous charge réelle via un test k6. L'autoscaling est lié aux métriques CPU collectées en Phase 1, formant une boucle de rétroaction complète : Observabilité → Action.

## Aperçu Structurel

1. [**Étape 1 : Règles d'Autoscaling (Terraform)**](./01-autoscaling-rules/README_FR.md)
2. [**Étape 2 : Test de Charge (k6)**](./02-load-testing/README_FR.md)

---

## La Boucle SRE complète

```
Phase 1 : Métriques CPU exposées (Prometheus + Azure Monitor)
       ↓
Phase 3 : Autoscaling déclenché par CPU > 75%
       ↓
Phase 4 : Alertes si CPU > 80% (SLO breach)
       ↓
Phase 5 : Chaos Engineering — valider que tout tient sous panne
```

## Contenu du Snapshot

| Chemin | Description |
|---|---|
| `01-autoscaling-rules/autoscaling.tf` | Règles Terraform : scale-out (+1 instance si CPU > 75% / 5min), scale-in (-1 si CPU < 25% / 10min) |
| `02-load-testing/load-test.js` | Script k6 — 20 min, 150 VUs max, 3 endpoints, seuils SLO |
| `02-load-testing/load-test-report.json` | Rapport simulé : 2 scale-out, 2 scale-in, tous les SLO respectés |

---

## Stack Technique

- **`azurerm_monitor_autoscale_setting`** : Ressource Terraform pour l'autoscaling App Service Plan
- **`CpuPercentage`** : Métrique Azure Monitor pilotant les règles de scaling
- **k6** : Outil de load testing (scénarios JS, métriques Prometheus, seuils SLO)
- **`/api/admin/stress`** : Route de chaos intégrée à l'app pour simuler une charge CPU

## Résultats Clés

| Métrique | Résultat | SLO |
|---|---|---|
| Latence p95 sous 150 VUs | **312 ms** | < 500 ms ✅ |
| Taux d'erreurs | **0.18%** | < 1% ✅ |
| Scale-out déclenché | **T+7min12s** | CPU 78% > 75% |
| Instances max atteintes | **3 instances** | max = 3 |

## Statut : Terminé ✅
