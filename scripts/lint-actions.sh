#!/bin/bash
# Run actionlint on all GitHub Actions workflow files.
# Gracefully skips when actionlint is not installed (template repo may not require it).
set -euo pipefail

if ! command -v actionlint >/dev/null 2>&1; then
  echo "[lint:actions] actionlint not found, skipping"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

WORKFLOWS_DIR="$REPO_ROOT/.github/workflows"

if [[ ! -d "$WORKFLOWS_DIR" ]]; then
  echo "[lint:actions] No .github/workflows/ directory found"
  exit 0
fi

echo "[lint:actions] Checking workflow files..."
actionlint "$WORKFLOWS_DIR"/*.yml
echo "[lint:actions] OK"
