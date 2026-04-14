# 02 — Résultats du Chaos Run

Ce dossier contient les résultats détaillés des expériences de Chaos Engineering exécutées le 2026-04-13.

## Fichiers

| Fichier | Description |
|---|---|
| `chaos-run-report.json` | Rapport complet du run — 2 expériences, alertes, SLO, autoscaling events |
| `metrics-during-chaos.json` | Timeline minute par minute — CPU%, requêtes HTTP, latences, mémoire |

---

## Résumé du Run

**Date :** 2026-04-13
**Durée totale :** 25 minutes
**Expériences exécutées :** 2
**Verdict global :** PASS — système résilient, alertes correctes, récupération automatique confirmée

---

## Expérience #1 — CPU Stress (10:00 → 10:10)

**Résultats clés :**

| Métrique | Valeur |
|---|---|
| CPU Peak | 87% |
| CPU moyen pendant le chaos | 79% |
| Instances peak | 3 (scale-out ×2) |
| Requêtes envoyées | 1840 |
| Erreurs HTTP | 13 (error rate 0.71%) |
| Latence p95 pendant chaos | 2241ms |
| Latence p99 peak | 2318ms |

**Alertes déclenchées :**

| Alerte | Fired | Sévérité | Resolved |
|---|---|---|---|
| `slo-latency-breach` | 10:03:42 | Sev2 | 10:10:12 |
| `alert-asp-cpu-high` | 10:05:18 | Sev2 | 10:11:45 |

**Autoscaling :**

| Heure | Événement | Trigger |
|---|---|---|
| 10:05:12 | Scale-out 1 → 2 | CPU 76% > 75% |
| 10:06:30 | Scale-out 2 → 3 | CPU 81% > 75% |
| 10:14:55 | Scale-in 3 → 2 | CPU 19% < 25% |
| 10:25:10 | Scale-in 2 → 1 | CPU 12% < 25% |

**SLO :**

| SLO | Cible | Réel | Verdict |
|---|---|---|---|
| Disponibilité | 99.9% | 99.29% | BREACH (attendu) |
| Latence p95 | 500ms | 2241ms | BREACH (attendu) |
| Taux d'erreur | < 1% | 0.71% | PASS ✅ |

---

## Expérience #2 — Kill Instance (10:13 → 10:16)

**Résultats clés :**

| Métrique | Valeur |
|---|---|
| Méthode | `az webapp restart` |
| Première erreur 503 | T+8s (10:13:08) |
| Durée downtime | **94 secondes** |
| SLO recovery | < 120s (SLO target) ✅ |
| Erreurs 5xx | 8 |
| Error rate (5min) | 2.7% |

**Timeline probe HTTP :**

| Heure | Status |
|---|---|
| 10:13:05 | 200 (avant chaos) |
| 10:13:10 | 503 ← début downtime |
| 10:13:45 | 502 (transition) |
| 10:13:55 | 200 ← service partiel |
| 10:14:42 | 200 ← fully restored |

**Alertes déclenchées :**

| Alerte | Fired | Sévérité | Resolved |
|---|---|---|---|
| `alert-webapp-5xx` | 10:13:25 | Sev2 | 10:15:10 |
| `slo-availability-breach` | 10:13:30 | Sev1 | 10:15:10 |

---

## Impact Global sur l'Error Budget

| Métrique | Valeur |
|---|---|
| Budget mensuel | 43.2 minutes |
| Consommé ce jour | 5.87 minutes (13.6%) |
| Budget restant | 37.33 minutes (**86.4%**) |
| Politique | 🟢 VERT — déploiements normaux autorisés |

---

## Timeline CPU (Visualisation)

```
CPU%
 90 |         ████
 80 |       ████████
 70 |     ██████████   ←scale-out×2
 60 |   ████████████████
 50 |   ████████████████████
 40 |  ██████████████████████
 30 | ██████████████████████████
 20 |████████████████████████████████
 10 |████████████████████████████████████████████
    ├──────┬──────┬──────┬──────┬──────┬──────┬──
   09:55  10:00  10:05  10:10  10:13  10:16  10:18
           [--- EXP1 ----------][E2]
```

---

## Fichiers Liés

- Scripts utilisés : [`../01-chaos-scripts/`](../01-chaos-scripts/)
- Post-mortem : [`../03-postmortem/postmortem-incident-001.md`](../03-postmortem/postmortem-incident-001.md)
