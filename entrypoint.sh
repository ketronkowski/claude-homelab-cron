#!/bin/bash
set -euo pipefail

HEALTH_DATA=$(bash /tasks/homelab-health/collect.sh 2>&1)
LLM_PROVIDER="${LLM_PROVIDER:-anthropic}"

if [ "$LLM_PROVIDER" = "ollama" ]; then
    PROMPT_FILE="${TASK_PROMPT_OLLAMA:-/tasks/homelab-health/prompt-ollama.txt}"
    printf '%s\n\n--- HEALTH DATA ---\n%s' "$(cat "$PROMPT_FILE")" "$HEALTH_DATA" \
        | exec python3 /tasks/run_ollama.py
else
    FULL_PROMPT="$(cat "$TASK_PROMPT")

--- HEALTH DATA ---
$HEALTH_DATA"
    exec claude -p "$FULL_PROMPT" --allowedTools bash --dangerously-skip-permissions --bare
fi
