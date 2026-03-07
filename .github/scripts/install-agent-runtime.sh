#!/bin/bash
set -euo pipefail

CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-latest}"

if command -v claude >/dev/null 2>&1; then
  echo "Claude Code CLI is already available: $(command -v claude)"
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to install Claude Code CLI in this workflow." >&2
  echo "Provide Claude Code CLI through the runner image or customize .github/scripts/install-agent-runtime.sh." >&2
  exit 1
fi

echo "Installing Claude Code CLI (${CLAUDE_CODE_VERSION})..."
npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"
