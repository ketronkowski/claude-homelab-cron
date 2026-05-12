#!/bin/bash
set -euo pipefail

TASK_DIR="${TASK_DIR:-/tasks/homelab-health}"

# Load task-level LLM config (LLM_PROVIDER, ANTHROPIC_MODEL, OLLAMA_MODEL)
[ -f "$TASK_DIR/config.env" ] && source "$TASK_DIR/config.env"

HEALTH_DATA=$(bash "$TASK_DIR/collect.sh" 2>&1)

LLM_PROVIDER="${LLM_PROVIDER:-anthropic}"
ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-claude-sonnet-4-6}"
OLLAMA_MODEL="${OLLAMA_MODEL:-gemma3:4b}"

if [ "$LLM_PROVIDER" = "ollama" ]; then
    export OLLAMA_MODEL OLLAMA_BASE_URL
    export SEND_SCRIPT="$TASK_DIR/send_email.py"
    printf '%s\n\n--- HEALTH DATA ---\n%s' \
        "$(cat "$TASK_DIR/prompt-ollama.txt")" "$HEALTH_DATA" \
        | exec python3 /tasks/run_ollama.py
else
    FULL_PROMPT="$(cat "$TASK_DIR/prompt.txt")

--- HEALTH DATA ---
$HEALTH_DATA"
    exec claude -p "$FULL_PROMPT" \
        --model "$ANTHROPIC_MODEL" \
        --allowedTools bash \
        --dangerously-skip-permissions \
        --bare
fi
