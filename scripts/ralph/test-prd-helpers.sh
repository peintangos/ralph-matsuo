#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./scripts/ralph/test-helpers.sh
source "$SCRIPT_DIR/test-helpers.sh"

setup_helper_repo() {
  local repo_dir="$1"

  setup_repo "$repo_dir" prd-helpers.sh
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

run_checkout_helper() {
  local output_var="$1"
  local status_var="$2"
  local repo_dir="$3"
  local branch_name="$4"
  shift 4

  capture_repo_command "$output_var" "$status_var" "$repo_dir" env "$@" \
    "$BASH" -c "source scripts/ralph/prd-helpers.sh; ensure_checked_out_branch '$branch_name' '[helper] '"
}

test_remote_branch_creates_tracking_branch() {
  local repo_dir stub_dir branch_file git_log output status git_output
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_helper_repo "$repo_dir"

  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"
  branch_file="$repo_dir/current-branch.txt"
  git_log="$repo_dir/git.log"
  printf 'main\n' > "$branch_file"
  : > "$git_log"

  create_git_stub "$stub_dir"

  run_checkout_helper output status "$repo_dir" "ralph/remote" \
    PATH="$stub_dir:$PATH" \
    TEST_GIT_BRANCH_FILE="$branch_file" \
    TEST_GIT_REMOTE_BRANCHES='ralph/remote' \
    TEST_GIT_LOG="$git_log"

  git_output="$(cat "$git_log")"

  assert_exit_code 0 "$status" "Helper should succeed when the target branch only exists on origin"
  assert_contains "$output" "[helper] Creating local tracking branch from origin/ralph/remote" "Helper should report tracking branch creation"
  assert_contains "$git_output" "checkout --track -b ralph/remote origin/ralph/remote" "Helper should use tracking checkout for remote-only branches"
}

test_missing_branch_creates_from_current_head() {
  local repo_dir stub_dir branch_file git_log output status git_output
  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN
  setup_helper_repo "$repo_dir"

  stub_dir="$repo_dir/test-bin"
  mkdir -p "$stub_dir"
  branch_file="$repo_dir/current-branch.txt"
  git_log="$repo_dir/git.log"
  printf 'main\n' > "$branch_file"
  : > "$git_log"

  create_git_stub "$stub_dir"

  run_checkout_helper output status "$repo_dir" "ralph/missing" \
    PATH="$stub_dir:$PATH" \
    TEST_GIT_BRANCH_FILE="$branch_file" \
    TEST_GIT_LOG="$git_log"

  git_output="$(cat "$git_log")"

  assert_exit_code 0 "$status" "Helper should create the target branch when it does not exist"
  assert_contains "$output" "[helper] Creating new branch from current HEAD: ralph/missing" "Helper should report new branch creation"
  assert_contains "$git_output" "show-ref --verify --quiet refs/heads/ralph/missing" "Helper should check for a local branch"
  assert_contains "$git_output" "show-ref --verify --quiet refs/remotes/origin/ralph/missing" "Helper should check for a remote branch"
  assert_contains "$git_output" "checkout -b ralph/missing" "Helper should create a new branch from the current HEAD"
}

test_remote_branch_creates_tracking_branch
test_missing_branch_creates_from_current_head
