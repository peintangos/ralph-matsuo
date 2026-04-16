#!/bin/bash
# Run shellcheck on all maintained shell scripts.
# Gracefully skips when shellcheck is not installed (template repo may not require it).
set -euo pipefail

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "[lint:shell] shellcheck not found, skipping"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

# Collect all shell scripts maintained in the repository
shell_files="$(git ls-files --cached --others --exclude-standard | grep -E '\.sh$' | sort)"

if [[ -z "$shell_files" ]]; then
  echo "[lint:shell] No shell scripts found"
  exit 0
fi

file_count="$(printf '%s\n' "$shell_files" | wc -l | tr -d ' ')"
echo "[lint:shell] Checking $file_count files..."
printf '%s\n' "$shell_files" | xargs shellcheck --severity=warning
echo "[lint:shell] OK"
