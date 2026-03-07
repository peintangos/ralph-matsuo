#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/scripts/ralph" "$repo_dir/docs/prds"
  cp "$SCRIPT_DIR/orchestrator.sh" "$repo_dir/scripts/ralph/"
  cp "$SCRIPT_DIR/prd-helpers.sh" "$repo_dir/scripts/ralph/"
}

run_orchestrator() {
  local repo_dir="$1"

  (cd "$repo_dir" && bash scripts/ralph/orchestrator.sh --dry-run)
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

test_malformed_progress_is_incomplete() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"

  mkdir -p "$repo_dir/docs/prds/prd-malformed/specifications"
  cat > "$repo_dir/docs/prds/prd-malformed/prd.md" <<'EOF'
# Malformed PRD

## Branch

`ralph/malformed`
EOF
  cat > "$repo_dir/docs/prds/prd-malformed/progress.md" <<'EOF'
# Progress

This file is non-empty but does not contain valid status rows.
EOF
  cat > "$repo_dir/docs/prds/prd-malformed/todo.md" <<'EOF'
# TODO

No executable tasks yet.
EOF
  cat > "$repo_dir/docs/prds/prd-malformed/specifications/spec-001-test.md" <<'EOF'
# Spec
EOF

  local output
  output="$(run_orchestrator "$repo_dir")"
  assert_contains "$output" "[incomplete] prd-malformed" "Malformed progress.md should block execution"
  assert_contains "$output" "progress.md has no specification rows with valid status" "Malformed progress reason should be reported"
}

test_mismatched_progress_count_is_incomplete() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"

  mkdir -p "$repo_dir/docs/prds/prd-mismatch/specifications"
  cat > "$repo_dir/docs/prds/prd-mismatch/prd.md" <<'EOF'
# Mismatch PRD

## Branch

`ralph/mismatch`
EOF
  cat > "$repo_dir/docs/prds/prd-mismatch/progress.md" <<'EOF'
# Progress

| Specification | Title | Status | Completed On | Notes |
|---------------|-------|--------|--------------|-------|
| spec-001-test | Test | pending | | |
EOF
  cat > "$repo_dir/docs/prds/prd-mismatch/todo.md" <<'EOF'
# TODO

- [ ] spec-001: First task
EOF
  cat > "$repo_dir/docs/prds/prd-mismatch/specifications/spec-001-test.md" <<'EOF'
# Spec 1
EOF
  cat > "$repo_dir/docs/prds/prd-mismatch/specifications/spec-002-test.md" <<'EOF'
# Spec 2
EOF

  local output
  output="$(run_orchestrator "$repo_dir")"
  assert_contains "$output" "[incomplete] prd-mismatch" "Spec/progress mismatch should block execution"
  assert_contains "$output" "progress.md spec count (1) does not match specifications/ file count (2)" "Mismatch reason should be reported"
  assert_contains "$output" "progress.md is missing specification rows for: spec-002-test" "Missing specification names should be reported"
}

test_duplicate_progress_rows_are_incomplete() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"

  mkdir -p "$repo_dir/docs/prds/prd-duplicate/specifications"
  cat > "$repo_dir/docs/prds/prd-duplicate/prd.md" <<'EOF'
# Duplicate Progress PRD

## Branch

`ralph/duplicate`
EOF
  cat > "$repo_dir/docs/prds/prd-duplicate/progress.md" <<'EOF'
# Progress

| Specification | Title | Status | Completed On | Notes |
|---------------|-------|--------|--------------|-------|
| spec-001-test | Test | done | 2026-03-07 | |
| spec-001-test | Duplicate | done | 2026-03-07 | |
EOF
  cat > "$repo_dir/docs/prds/prd-duplicate/todo.md" <<'EOF'
# TODO
EOF
  cat > "$repo_dir/docs/prds/prd-duplicate/dependencies.md" <<'EOF'
# Dependencies
EOF
  cat > "$repo_dir/docs/prds/prd-duplicate/specifications/spec-001-test.md" <<'EOF'
# Spec 1
EOF
  cat > "$repo_dir/docs/prds/prd-duplicate/specifications/spec-002-test.md" <<'EOF'
# Spec 2
EOF

  local output
  output="$(run_orchestrator "$repo_dir")"
  assert_contains "$output" "[incomplete] prd-duplicate" "Duplicate progress rows should block execution"
  assert_contains "$output" "progress.md has duplicate specification rows: spec-001-test" "Duplicate specification rows should be reported"
  assert_contains "$output" "progress.md is missing specification rows for: spec-002-test" "Missing specification rows should be reported"
}

test_invalid_branch_name_is_incomplete() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"

  mkdir -p "$repo_dir/docs/prds/prd-invalid-branch/specifications"
  cat > "$repo_dir/docs/prds/prd-invalid-branch/prd.md" <<'EOF'
# Invalid Branch PRD

## Branch

No backticked branch name is set here.
EOF
  cat > "$repo_dir/docs/prds/prd-invalid-branch/progress.md" <<'EOF'
# Progress

| Specification | Title | Status | Completed On | Notes |
|---------------|-------|--------|--------------|-------|
| spec-001-test | Test | pending | | |
EOF
  cat > "$repo_dir/docs/prds/prd-invalid-branch/todo.md" <<'EOF'
# TODO

- [ ] spec-001: First task
EOF
  cat > "$repo_dir/docs/prds/prd-invalid-branch/dependencies.md" <<'EOF'
# Dependencies
EOF
  cat > "$repo_dir/docs/prds/prd-invalid-branch/specifications/spec-001-test.md" <<'EOF'
# Spec
EOF

  local output
  output="$(run_orchestrator "$repo_dir")"
  assert_contains "$output" "[incomplete] prd-invalid-branch" "PRDs without a valid branch name should be incomplete"
  assert_contains "$output" "prd.md has no valid branch name in the '## Branch' section" "Missing branch values should be reported"
}

test_ready_prd_is_detected() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"

  mkdir -p "$repo_dir/docs/prds/prd-ready/specifications"
  cat > "$repo_dir/docs/prds/prd-ready/prd.md" <<'EOF'
# Ready PRD

## Branch

`ralph/ready`
EOF
  cat > "$repo_dir/docs/prds/prd-ready/progress.md" <<'EOF'
# Progress

| Specification | Title | Status | Completed On | Notes |
|---------------|-------|--------|--------------|-------|
| spec-001-test | Test | pending | | |
EOF
  cat > "$repo_dir/docs/prds/prd-ready/todo.md" <<'EOF'
# TODO

- [ ] spec-001: First task
EOF
  cat > "$repo_dir/docs/prds/prd-ready/dependencies.md" <<'EOF'
# Dependencies
EOF
  cat > "$repo_dir/docs/prds/prd-ready/specifications/spec-001-test.md" <<'EOF'
# Spec
EOF

  local output
  output="$(run_orchestrator "$repo_dir")"
  assert_contains "$output" "[ready]      prd-ready" "Ready PRD should be selected as ready"
  assert_contains "$output" "[dry-run] Skipping ralph.sh execution" "Dry-run should stop before execution"
}

test_stale_lock_is_ignored() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"

  mkdir -p "$repo_dir/docs/prds/prd-stale-lock/specifications"
  cat > "$repo_dir/docs/prds/prd-stale-lock/prd.md" <<'EOF'
# Stale Lock PRD

## Branch

`ralph/stale-lock`
EOF
  cat > "$repo_dir/docs/prds/prd-stale-lock/progress.md" <<'EOF'
# Progress

| Specification | Title | Status | Completed On | Notes |
|---------------|-------|--------|--------------|-------|
| spec-001-test | Test | pending | | |
EOF
  cat > "$repo_dir/docs/prds/prd-stale-lock/todo.md" <<'EOF'
# TODO

- [ ] spec-001: First task
EOF
  cat > "$repo_dir/docs/prds/prd-stale-lock/dependencies.md" <<'EOF'
# Dependencies
EOF
  cat > "$repo_dir/docs/prds/prd-stale-lock/specifications/spec-001-test.md" <<'EOF'
# Spec
EOF
  echo "2026-03-07T00:00:00Z stale-runner" > "$repo_dir/docs/prds/prd-stale-lock/.ralph-lock"

  local output
  output="$(run_orchestrator "$repo_dir")"
  assert_contains "$output" "[ready]      prd-stale-lock" "Stale lock files should not block ready PRDs"
  assert_contains "$output" "[dry-run] Skipping ralph.sh execution" "Dry-run should still select the ready PRD"
}

test_numbered_todo_is_incomplete() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"

  mkdir -p "$repo_dir/docs/prds/prd-numbered/specifications"
  cat > "$repo_dir/docs/prds/prd-numbered/prd.md" <<'EOF'
# Numbered Todo PRD

## Branch

`ralph/numbered`
EOF
  cat > "$repo_dir/docs/prds/prd-numbered/progress.md" <<'EOF'
# Progress

| Specification | Title | Status | Completed On | Notes |
|---------------|-------|--------|--------------|-------|
| spec-001-test | Test | pending | | |
EOF
  cat > "$repo_dir/docs/prds/prd-numbered/todo.md" <<'EOF'
# TODO

1. spec-001: First task
EOF
  cat > "$repo_dir/docs/prds/prd-numbered/dependencies.md" <<'EOF'
# Dependencies
EOF
  cat > "$repo_dir/docs/prds/prd-numbered/specifications/spec-001-test.md" <<'EOF'
# Spec
EOF

  local output
  output="$(run_orchestrator "$repo_dir")"
  assert_contains "$output" "[incomplete] prd-numbered" "Numbered todo items should not count as executable tasks"
  assert_contains "$output" "todo.md has no tasks (but pending specs exist)" "Numbered todo items should produce the missing tasks reason"
}

test_done_prd_is_detected() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"

  mkdir -p "$repo_dir/docs/prds/prd-done/specifications"
  cat > "$repo_dir/docs/prds/prd-done/prd.md" <<'EOF'
# Done PRD

## Branch

`ralph/done`
EOF
  cat > "$repo_dir/docs/prds/prd-done/progress.md" <<'EOF'
# Progress

| Specification | Title | Status | Completed On | Notes |
|---------------|-------|--------|--------------|-------|
| spec-001-test | Test | done | 2026-03-07 | |
EOF
  cat > "$repo_dir/docs/prds/prd-done/todo.md" <<'EOF'
# TODO
EOF
  cat > "$repo_dir/docs/prds/prd-done/dependencies.md" <<'EOF'
# Dependencies
EOF
  cat > "$repo_dir/docs/prds/prd-done/specifications/spec-001-test.md" <<'EOF'
# Spec
EOF

  local output
  output="$(run_orchestrator "$repo_dir")"
  assert_contains "$output" "[done]       prd-done" "Completed PRD should be marked done"
  assert_contains "$output" "Ready: 0  Incomplete: 0  Done: 1" "Done PRD should not be executed"
}

test_malformed_progress_is_incomplete
test_mismatched_progress_count_is_incomplete
test_duplicate_progress_rows_are_incomplete
test_invalid_branch_name_is_incomplete
test_ready_prd_is_detected
test_stale_lock_is_ignored
test_numbered_todo_is_incomplete
test_done_prd_is_detected
