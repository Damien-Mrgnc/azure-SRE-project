# Étape 2 : Test de Charge (k6)

*Read the [English Version](README.md) here.*

## Objectif

Valider le comportement de l'autoscaling sous charge réelle à l'aide de **k6**, un outil de load testing moderne. Le test simule une montée progressive jusqu'à 150 utilisateurs virtuels pour déclencher les règles de scale-out définies en Étape 1.

## Outil utilisé : k6

k6 est un outil de load testing open-source écrit en Go, avec des scénarios définis en JavaScript. Il génère des métriques précises (latences, taux d'erreurs) et permet de définir des **SLO comme seuils d'échec du test**.

**Installation :**
```bash
# Windows
winget install k6

# Linux/Ubuntu
sudo apt install k6

# macOS
brew install k6
```

## Scénario de test

Le test suit 6 étapes sur 20 minutes :

| Étape | Durée | VUs | Objectif |
|---|---|---|---|
| Rampe douce | 2 min | 0 → 10 | Vérifier la santé de base |
| Montée | 3 min | 10 → 50 | Charge normale |
| Pic | 5 min | 50 → 150 | **Déclencher le scale-out** |
| Maintien | 5 min | 150 | Observer la stabilité multi-instances |
| Descente | 3 min | 150 → 20 | **Déclencher le scale-in** |
| Fin | 2 min | 20 → 0 | Retour au repos |

## Mix de requêtes

| Endpoint | % du trafic | Raison |
|---|---|---|
| `GET /api/config` | 70% | Charge légère, représente le trafic réel |
| `GET /` | 20% | SSR + appel API externe, charge modérée |
| `POST /api/admin/stress` | 10% | **Brûlure CPU intentionnelle** — déclenche le scale-out |

La route `/api/admin/stress` (ajoutée Phase 1 pour le Chaos Engineering) bloque volontairement le CPU pendant 2 secondes, simulant un traitement intensif.

## Seuils SLO (thresholds)

Le test **échoue automatiquement** si ces seuils sont dépassés :

```javascript
thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'], // Latence
    error_rate: ['rate<0.01'],                        // Erreurs < 1%
}
```

## Exécution

```bash
# Test basique
k6 run load-test.js

# Avec URL cible personnalisée
k6 run --env BASE_URL=https://app-projet3-sre.azurewebsites.net load-test.js

# Avec output InfluxDB (pour dashboard Grafana temps réel)
k6 run --out influxdb=http://localhost:8086/k6 load-test.js
```

## Résultats obtenus (simulés)

Voir [`load-test-report.json`](./load-test-report.json) pour le rapport complet. Points clés :

| Métrique | Résultat | SLO | Verdict |
|---|---|---|---|
| Latence p95 | 312 ms | < 500 ms | ✅ PASS |
| Latence p99 | 748 ms | < 1000 ms | ✅ PASS |
| Taux d'erreurs | 0.18% | < 1% | ✅ PASS |
| Disponibilité | 99.82% | > 99.9% | ⚠️ LIMITE |

### Chronologie de l'autoscaling

```
T+07m12s : SCALE-OUT → 2 instances  (CPU 78% > 75%)
T+12m45s : SCALE-OUT → 3 instances  (CPU 82% > 75%)
T+26m30s : SCALE-IN  → 2 instances  (CPU 18% < 25%)
T+36m31s : SCALE-IN  → 1 instance   (CPU 13% < 25%)
```

L'autoscaling a absorbé le pic sans dépasser les SLO de latence. La disponibilité à 99.82% (légèrement sous l'objectif 99.9%) est liée aux quelques requêtes rejetées lors du scale-out initial — une amélioration possible serait de pré-chauffer les instances.

## Fichiers de cette étape

| Fichier | Description |
|---|---|
| [`load-test.js`](./load-test.js) | Script k6 — scénario 6 étapes, 3 endpoints, seuils SLO |
| [`load-test-report.json`](./load-test-report.json) | Rapport complet simulé — métriques, événements autoscaling, timeline CPU |
