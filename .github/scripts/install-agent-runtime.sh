#!/bin/bash
set -euo pipefail

# Determine which tool to install. Default to claude for backward compatibility.
AGENT_TOOL="${INPUT_TOOL:-claude}"

CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-latest}"
CODEX_VERSION="${CODEX_VERSION:-latest}"

install_claude() {
  if command -v claude >/dev/null 2>&1; then
    echo "Claude Code CLI is already available: $(command -v claude)"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required to install Claude Code CLI in this workflow." >&2
    echo "Provide Claude Code CLI through the runner image or customize .github/scripts/install-agent-runtime.sh." >&2
    return 1
  fi

  echo "Installing Claude Code CLI (${CLAUDE_CODE_VERSION})..."
  npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"
}

install_codex() {
  if command -v codex >/dev/null 2>&1; then
    echo "Codex CLI is already available: $(command -v codex)"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required to install Codex CLI in this workflow." >&2
    echo "Provide Codex CLI through the runner image or customize .github/scripts/install-agent-runtime.sh." >&2
    return 1
  fi

  echo "Installing Codex CLI (${CODEX_VERSION})..."
  npm install -g "@openai/codex@${CODEX_VERSION}"
}

case "$AGENT_TOOL" in
  claude)
    install_claude
    ;;
  codex)
    install_codex
    ;;
  *)
    echo "Unknown agent tool: $AGENT_TOOL" >&2
    exit 1
    ;;
esac
