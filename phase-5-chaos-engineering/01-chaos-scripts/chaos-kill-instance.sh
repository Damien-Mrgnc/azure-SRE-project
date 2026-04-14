#!/bin/bash
# =============================================================================
# Chaos Experiment #2 : Instance Kill (Restart)
# =============================================================================
# Objectif : Simuler la mort brutale de l'instance App Service pour vérifier :
#   1. Le health check Azure redémarre automatiquement l'instance
#   2. L'alerte alert-webapp-5xx se déclenche pendant le redémarrage
#   3. La durée d'indisponibilité est < 2 min (health_check_eviction_time_in_min)
#   4. Les traces OTel capturent les erreurs de connexion (Phase 2)
#
# Mécanisme : az webapp restart → indisponibilité temporaire de l'App Service
#
# Usage :
#   chmod +x chaos-kill-instance.sh
#   ./chaos-kill-instance.sh --rg rg-projet3-sre --app app-projet3-sre-abc123
# =============================================================================

set -euo pipefail

# --- Paramètres ---
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-projet3-sre}"
APP_NAME="${APP_NAME:-}"
APP_URL="${APP_URL:-https://app-projet3-sre.azurewebsites.net}"
PROBE_INTERVAL="${PROBE_INTERVAL:-5}"  # Sonder toutes les 5s

if [ -z "$APP_NAME" ]; then
    echo "ERROR: APP_NAME non défini."
    echo "Usage: APP_NAME=app-projet3-sre-abc123 RESOURCE_GROUP=rg-projet3-sre ./chaos-kill-instance.sh"
    exit 1
fi

echo "============================================"
echo "CHAOS EXPERIMENT #2 : Instance Kill"
echo "============================================"
echo "Resource Group : $RESOURCE_GROUP"
echo "App Name       : $APP_NAME"
echo "Target URL     : $APP_URL"
echo "Start          : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "============================================"
echo ""

# --- Sonder la disponibilité en arrière-plan ---
probe_availability() {
    local url="$1"
    local interval="$2"
    local outfile="/tmp/chaos_probe_$$.log"

    echo "" > "$outfile"

    while true; do
        TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time 5 \
            "${url}/api/config" 2>/dev/null || echo "000")

        if [[ "$STATUS" == "200" ]]; then
            echo "$TIMESTAMP STATUS=$STATUS OK" | tee -a "$outfile"
        else
            echo "$TIMESTAMP STATUS=$STATUS *** DOWN ***" | tee -a "$outfile"
        fi

        sleep "$interval"
    done
}

# Démarrer le probe en arrière-plan
probe_availability "$APP_URL" "$PROBE_INTERVAL" &
PROBE_PID=$!

# Attendre 10s pour avoir une baseline
echo "Baseline (10s avant le chaos)..."
sleep 10

# --- Injecter le chaos ---
echo ""
echo "[$(date -u +%H:%M:%SZ)] CHAOS : Redémarrage de $APP_NAME..."
KILL_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

az webapp restart \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --output none

echo "[$(date -u +%H:%M:%SZ)] Commande az webapp restart envoyée."
echo ""

# --- Attendre la récupération ---
echo "Attente de la récupération (max 5 min)..."
RECOVERY_START=$(date +%s)
MAX_WAIT=300  # 5 minutes

while true; do
    ELAPSED=$(($(date +%s) - RECOVERY_START))
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 5 "${APP_URL}/api/config" 2>/dev/null || echo "000")

    if [[ "$STATUS" == "200" ]]; then
        RECOVERY_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        echo ""
        echo "[$(date -u +%H:%M:%SZ)] SERVICE RÉTABLI après ${ELAPSED}s (HTTP $STATUS)"
        break
    fi

    if [ $ELAPSED -gt $MAX_WAIT ]; then
        echo ""
        echo "[$(date -u +%H:%M:%SZ)] TIMEOUT : service non rétabli après ${MAX_WAIT}s — INCIDENT"
        break
    fi

    sleep "$PROBE_INTERVAL"
done

# Stopper le probe
kill "$PROBE_PID" 2>/dev/null || true

# --- Résumé ---
echo ""
echo "============================================"
echo "FIN DU CHAOS KILL INSTANCE"
echo "============================================"
echo "Heure du kill      : $KILL_TIME"
echo "Heure de récupérat.: ${RECOVERY_TIME:-TIMEOUT}"
echo "Durée d'interruption: ${ELAPSED}s"
echo "============================================"
echo ""
echo "Points à vérifier dans Azure Portal :"
echo "  - Azure Monitor → Alertes → alert-webapp-5xx"
echo "  - App Service → Diagnostic → Application Event Log"
echo "  - Application Insights → Failures (traces OTel pendant le downtime)"
