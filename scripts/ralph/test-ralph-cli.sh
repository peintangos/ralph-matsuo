#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/ralph/test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

setup_ralph_repo() {
  local repo_dir="$1"

  setup_repo "$repo_dir" ralph.sh CLAUDE.md
}

create_basic_prd() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/docs/prds/prd-basic"
  cat > "$repo_dir/docs/prds/prd-basic/prd.md" <<'EOF'
# Basic PRD
EOF
}

create_noop_sleep_stub() {
  local stub_dir="$1"

  create_stub_command "$stub_dir" sleep <<'EOF'
#!/bin/bash
exit 0
EOF
}

test_help_prints_usage() {
  local repo_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"

  capture_repo_command output status "$repo_dir" "$BASH" scripts/ralph/ralph.sh --help
  assert_exit_code 0 "$status" "Help should exit successfully"
  assert_contains "$output" "Usage: ./ralph.sh --tool claude --prd <prd_dir> [max_iterations]" "Help should describe usage"
}

test_invalid_tool_fails() {
  local repo_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"

  capture_repo_command output status "$repo_dir" "$BASH" scripts/ralph/ralph.sh --tool invalid
  assert_exit_code 1 "$status" "Invalid tool should fail"
  assert_contains "$output" "Error: Invalid tool 'invalid'. Must be 'claude'." "Invalid tool error should be reported"
}

test_missing_tool_in_path_fails() {
  local repo_dir stub_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"
  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"

  capture_repo_command output status "$repo_dir" env PATH="$stub_dir" "$BASH" scripts/ralph/ralph.sh --tool claude --prd docs/prds/prd-basic
  assert_exit_code 1 "$status" "Missing tool should fail"
  assert_contains "$output" "Error: Required tool 'claude' is not installed or not in PATH." "Missing tool error should be reported"
}

test_missing_prd_option_fails() {
  local repo_dir stub_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"
  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"

  create_stub_command "$stub_dir" claude <<'EOF'
#!/bin/bash
exit 0
EOF

  capture_repo_command output status "$repo_dir" env PATH="$stub_dir:$PATH" "$BASH" scripts/ralph/ralph.sh --tool claude
  assert_exit_code 1 "$status" "Missing PRD option should fail"
  assert_contains "$output" "Error: --prd option is required." "Missing PRD option should be reported"
}

test_missing_prd_directory_fails() {
  local repo_dir stub_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"
  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"

  create_stub_command "$stub_dir" claude <<'EOF'
#!/bin/bash
exit 0
EOF

  capture_repo_command output status "$repo_dir" env PATH="$stub_dir:$PATH" "$BASH" scripts/ralph/ralph.sh --tool claude --prd docs/prds/prd-missing
  assert_exit_code 1 "$status" "Missing PRD directory should fail"
  assert_contains "$output" "Error: PRD directory 'docs/prds/prd-missing' does not exist." "Missing PRD directory should be reported"
}

test_missing_prd_file_fails() {
  local repo_dir stub_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"
  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir" "$repo_dir/docs/prds/prd-empty"

  create_stub_command "$stub_dir" claude <<'EOF'
#!/bin/bash
exit 0
EOF

  capture_repo_command output status "$repo_dir" env PATH="$stub_dir:$PATH" "$BASH" scripts/ralph/ralph.sh --tool claude --prd docs/prds/prd-empty
  assert_exit_code 1 "$status" "Missing prd.md should fail"
  assert_contains "$output" "Error: prd.md not found in 'docs/prds/prd-empty'." "Missing prd.md should be reported"
}

test_claude_completion_exits_zero() {
  local repo_dir stub_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"
  create_basic_prd "$repo_dir"
  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"

  create_stub_command "$stub_dir" claude <<'EOF'
#!/bin/bash
printf '<promise>COMPLETE</promise>\n'
EOF

  capture_repo_command output status "$repo_dir" env PATH="$stub_dir:$PATH" "$BASH" scripts/ralph/ralph.sh --tool claude --prd docs/prds/prd-basic 3
  assert_exit_code 0 "$status" "Claude completion should succeed"
  assert_contains "$output" "Ralph completed all tasks!" "Completion signal should stop the loop"
  assert_contains "$output" "Completed at iteration 1 of 3" "Completion should happen on the first iteration"
}

test_amp_is_rejected() {
  local repo_dir stub_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"
  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"

  capture_repo_command output status "$repo_dir" env PATH="$stub_dir:$PATH" "$BASH" scripts/ralph/ralph.sh --tool amp
  assert_exit_code 1 "$status" "Amp should be rejected"
  assert_contains "$output" "Error: Invalid tool 'amp'. Must be 'claude'." "Amp should be reported as an invalid tool"
}

test_max_iterations_exit_code_is_two() {
  local repo_dir stub_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"
  create_basic_prd "$repo_dir"
  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"

  create_stub_command "$stub_dir" claude <<'EOF'
#!/bin/bash
printf 'working\n'
EOF
  create_noop_sleep_stub "$stub_dir"

  capture_repo_command output status "$repo_dir" env PATH="$stub_dir:$PATH" "$BASH" scripts/ralph/ralph.sh --tool claude --prd docs/prds/prd-basic 2
  assert_exit_code 2 "$status" "Max iterations should return exit code 2"
  assert_contains "$output" "Iteration 1 complete. Continuing..." "Non-complete iterations should continue"
  assert_contains "$output" "Ralph reached max iterations (2) with work still remaining." "Max iteration message should be reported"
}

test_agent_failure_is_propagated() {
  local repo_dir stub_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_ralph_repo "$repo_dir"
  create_basic_prd "$repo_dir"
  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"

  create_stub_command "$stub_dir" claude <<'EOF'
#!/bin/bash
printf 'boom\n'
exit 42
EOF

  capture_repo_command output status "$repo_dir" env PATH="$stub_dir:$PATH" "$BASH" scripts/ralph/ralph.sh --tool claude --prd docs/prds/prd-basic 3
  assert_exit_code 42 "$status" "Agent failures should propagate"
  assert_contains "$output" "Ralph failed: claude exited with status 42 during iteration 1." "Failure message should include the agent exit code"
}

test_help_prints_usage
test_invalid_tool_fails
test_missing_tool_in_path_fails
test_missing_prd_option_fails
test_missing_prd_directory_fails
test_missing_prd_file_fails
test_claude_completion_exits_zero
test_amp_is_rejected
test_max_iterations_exit_code_is_two
test_agent_failure_is_propagated
