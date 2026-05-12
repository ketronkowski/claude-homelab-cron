#!/bin/bash
# Pre-collect homelab health data and output a compact summary.
set -uo pipefail

echo "DATE: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo ""

# --- NODES ---
echo "=== NODES ==="
NODE_OUTPUT=$(kubectl get nodes --no-headers 2>/dev/null)
if [ -z "$NODE_OUTPUT" ]; then
  echo "  ERROR: could not reach cluster API"
else
  echo "$NODE_OUTPUT" | while read -r name ready status restarts age; do
    echo "  $name: $ready"
  done
  # Check for pressure conditions
  kubectl get nodes -o json 2>/dev/null | jq -r '
    .items[] |
    . as $n |
    ($n.status.conditions[] | select(.type != "Ready" and .status == "True")) |
    "  WARNING: \($n.metadata.name) has condition \(.type)=True"
  ' 2>/dev/null || true
fi
echo ""

# --- PODS ---
echo "=== PODS WITH ISSUES (non-Running/Succeeded or restarts > 5) ==="
POD_ISSUES=$(kubectl get pods -A --no-headers 2>/dev/null | awk '
{
  ns=$1; name=$2; status=$4; restarts=int($5)
  if (status != "Running" && status != "Completed" && status != "Succeeded" && status != "Terminating")
    printf "  NON-RUNNING: %s/%s (phase=%s)\n", ns, name, status
  else if (restarts > 5)
    printf "  HIGH-RESTARTS: %s/%s (%d restarts, %s)\n", ns, name, restarts, status
}')
if [ -z "$POD_ISSUES" ]; then
  echo "  All pods healthy."
else
  echo "$POD_ISSUES"
fi
echo ""

# --- ARGOCD ---
echo "=== ARGOCD APPLICATIONS ==="
APP_TOTAL=$(kubectl get applications -A --no-headers 2>/dev/null | wc -l | tr -d ' ')
APP_ISSUES=$(kubectl get applications -A --no-headers \
  -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status' \
  2>/dev/null | awk 'NR>0 && ($2 != "Synced" || $3 != "Healthy") {print "  ISSUE:", $1, "sync="$2, "health="$3}')
if [ -z "$APP_ISSUES" ]; then
  echo "  All $APP_TOTAL apps Synced and Healthy."
else
  echo "$APP_ISSUES"
fi
echo ""

# --- REACHABILITY ---
echo "=== REACHABILITY ==="
declare -a URLS=(
  "https://wled.lab.ri.tronkowski.net"
  "https://openwebui.lab.ri.tronkowski.net"
  "https://dns.lab.ri.tronkowski.net"
  "https://remote-falcon.lab.ri.tronkowski.net"
  "https://mongodb.lab.ri.tronkowski.net"
  "https://longhorn.lab.ri.tronkowski.net"
)
for url in "${URLS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null)
  if [[ "$code" =~ ^(2|3|401|403) ]]; then
    echo "  OK ($code): $url"
  else
    echo "  FAIL ($code): $url"
  fi
done
echo ""
