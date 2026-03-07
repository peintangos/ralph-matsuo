#!/bin/bash
# Shared helpers for extracting metadata from PRD markdown files.

prd_md_path() {
  local prd_dir="$1"
  printf '%s\n' "${prd_dir%/}/prd.md"
}

get_prd_branch() {
  local prd_md
  prd_md="$(prd_md_path "$1")"

  if [[ ! -f "$prd_md" ]]; then
    return 0
  fi

  grep -A3 '^## Branch' "$prd_md" 2>/dev/null | grep -oE "\`[^\`]+\`" | tr -d '`' | head -1 || true
}

get_prd_title() {
  local prd_md
  prd_md="$(prd_md_path "$1")"

  if [[ ! -f "$prd_md" ]]; then
    return 0
  fi

  sed -n '1s/^# //p' "$prd_md"
}

branch_helper_log() {
  local prefix="${1:-}"
  shift || true
  printf '%s%s\n' "$prefix" "$*"
}

local_branch_exists() {
  local branch_name="$1"
  git show-ref --verify --quiet "refs/heads/$branch_name"
}

remote_branch_exists() {
  local branch_name="$1"
  local remote_name="${2:-origin}"
  git show-ref --verify --quiet "refs/remotes/$remote_name/$branch_name"
}

ensure_checked_out_branch() {
  local target_branch="$1"
  local log_prefix="${2:-}"
  local remote_name="${3:-origin}"
  local current_branch=""

  if [[ -z "$target_branch" ]]; then
    branch_helper_log "$log_prefix" "Error: Target branch is required."
    return 1
  fi

  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$current_branch" == "$target_branch" ]]; then
    branch_helper_log "$log_prefix" "Already on branch: $target_branch"
    return 0
  fi

  if local_branch_exists "$target_branch"; then
    branch_helper_log "$log_prefix" "Switching branch: $current_branch -> $target_branch"
    git checkout "$target_branch"
    return 0
  fi

  if remote_branch_exists "$target_branch" "$remote_name"; then
    branch_helper_log "$log_prefix" "Switching branch: $current_branch -> $target_branch"
    branch_helper_log "$log_prefix" "Creating local tracking branch from $remote_name/$target_branch"
    git checkout --track -b "$target_branch" "$remote_name/$target_branch"
    return 0
  fi

  branch_helper_log "$log_prefix" "Switching branch: $current_branch -> $target_branch"
  branch_helper_log "$log_prefix" "Creating new branch from current HEAD: $target_branch"
  git checkout -b "$target_branch"
  return 0
}
