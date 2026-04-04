#!/bin/bash
# Codex wrapper: .claude/hooks/notify-completion.sh に委譲
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
export CLAUDE_PROJECT_DIR="$PROJECT_DIR"
exec "$PROJECT_DIR/.claude/hooks/notify-completion.sh"
