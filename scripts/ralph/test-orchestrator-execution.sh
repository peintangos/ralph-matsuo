#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/ralph/test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

setup_orchestrator_repo() {
  local repo_dir="$1"

  setup_repo "$repo_dir" orchestrator.sh prd-helpers.sh
}

create_ready_prd() {
  local repo_dir="$1"
  local slug="$2"
  local branch="$3"

  mkdir -p "$repo_dir/docs/prds/prd-$slug/specifications"
  cat > "$repo_dir/docs/prds/prd-$slug/prd.md" <<EOF
# ${slug} PRD

## Branch

\`${branch}\`
EOF
  cat > "$repo_dir/docs/prds/prd-$slug/progress.md" <<'EOF'
# Progress

| Specification | Title | Status | Completed On | Notes |
|---------------|-------|--------|--------------|-------|
| spec-001-test | Test | pending | | |
EOF
  cat > "$repo_dir/docs/prds/prd-$slug/todo.md" <<'EOF'
# TODO

- [ ] spec-001: First task
EOF
  cat > "$repo_dir/docs/prds/prd-$slug/dependencies.md" <<'EOF'
# Dependencies
EOF
  cat > "$repo_dir/docs/prds/prd-$slug/specifications/spec-001-test.md" <<'EOF'
# Spec
EOF
}

create_git_stub() {
  local stub_dir="$1"

  create_stub_command "$stub_dir" git <<'EOF'
#!/bin/bash
set -euo pipefail

branch_in_list() {
  local branch_name="$1"
  local branch_list="${2:-}"

  grep -Fxq "$branch_name" <<< "$branch_list"
}

if [[ -n "${TEST_GIT_LOG:-}" ]]; then
  printf '%s\n' "$*" >> "$TEST_GIT_LOG"
fi

if [[ "${1:-}" == "rev-parse" && "${2:-}" == "--abbrev-ref" && "${3:-}" == "HEAD" ]]; then
  cat "${TEST_GIT_BRANCH_FILE:?}"
  exit 0
fi

if [[ "${1:-}" == "show-ref" && "${2:-}" == "--verify" && "${3:-}" == "--quiet" ]]; then
  ref_name="${4:-}"
  case "$ref_name" in
    refs/heads/*)
      branch_name="${ref_name#refs/heads/}"
      if branch_in_list "$branch_name" "${TEST_GIT_LOCAL_BRANCHES:-}"; then
        exit 0
      fi
      exit 1
      ;;
    refs/remotes/origin/*)
      branch_name="${ref_name#refs/remotes/origin/}"
      if branch_in_list "$branch_name" "${TEST_GIT_REMOTE_BRANCHES:-}"; then
        exit 0
      fi
      exit 1
      ;;
  esac
fi

if [[ "${1:-}" == "checkout" ]]; then
  if [[ "${2:-}" == "--track" && "${3:-}" == "-b" ]]; then
    printf '%s\n' "${4:?}" > "${TEST_GIT_BRANCH_FILE:?}"
  elif [[ "${2:-}" == "-b" ]]; then
    printf '%s\n' "${3:?}" > "${TEST_GIT_BRANCH_FILE:?}"
  else
    printf '%s\n' "${2:?}" > "${TEST_GIT_BRANCH_FILE:?}"
  fi
  exit 0
fi

echo "git stub received unexpected args: $*" >&2
exit 1
EOF
}

create_ralph_stub() {
  local repo_dir="$1"

  cat > "$repo_dir/scripts/ralph/ralph.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

tool=""
prd_dir=""
max_iterations=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)
      tool="$2"
      shift 2
      ;;
    --prd)
      prd_dir="$2"
      shift 2
      ;;
    *)
      max_iterations="$1"
      shift
      ;;
  esac
done

{
  printf 'tool=%s\n' "$tool"
  printf 'prd=%s\n' "$prd_dir"
  printf 'max_iterations=%s\n' "$max_iterations"
} >> "${TEST_RALPH_LOG:?}"

printf '%s\n' "${TEST_RALPH_OUTPUT:-stub ralph run}"
exit "${TEST_RALPH_EXIT_CODE:-0}"
EOF

  chmod +x "$repo_dir/scripts/ralph/ralph.sh"
}

test_no_actionable_prds_exit_cleanly() {
  local repo_dir output status
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_orchestrator_repo "$repo_dir"

  capture_repo_command output status "$repo_dir" "$BASH" scripts/ralph/orchestrator.sh --dry-run
  assert_exit_code 0 "$status" "No-action dry-run should exit successfully"
  assert_contains "$output" "No actionable PRDs found. Exiting." "No-action message should be reported"
}

test_first_ready_prd_runs_and_switches_branch() {
  local repo_dir stub_dir branch_file git_log ralph_log output status ralph_output git_output
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_orchestrator_repo "$repo_dir"
  create_ready_prd "$repo_dir" alpha "ralph/alpha"
  create_ready_prd "$repo_dir" beta "ralph/beta"
  create_ralph_stub "$repo_dir"

  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"
  branch_file="$repo_dir/current-branch.txt"
  git_log="$repo_dir/git.log"
  ralph_log="$repo_dir/ralph.log"
  printf 'main\n' > "$branch_file"
  : > "$git_log"
  : > "$ralph_log"

  create_git_stub "$stub_dir"

  capture_repo_command output status "$repo_dir" env \
    PATH="$stub_dir:$PATH" \
    TEST_GIT_BRANCH_FILE="$branch_file" \
    TEST_GIT_LOCAL_BRANCHES=$'ralph/alpha\nralph/beta' \
    TEST_GIT_LOG="$git_log" \
    TEST_RALPH_LOG="$ralph_log" \
    TEST_RALPH_EXIT_CODE=0 \
    "$BASH" scripts/ralph/orchestrator.sh --max-iterations 7

  ralph_output="$(cat "$ralph_log")"
  git_output="$(cat "$git_log")"

  assert_exit_code 0 "$status" "Successful orchestrator execution should exit successfully"
  assert_contains "$output" "PRD: prd-alpha" "The first ready PRD should be selected"
  assert_contains "$output" "Branch: ralph/alpha" "The selected PRD branch should be reported"
  assert_contains "$output" "Switching branch: main -> ralph/alpha" "Branch switching should occur when needed"
  assert_contains "$output" "Starting ralph.sh (tool: claude)..." "orchestrator should start ralph.sh"
  assert_contains "$git_output" "checkout ralph/alpha" "git checkout should target the PRD branch"
  assert_contains "$ralph_output" "tool=claude" "orchestrator should invoke ralph.sh with the claude tool"
  assert_contains "$ralph_output" "prd=$repo_dir/docs/prds/prd-alpha" "orchestrator should pass the selected PRD path"
  assert_contains "$ralph_output" "max_iterations=7" "orchestrator should pass max iterations through to ralph.sh"
}

test_existing_branch_skips_checkout() {
  local repo_dir stub_dir branch_file git_log ralph_log output status git_output
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_orchestrator_repo "$repo_dir"
  create_ready_prd "$repo_dir" existing "ralph/existing"
  create_ralph_stub "$repo_dir"

  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"
  branch_file="$repo_dir/current-branch.txt"
  git_log="$repo_dir/git.log"
  ralph_log="$repo_dir/ralph.log"
  printf 'ralph/existing\n' > "$branch_file"
  : > "$git_log"
  : > "$ralph_log"

  create_git_stub "$stub_dir"

  capture_repo_command output status "$repo_dir" env \
    PATH="$stub_dir:$PATH" \
    TEST_GIT_BRANCH_FILE="$branch_file" \
    TEST_GIT_LOG="$git_log" \
    TEST_RALPH_LOG="$ralph_log" \
    TEST_RALPH_EXIT_CODE=0 \
    "$BASH" scripts/ralph/orchestrator.sh --max-iterations 4

  git_output="$(cat "$git_log")"

  assert_exit_code 0 "$status" "orchestrator should succeed when already on the target branch"
  assert_contains "$git_output" "rev-parse --abbrev-ref HEAD" "Current branch should be inspected"
  assert_not_contains "$git_output" "checkout" "git checkout should not run when already on the target branch"
  assert_not_contains "$output" "Switching branch:" "No branch switch message should be emitted"
}

test_remote_branch_creates_tracking_checkout() {
  local repo_dir stub_dir branch_file git_log ralph_log output status git_output
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_orchestrator_repo "$repo_dir"
  create_ready_prd "$repo_dir" remote "ralph/remote"
  create_ralph_stub "$repo_dir"

  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"
  branch_file="$repo_dir/current-branch.txt"
  git_log="$repo_dir/git.log"
  ralph_log="$repo_dir/ralph.log"
  printf 'main\n' > "$branch_file"
  : > "$git_log"
  : > "$ralph_log"

  create_git_stub "$stub_dir"

  capture_repo_command output status "$repo_dir" env \
    PATH="$stub_dir:$PATH" \
    TEST_GIT_BRANCH_FILE="$branch_file" \
    TEST_GIT_REMOTE_BRANCHES='ralph/remote' \
    TEST_GIT_LOG="$git_log" \
    TEST_RALPH_LOG="$ralph_log" \
    TEST_RALPH_EXIT_CODE=0 \
    "$BASH" scripts/ralph/orchestrator.sh --max-iterations 5

  git_output="$(cat "$git_log")"

  assert_exit_code 0 "$status" "orchestrator should create a tracking branch when only origin has the target branch"
  assert_contains "$output" "Creating local tracking branch from origin/ralph/remote" "Tracking branch creation should be reported"
  assert_contains "$git_output" "show-ref --verify --quiet refs/heads/ralph/remote" "Local branch existence should be checked first"
  assert_contains "$git_output" "show-ref --verify --quiet refs/remotes/origin/ralph/remote" "Remote branch existence should be checked when local branch is absent"
  assert_contains "$git_output" "checkout --track -b ralph/remote origin/ralph/remote" "Tracking checkout should be used for remote-only branches"
}

test_missing_branch_creates_new_branch_and_runs_ralph() {
  local repo_dir stub_dir branch_file git_log ralph_log output status git_output
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_orchestrator_repo "$repo_dir"
  create_ready_prd "$repo_dir" missing "ralph/missing"
  create_ralph_stub "$repo_dir"

  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"
  branch_file="$repo_dir/current-branch.txt"
  git_log="$repo_dir/git.log"
  ralph_log="$repo_dir/ralph.log"
  printf 'main\n' > "$branch_file"
  : > "$git_log"
  : > "$ralph_log"

  create_git_stub "$stub_dir"

  capture_repo_command output status "$repo_dir" env \
    PATH="$stub_dir:$PATH" \
    TEST_GIT_BRANCH_FILE="$branch_file" \
    TEST_GIT_LOG="$git_log" \
    TEST_RALPH_LOG="$ralph_log" \
    TEST_RALPH_EXIT_CODE=0 \
    "$BASH" scripts/ralph/orchestrator.sh --max-iterations 5

  git_output="$(cat "$git_log")"

  assert_exit_code 0 "$status" "orchestrator should create and use the target branch when it is missing everywhere"
  assert_contains "$output" "Creating new branch from current HEAD: ralph/missing" "Missing branches should be created from the current HEAD"
  assert_contains "$git_output" "show-ref --verify --quiet refs/heads/ralph/missing" "Missing local branch should be checked"
  assert_contains "$git_output" "show-ref --verify --quiet refs/remotes/origin/ralph/missing" "Missing remote branch should be checked"
  assert_contains "$git_output" "checkout -b ralph/missing" "orchestrator should create the missing branch from the current HEAD"
  assert_contains "$(cat "$ralph_log")" "tool=claude" "ralph.sh should run after the branch is created"
}

test_ralph_exit_code_is_propagated() {
  local repo_dir stub_dir branch_file git_log ralph_log output status ralph_output
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_orchestrator_repo "$repo_dir"
  create_ready_prd "$repo_dir" failing "ralph/failing"
  create_ralph_stub "$repo_dir"

  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"
  branch_file="$repo_dir/current-branch.txt"
  git_log="$repo_dir/git.log"
  ralph_log="$repo_dir/ralph.log"
  printf 'main\n' > "$branch_file"
  : > "$git_log"
  : > "$ralph_log"

  create_git_stub "$stub_dir"

  capture_repo_command output status "$repo_dir" env \
    PATH="$stub_dir:$PATH" \
    TEST_GIT_BRANCH_FILE="$branch_file" \
    TEST_GIT_LOCAL_BRANCHES='ralph/failing' \
    TEST_GIT_LOG="$git_log" \
    TEST_RALPH_LOG="$ralph_log" \
    TEST_RALPH_EXIT_CODE=9 \
    "$BASH" scripts/ralph/orchestrator.sh --max-iterations 3

  ralph_output="$(cat "$ralph_log")"

  assert_exit_code 9 "$status" "orchestrator should propagate ralph.sh failures"
  assert_contains "$ralph_output" "max_iterations=3" "Failure case should still call ralph.sh with the requested iteration limit"
}

test_no_actionable_prds_exit_cleanly
test_first_ready_prd_runs_and_switches_branch
test_existing_branch_skips_checkout
test_remote_branch_creates_tracking_checkout
test_missing_branch_creates_new_branch_and_runs_ralph
test_ralph_exit_code_is_propagated
