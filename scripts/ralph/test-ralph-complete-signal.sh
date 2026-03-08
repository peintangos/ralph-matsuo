#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if grep -Fq "$needle" <<< "$haystack"; then
    echo "Assertion failed: $message" >&2
    echo "Did not expect to find: $needle" >&2
    echo "Output was:" >&2
    echo "$haystack" >&2
    exit 1
  fi
}

setup_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/scripts/ralph" "$repo_dir/docs/prds/prd-test"
  cp "$SCRIPT_DIR/ralph.sh" "$repo_dir/scripts/ralph/"
  cp "$SCRIPT_DIR/CLAUDE.md" "$repo_dir/scripts/ralph/"
  cat > "$repo_dir/docs/prds/prd-test/prd.md" <<'EOF'
# Test PRD

## Branch

`ralph/test`
EOF
}

setup_git_repo_with_upstream() {
  local repo_dir="$1"
  local remote_repo="$repo_dir/.git/ralph-test-remote.git"

  git -C "$repo_dir" init >/dev/null 2>&1
  git -C "$repo_dir" config user.name "Ralph Test"
  git -C "$repo_dir" config user.email "ralph-test@example.com"
  git -C "$repo_dir" checkout -b ralph/test >/dev/null 2>&1
  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "chore: initial" >/dev/null 2>&1
  git init --bare "$remote_repo" >/dev/null 2>&1
  git -C "$repo_dir" remote add origin "$remote_repo"
  git -C "$repo_dir" push -u origin ralph/test >/dev/null 2>&1
}

run_ralph() {
  local repo_dir="$1"
  local fake_output="$2"

  local fake_bin_dir
  fake_bin_dir="$(mktemp -d)"

  cat > "$fake_bin_dir/claude" <<'EOF'
#!/bin/bash
cat >/dev/null
cat "$FAKE_CLAUDE_OUTPUT_FILE"
EOF
  chmod +x "$fake_bin_dir/claude"

  local output_file
  output_file="$(mktemp)"
  printf '%s' "$fake_output" > "$output_file"

  local output
  local exit_code=0
  output="$(
    cd "$repo_dir" && \
    PATH="$fake_bin_dir:$PATH" \
    FAKE_CLAUDE_OUTPUT_FILE="$output_file" \
    bash scripts/ralph/ralph.sh --tool claude --prd docs/prds/prd-test 1 2>&1
  )" || exit_code=$?

  rm -f "$output_file"
  rm -rf "$fake_bin_dir"

  printf '%s\n%s' "$exit_code" "$output"
}

test_inline_complete_signal_does_not_finish() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"
  setup_git_repo_with_upstream "$repo_dir"

  local result
  result="$(run_ralph "$repo_dir" $'analysis...\n<promise>COMPLETE</promise> seen in explanation, not as final signal\n')"
  local exit_code
  local output
  exit_code="$(printf '%s\n' "$result" | sed -n '1p')"
  output="$(printf '%s\n' "$result" | sed '1d')"

  if [[ "$exit_code" -ne 2 ]]; then
    echo "Assertion failed: Inline sentinel should not mark the run complete" >&2
    echo "Expected exit code 2, got $exit_code" >&2
    echo "$output" >&2
    exit 1
  fi

  assert_not_contains "$output" "Ralph completed all tasks!" "Inline sentinel should not trigger completion"
  assert_contains "$output" "Ralph reached max iterations (1) with work still remaining." "Run should continue until max iterations"
}

test_final_complete_signal_finishes() {
  local repo_dir
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_repo "$repo_dir"
  setup_git_repo_with_upstream "$repo_dir"

  local result
  result="$(run_ralph "$repo_dir" $'work complete\n<promise>COMPLETE</promise>\n')"
  local exit_code
  local output
  exit_code="$(printf '%s\n' "$result" | sed -n '1p')"
  output="$(printf '%s\n' "$result" | sed '1d')"

  if [[ "$exit_code" -ne 0 ]]; then
    echo "Assertion failed: Final sentinel should mark the run complete" >&2
    echo "Expected exit code 0, got $exit_code" >&2
    echo "$output" >&2
    exit 1
  fi

  assert_contains "$output" "Ralph completed all tasks!" "Final sentinel should trigger completion"
  assert_contains "$output" "Completed at iteration 1 of 1" "Completion message should mention the iteration"
}

test_inline_complete_signal_does_not_finish
test_final_complete_signal_finishes
