#!/bin/bash

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_repo() {
  local repo_dir="$1"
  shift

  mkdir -p "$repo_dir/scripts/ralph" "$repo_dir/docs/prds"

  local relative_path
  for relative_path in "$@"; do
    cp "$TEST_SCRIPT_DIR/$relative_path" "$repo_dir/scripts/ralph/"
  done
}

setup_git_repo() {
  local repo_dir="$1"
  local branch_name="${2:-main}"

  git -C "$repo_dir" init >/dev/null 2>&1
  git -C "$repo_dir" config user.name "Ralph Test"
  git -C "$repo_dir" config user.email "ralph-test@example.com"
  git -C "$repo_dir" checkout -b "$branch_name" >/dev/null 2>&1
  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "chore: initial" >/dev/null 2>&1
}

add_git_remote() {
  local repo_dir="$1"
  local remote_repo="$repo_dir/.git/ralph-test-remote.git"

  git init --bare "$remote_repo" >/dev/null 2>&1
  git -C "$repo_dir" remote add origin "$remote_repo"
}

setup_git_repo_with_upstream() {
  local repo_dir="$1"
  local branch_name="${2:-main}"

  setup_git_repo "$repo_dir" "$branch_name"
  add_git_remote "$repo_dir"
  git -C "$repo_dir" push -u origin "$branch_name" >/dev/null 2>&1
}

create_stub_command() {
  local bin_dir="$1"
  local command_name="$2"

  cat > "$bin_dir/$command_name"
  chmod +x "$bin_dir/$command_name"
}

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

assert_equals() {
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

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  assert_equals "$expected" "$actual" "$message"
}
