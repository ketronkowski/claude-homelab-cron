#!/bin/bash
set -euo pipefail
exec claude -p "$(cat "$TASK_PROMPT")" --allowedTools bash --dangerously-skip-permissions --bare
