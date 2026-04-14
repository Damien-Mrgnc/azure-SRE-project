# 03 — Post-Mortem

Ce dossier contient le post-mortem de l'incident généré lors du Chaos Engineering Run de la Phase 5.

## Fichiers

| Fichier | Description |
|---|---|
| `postmortem-incident-001.md` | Post-mortem complet au format Google SRE |

---

## Qu'est-ce qu'un Post-Mortem ?

Un post-mortem (ou "revue d'incident") est un document structuré rédigé après un incident ou une expérience de chaos pour :

1. **Documenter** ce qui s'est passé (timeline factuelle)
2. **Analyser** les causes racines (5 Whys)
3. **Identifier** ce qui a fonctionné et ce qui n'a pas fonctionné
4. **Définir** des action items concrets pour éviter la récurrence

La culture SRE insiste sur les **post-mortems blameless** : l'objectif n'est pas de trouver un coupable mais de comprendre les défaillances systémiques.

---

## Résumé du Post-Mortem #001

**Incident :** Dégradation lors du Chaos Engineering Run
**Date :** 2026-04-13
**Durée d'impact :** ~15 minutes (10:00 → 10:16)
**Sévérité max :** Sev1 (downtime 94s lors de l'expérience #2)

### Ce qui a fonctionné ✅

- Autoscaling déclenché correctement (1 → 3 instances)
- 4 alertes déclenchées sans faux positifs
- Health check Azure a rétabli le service en 94s (SLO : < 120s)
- Monitoring complet (Azure Monitor + Application Insights + OTel)
- Error budget : 86.4% restant → déploiements normaux autorisés

### Ce qui n'a pas fonctionné ❌

- Délai autoscaling de 5min → latence p99 > 2000ms pendant 5min
- Pas de graceful shutdown → 8 erreurs 5xx évitables
- Pas de circuit breaker côté client

### Action Items Clés

| Priorité | Action |
|---|---|
| P1 | Réduire fenêtre autoscaling PT5M → PT2M |
| P1 | Configurer graceful shutdown (WEBSITE_GRACEFUL_SHUTDOWN_TIMEOUT=30) |
| P2 | Réduire health check interval 30s → 15s |
| P2 | Implémenter circuit breaker (opossum) |

---

## Format Google SRE

Le post-mortem suit la structure recommandée par Google SRE :

```
1. Résumé Exécutif
2. Timeline Détaillée
3. Impact (utilisateurs + SLO + error budget)
4. Analyse des Causes Racines (5 Whys)
5. Ce qui a fonctionné
6. Ce qui n'a pas fonctionné
7. Action Items (court/moyen/long terme)
8. Métriques clés
9. Verdict final
10. Leçons apprises
```

---

## Fichiers Liés

- Résultats du chaos run : [`../02-chaos-results/`](../02-chaos-results/)
- Scripts utilisés : [`../01-chaos-scripts/`](../01-chaos-scripts/)
