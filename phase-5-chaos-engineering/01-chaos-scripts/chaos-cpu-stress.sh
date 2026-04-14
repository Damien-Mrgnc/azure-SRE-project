#!/bin/bash
# =============================================================================
# Chaos Experiment #1 : CPU Stress
# =============================================================================
# Objectif : Saturer le CPU de l'App Service pour vérifier que :
#   1. L'alerte alert-asp-cpu-high se déclenche (Phase 4 — CPU > 80%)
#   2. L'autoscaling scale-out s'active (Phase 3 — CPU > 75%)
#   3. Le service reste disponible (SLO disponibilité Phase 4 — 99.9%)
#
# Mécanisme : appels répétés en parallèle sur POST /api/admin/stress
# (route de chaos intégrée à l'app — bloque le CPU 2s par appel)
#
# Usage :
#   chmod +x chaos-cpu-stress.sh
#   ./chaos-cpu-stress.sh --url https://app-projet3-sre.azurewebsites.net --duration 300
# =============================================================================

set -euo pipefail

# --- Paramètres ---
APP_URL="${1:-https://app-projet3-sre.azurewebsites.net}"
DURATION="${2:-300}"      # Durée du chaos en secondes (défaut 5 min)
CONCURRENCY="${3:-20}"    # Nombre de requêtes parallèles
STRESS_MS="${4:-2000}"    # Durée de blocage CPU par requête (ms)

ADMIN_TOKEN="${ADMIN_TOKEN:-}"  # Bearer token admin (optionnel si auth désactivée en lab)

echo "============================================"
echo "CHAOS EXPERIMENT #1 : CPU Stress"
echo "============================================"
echo "Target  : $APP_URL"
echo "Duration: ${DURATION}s"
echo "Workers : $CONCURRENCY parallel requests"
echo "Stress  : ${STRESS_MS}ms CPU burn per request"
echo "Start   : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "============================================"
echo ""

# --- Fonction : une requête de stress ---
stress_request() {
    local url="$1"
    local ms="$2"
    local token="$3"

    local headers=(-H "Content-Type: application/json")
    if [ -n "$token" ]; then
        headers+=(-H "Authorization: Bearer $token")
    fi

    curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" \
        -X POST \
        "${headers[@]}" \
        -d "{\"duration\": $ms}" \
        "${url}/api/admin/stress" \
        --max-time 30 \
        --retry 2 \
        --retry-delay 1 || echo "ERROR (connection failed)"
}

export -f stress_request

# --- Boucle principale ---
START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))
REQUEST_COUNT=0
SUCCESS_COUNT=0
ERROR_COUNT=0

echo "Démarrage du chaos — appuyez sur Ctrl+C pour arrêter manuellement"
echo ""

while [ $(date +%s) -lt $END_TIME ]; do
    ELAPSED=$(($(date +%s) - START_TIME))

    # Envoyer CONCURRENCY requêtes en parallèle
    RESULTS=$(seq 1 "$CONCURRENCY" | xargs -P "$CONCURRENCY" -I{} bash -c \
        "stress_request '$APP_URL' '$STRESS_MS' '$ADMIN_TOKEN'")

    # Compter les succès/erreurs
    while IFS= read -r line; do
        REQUEST_COUNT=$((REQUEST_COUNT + 1))
        STATUS=$(echo "$line" | cut -d' ' -f1)
        if [[ "$STATUS" == "200" ]] || [[ "$STATUS" == "401" ]]; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done <<< "$RESULTS"

    echo "[T+${ELAPSED}s] Batch envoyé — Total: $REQUEST_COUNT req | Succès: $SUCCESS_COUNT | Erreurs: $ERROR_COUNT"

    # Courte pause entre les batches (1s)
    sleep 1
done

# --- Résumé ---
TOTAL_ELAPSED=$(($(date +%s) - START_TIME))
ERROR_RATE=$(echo "scale=2; $ERROR_COUNT * 100 / $REQUEST_COUNT" | bc 2>/dev/null || echo "N/A")

echo ""
echo "============================================"
echo "FIN DU CHAOS CPU STRESS"
echo "============================================"
echo "Durée réelle    : ${TOTAL_ELAPSED}s"
echo "Requêtes totales: $REQUEST_COUNT"
echo "Succès          : $SUCCESS_COUNT"
echo "Erreurs         : $ERROR_COUNT"
echo "Taux d'erreurs  : ${ERROR_RATE}%"
echo "Fin             : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "============================================"
echo ""
echo "Vérifier dans Azure Portal :"
echo "  - Azure Monitor → Alertes → alert-asp-cpu-high"
echo "  - App Service Plan → Scale out → Historique"
echo "  - Log Analytics → AppServiceHTTPLogs"
