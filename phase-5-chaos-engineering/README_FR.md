# Phase 5 — Chaos Engineering

## Objectif

Valider la résilience du système par des expériences contrôlées qui injectent des défaillances réelles, et vérifier que les mécanismes SRE des phases précédentes (autoscaling, alertes, health check) répondent correctement.

**Principe du Chaos Engineering :** "Break things on purpose to build more resilient systems."

---

## Structure

```
phase-5-chaos-engineering/
├── 01-chaos-scripts/           # Scripts d'injection de chaos
│   ├── chaos-cpu-stress.sh         # Stress CPU via requêtes concurrentes
│   ├── chaos-kill-instance.sh      # Kill instance via az webapp restart
│   ├── chaos-latency-inject.js     # Proxy injection de latence
│   ├── azure-chaos-experiment.json # Définition Azure Chaos Studio
│   ├── README_FR.md
│   └── README.md
│
├── 02-chaos-results/           # Résultats et métriques du chaos run
│   ├── chaos-run-report.json       # Rapport complet (2 expériences)
│   ├── metrics-during-chaos.json   # Timeline métriques minute par minute
│   ├── README_FR.md
│   └── README.md
│
└── 03-postmortem/              # Post-mortem au format Google SRE
    ├── postmortem-incident-001.md  # Post-mortem complet
    ├── README_FR.md
    └── README.md
```

---

## Expériences Réalisées

### Expérience #1 — CPU Stress

| Paramètre | Valeur |
|---|---|
| Script | `chaos-cpu-stress.sh` |
| Durée | 10 minutes |
| Concurrence | 20 workers |
| CPU peak atteint | 87% |
| Scale-outs déclenchés | 2 (1→2→3 instances) |
| Alertes fired | `slo-latency-breach` (Sev2), `alert-asp-cpu-high` (Sev2) |
| Verdict | PARTIAL — SLO latence breachée (attendu), autoscaling correct |

### Expérience #2 — Kill Instance

| Paramètre | Valeur |
|---|---|
| Script | `chaos-kill-instance.sh` |
| Méthode | `az webapp restart` |
| Downtime | **94 secondes** |
| SLO recovery | < 120s ✅ |
| Alertes fired | `alert-webapp-5xx` (Sev2), `slo-availability-breach` (Sev1) |
| Verdict | PASS — service rétabli en < 2min |

---

## Résultats Clés

```
┌────────────────────────────────────────────────────────────────┐
│              CHAOS ENGINEERING — BILAN GLOBAL                  │
├─────────────────────────────┬──────────────────────────────────┤
│ Autoscaling déclenché       │ ✅ Oui (×2)                      │
│ Alertes correctement fired  │ ✅ 4/4                           │
│ Auto-healing confirmé       │ ✅ Oui (94s)                     │
│ SLO breach pendant chaos    │ ⚠️  Oui (attendu)                │
│ SLO breach après chaos      │ ✅ Non                           │
│ Error budget consommé       │ 13.6% (86.4% restant)            │
│ Politique déploiement       │ 🟢 VERT                          │
└─────────────────────────────┴──────────────────────────────────┘
```

---

## Lien avec les Phases Précédentes

| Phase | Mécanisme | Validé en Phase 5 |
|---|---|---|
| Phase 1 — Monitoring | Métriques Azure Monitor | ✅ CPU%, latence, 5xx capturés |
| Phase 2 — Logs/Tracing | Traces OTel, logs JSON | ✅ Traces visibles pendant downtime |
| Phase 3 — Autoscaling | Scale-out CPU > 75% | ✅ Déclenché correctement |
| Phase 4 — SLO/Alertes | KQL alerts, error budget | ✅ 4 alertes fired, budget suivi |

---

## Hypothèses Validées

| # | Hypothèse | Résultat |
|---|---|---|
| 1 | L'autoscaling absorbe la charge CPU avant le BREACH disponibilité | ✅ VALIDÉ |
| 2 | Le health check rétablit le service en < 2min après un restart | ✅ VALIDÉ (94s) |
| 3 | Les alertes SLO se déclenchent correctement | ✅ VALIDÉ (4/4) |

---

## Action Items Post-Chaos

| Priorité | Action | Sprint |
|---|---|---|
| P1 | Réduire fenêtre autoscaling PT5M → PT2M | Sprint N |
| P1 | Configurer graceful shutdown (30s) | Sprint N |
| P2 | Health check interval 30s → 15s | Sprint N+1 |
| P2 | Circuit breaker côté client (opossum) | Sprint N+1 |
| P3 | Multi-zone deployment | Backlog |

Voir le post-mortem complet : [`03-postmortem/postmortem-incident-001.md`](03-postmortem/postmortem-incident-001.md)

---

## Ressources

- [Azure Chaos Studio Documentation](https://learn.microsoft.com/en-us/azure/chaos-studio/)
- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [Google SRE Book — Chapter 15 : Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)
- [Netflix Chaos Monkey](https://github.com/Netflix/chaosmonkey)
