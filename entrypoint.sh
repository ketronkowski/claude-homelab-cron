#!/bin/bash
set -euo pipefail

HEALTH_DATA=$(bash /tasks/homelab-health/collect.sh 2>&1)

PROMPT="$(cat "$TASK_PROMPT")

--- HEALTH DATA ---
$HEALTH_DATA"

exec claude -p "$PROMPT" --allowedTools bash --dangerously-skip-permissions --bare
