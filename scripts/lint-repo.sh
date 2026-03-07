#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

status=0

report_error() {
  echo "[repo-lint] $*" >&2
  status=1
}

check_required_files() {
  local path
  local required_files=(
    "README.md"
    "LICENSE"
    "CLAUDE.md"
    "CONTRIBUTING.md"
    "SECURITY.md"
    "CODE_OF_CONDUCT.md"
    "SUPPORT.md"
    "ralph.toml"
    ".github/workflows/prd-create.yml"
    ".github/workflows/ralph.yml"
  )

  for path in "${required_files[@]}"; do
    if [[ ! -f "$path" ]]; then
      report_error "Missing required file: $path"
    fi
  done
}

check_readme_headings() {
  local heading
  local required_headings=(
    "## What Ralph Is"
    "## What Ralph Is Not"
    "## Quick Start"
    "## Requirements and Automation"
    "## Local Validation"
    "## Known Limitations"
    "## Support and Security"
  )

  for heading in "${required_headings[@]}"; do
    if ! grep -Fq -- "$heading" README.md; then
      report_error "README.md is missing required heading: $heading"
    fi
  done
}

check_registry_keys() {
  local key
  local required_keys=(
    "test_primary"
    "test_integration"
    "build_check"
    "lint_check"
    "format_fix"
  )

  for key in "${required_keys[@]}"; do
    if ! grep -Fq -- "${key} =" ralph.toml; then
      report_error "ralph.toml is missing required key: ${key}"
    fi
  done

  if ! grep -Fq -- 'build_check = "N/A"' ralph.toml; then
    report_error 'ralph.toml should keep build_check as "N/A" in this template repository'
  fi

  if ! grep -Fq -- 'lint_check = "N/A"' ralph.toml; then
    report_error 'ralph.toml should keep lint_check as "N/A" in this template repository'
  fi

  if ! grep -Fq -- 'format_fix = "N/A"' ralph.toml; then
    report_error 'ralph.toml should keep format_fix as "N/A" in this template repository'
  fi
}

check_finder_metadata() {
  local metadata_files

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    metadata_files="$(git ls-files --cached --others --exclude-standard | grep -E '(^|/)\.DS_Store$' || true)"
  else
    metadata_files="$(find . -name ".DS_Store" -print)"
  fi

  if [[ -n "$metadata_files" ]]; then
    report_error "Remove Finder metadata files before release:"
    while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      report_error "  $path"
    done <<< "$metadata_files"
  fi
}

check_required_files
check_readme_headings
check_registry_keys
check_finder_metadata

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

echo "[repo-lint] OK"
