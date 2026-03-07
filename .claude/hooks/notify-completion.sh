#!/bin/bash
set -euo pipefail

INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

TITLE="Claude Code"
MESSAGE="Task completed"

if command -v notify-send >/dev/null 2>&1; then
  notify-send "$TITLE" "$MESSAGE"
  exit 0
fi

if command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\""
  exit 0
fi

if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -Command "[console]::beep(1000,250)" >/dev/null 2>&1 || true
  exit 0
fi

printf '\a'
exit 0
