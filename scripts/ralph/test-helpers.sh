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
