#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

capture_repo_command() {
  local output_var="$1"
  local status_var="$2"
  local repo_dir="$3"
  shift 3

  local command_output
  local command_status

  set +e
  command_output="$(cd "$repo_dir" && "$@" 2>&1)"
  command_status=$?
  set -e

  printf -v "$output_var" '%s' "$command_output"
  printf -v "$status_var" '%s' "$command_status"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if ! grep -Fq "$needle" <<< "$haystack"; then
    echo "Assertion failed: $message" >&2
    echo "Expected to find: $needle" >&2
    echo "Output was:" >&2
    echo "$haystack" >&2
    exit 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$expected" != "$actual" ]]; then
    echo "Assertion failed: $message" >&2
    echo "Expected: $expected" >&2
    echo "Actual: $actual" >&2
    exit 1
  fi
}

setup_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/scripts" "$repo_dir/.github/workflows"
  cp "$SCRIPT_DIR/lint-repo.sh" "$repo_dir/scripts/lint-repo.sh"
  chmod +x "$repo_dir/scripts/lint-repo.sh"
  git init -q "$repo_dir"

  cat > "$repo_dir/README.md" <<'EOF'
# Test Repo

## What Ralph Is

Template.

## What Ralph Is Not

App.

## Quick Start

Text.

## Requirements and Automation

Text.

## Local Validation

Text.

## Known Limitations

Text.

## Support and Security

Text.
EOF

  cat > "$repo_dir/ralph.toml" <<'EOF'
test_primary = "npm run test"
test_integration = "npm run test:orchestrator"
build_check = "N/A"
lint_check = "N/A"
format_fix = "N/A"
EOF

  touch "$repo_dir/LICENSE"
  touch "$repo_dir/CLAUDE.md"
  touch "$repo_dir/CONTRIBUTING.md"
  touch "$repo_dir/SECURITY.md"
  touch "$repo_dir/CODE_OF_CONDUCT.md"
  touch "$repo_dir/SUPPORT.md"
  touch "$repo_dir/.github/workflows/prd-create.yml"
  touch "$repo_dir/.github/workflows/ralph.yml"
}

test_successful_repo_passes() {
  local repo_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN

  setup_repo "$repo_dir"

  capture_repo_command output status "$repo_dir" "$BASH" scripts/lint-repo.sh
  assert_exit_code 0 "$status" "Valid repo should pass"
  assert_contains "$output" "[repo-lint] OK" "Success output should be reported"
}

test_missing_support_file_fails() {
  local repo_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN

  setup_repo "$repo_dir"
  rm -f "$repo_dir/SUPPORT.md"

  capture_repo_command output status "$repo_dir" "$BASH" scripts/lint-repo.sh
  assert_exit_code 1 "$status" "Missing OSS support file should fail"
  assert_contains "$output" "Missing required file: SUPPORT.md" "Missing support file should be reported"
}

test_ds_store_fails() {
  local repo_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN

  setup_repo "$repo_dir"
  touch "$repo_dir/.DS_Store"
  git -C "$repo_dir" add -f .DS_Store

  capture_repo_command output status "$repo_dir" "$BASH" scripts/lint-repo.sh
  assert_exit_code 1 "$status" "Finder metadata should fail lint"
  assert_contains "$output" "Remove Finder metadata files before release:" "Finder metadata error should be reported"
  assert_contains "$output" ".DS_Store" "Specific Finder metadata path should be listed"
}

test_non_portable_registry_value_fails() {
  local repo_dir output status rewritten_registry
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN

  setup_repo "$repo_dir"
  rewritten_registry="$(mktemp)"
  sed 's/lint_check = "N\/A"/lint_check = "npm run lint:repo"/' "$repo_dir/ralph.toml" > "$rewritten_registry"
  mv "$rewritten_registry" "$repo_dir/ralph.toml"

  capture_repo_command output status "$repo_dir" "$BASH" scripts/lint-repo.sh
  assert_exit_code 1 "$status" "Non-portable registry values should fail"
  assert_contains "$output" 'ralph.toml should keep lint_check as "N/A" in this template repository' "lint_check policy should be reported"
}

test_successful_repo_passes
test_missing_support_file_fails
test_ds_store_fails
test_non_portable_registry_value_fails
