#!/bin/bash
# Ralph Orchestrator - Scans PRDs, determines status, and runs ralph.sh accordingly
# Usage: ./orchestrator.sh [--max-iterations N] [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PRDS_DIR="$REPO_ROOT/docs/prds"
MAX_ITERATIONS=10
DRY_RUN=false

# shellcheck source=./scripts/ralph/prd-helpers.sh
source "$SCRIPT_DIR/prd-helpers.sh"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --max-iterations=*)
      MAX_ITERATIONS="${1#*=}"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      echo "Usage: ./orchestrator.sh [--max-iterations N] [--dry-run]"
      echo ""
      echo "Options:"
      echo "  --max-iterations N   Max iterations for ralph.sh (default: 10)"
      echo "  --dry-run            Only check status, do not run ralph.sh"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Log helper
log() {
  echo "[orchestrator] $*"
}

# Count specification files without turning a missing directory into a shell error.
count_spec_files() {
  local prd_dir="$1"
  local spec_dir="$prd_dir/specifications"

  if [[ ! -d "$spec_dir" ]]; then
    printf '0\n'
    return 0
  fi

  find "$spec_dir" -name "spec-*.md" 2>/dev/null | wc -l | tr -d ' '
}

count_progress_spec_rows() {
  local prd_dir="$1"
  local progress_file="$prd_dir/progress.md"

  if [[ ! -f "$progress_file" ]]; then
    printf '0\n'
    return 0
  fi

  grep -cEi '^\|\s*spec-[^|]+\|[^|]*\|\s*(pending|in-progress|done)\s*\|' "$progress_file" 2>/dev/null || true
}

list_spec_files() {
  local prd_dir="$1"
  local spec_dir="$prd_dir/specifications"

  if [[ ! -d "$spec_dir" ]]; then
    return 0
  fi

  find "$spec_dir" -name "spec-*.md" -exec basename {} .md \; 2>/dev/null | sort
}

list_progress_spec_rows() {
  local prd_dir="$1"
  local progress_file="$prd_dir/progress.md"

  if [[ ! -f "$progress_file" ]]; then
    return 0
  fi

  awk -F'|' '
    /^\|[[:space:]]*spec-/ {
      spec = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", spec)
      if (spec != "") {
        print spec
      }
    }
  ' "$progress_file" | sort
}

join_lines_csv() {
  printf '%s\n' "$1" | awk '
    NF {
      if (count > 0) {
        printf ", "
      }
      printf "%s", $0
      count++
    }
  '
}

count_progress_spec_rows_by_status() {
  local prd_dir="$1"
  local status_regex="$2"
  local progress_file="$prd_dir/progress.md"

  if [[ ! -f "$progress_file" ]]; then
    printf '0\n'
    return 0
  fi

  grep -cEi "^\|\s*spec-[^|]+\|[^|]*\|\s*(${status_regex})\s*\|" "$progress_file" 2>/dev/null || true
}

count_invalid_progress_rows() {
  local prd_dir="$1"
  local progress_file="$prd_dir/progress.md"

  if [[ ! -f "$progress_file" ]]; then
    printf '0\n'
    return 0
  fi

  awk '
    BEGIN { count = 0 }
    /^\|[[:space:]]*spec-/ {
      if ($0 !~ /\|[[:space:]]*(pending|in-progress|done)[[:space:]]*\|/) {
        count++
      }
    }
    END { print count }
  ' "$progress_file"
}

# Global variable for incomplete reasons
PRD_STATUS=""
INCOMPLETE_REASONS=()

# Determine PRD status
# Args: PRD directory path
# Output: ready / incomplete / done
# Side effect: Stores status in PRD_STATUS and incomplete reasons in INCOMPLETE_REASONS
check_prd_status() {
  local prd_dir="$1"
  local prd_name
  prd_name="$(basename "$prd_dir")"
  PRD_STATUS=""
  INCOMPLETE_REASONS=()

  # Skip if prd.md doesn't exist
  if [[ ! -f "$prd_dir/prd.md" ]]; then
    INCOMPLETE_REASONS+=("prd.md does not exist")
    PRD_STATUS="incomplete"
    return 0
  fi

  # No ## Branch section or branch value in prd.md -> incomplete
  local prd_branch
  prd_branch="$(get_prd_branch "$prd_dir")"
  if ! grep -q '^## Branch' "$prd_dir/prd.md" 2>/dev/null; then
    INCOMPLETE_REASONS+=("prd.md has no '## Branch' section")
  elif [[ -z "$prd_branch" ]]; then
    INCOMPLETE_REASONS+=("prd.md has no valid branch name in the '## Branch' section")
  fi

  # specifications/ is empty or doesn't exist -> incomplete
  local spec_count
  spec_count="$(count_spec_files "$prd_dir")"
  if [[ "$spec_count" -eq 0 ]]; then
    INCOMPLETE_REASONS+=("specifications/ is empty")
  fi

  # progress.md doesn't exist or is empty -> incomplete
  if [[ ! -f "$prd_dir/progress.md" ]] || [[ ! -s "$prd_dir/progress.md" ]]; then
    INCOMPLETE_REASONS+=("progress.md does not exist or is empty")
  fi

  # progress.md must enumerate every specification with a valid status
  local progress_spec_count
  progress_spec_count="$(count_progress_spec_rows "$prd_dir")"
  if [[ "$progress_spec_count" -eq 0 ]]; then
    INCOMPLETE_REASONS+=("progress.md has no specification rows with valid status")
  elif [[ "$progress_spec_count" -ne "$spec_count" ]]; then
    INCOMPLETE_REASONS+=("progress.md spec count ($progress_spec_count) does not match specifications/ file count ($spec_count)")
  fi

  local invalid_progress_rows
  invalid_progress_rows="$(count_invalid_progress_rows "$prd_dir")"
  if [[ "$invalid_progress_rows" -gt 0 ]]; then
    INCOMPLETE_REASONS+=("progress.md has specification rows with invalid status values")
  fi

  local spec_rows=""
  local progress_rows=""
  local unique_progress_rows=""
  local duplicate_progress_specs=""
  local missing_progress_specs=""
  local unknown_progress_specs=""
  if [[ "$spec_count" -gt 0 ]]; then
    spec_rows="$(list_spec_files "$prd_dir")"
    progress_rows="$(list_progress_spec_rows "$prd_dir")"

    if [[ -n "$progress_rows" ]]; then
      unique_progress_rows="$(printf '%s\n' "$progress_rows" | sed '/^$/d' | uniq)"
      duplicate_progress_specs="$(printf '%s\n' "$progress_rows" | sed '/^$/d' | uniq -d)"
      missing_progress_specs="$(comm -23 \
        <(printf '%s\n' "$spec_rows" | sed '/^$/d') \
        <(printf '%s\n' "$unique_progress_rows"))"
      unknown_progress_specs="$(comm -13 \
        <(printf '%s\n' "$spec_rows" | sed '/^$/d') \
        <(printf '%s\n' "$unique_progress_rows"))"
    else
      missing_progress_specs="$(printf '%s\n' "$spec_rows" | sed '/^$/d')"
    fi

    if [[ -n "$duplicate_progress_specs" ]]; then
      INCOMPLETE_REASONS+=("progress.md has duplicate specification rows: $(join_lines_csv "$duplicate_progress_specs")")
    fi

    if [[ -n "$missing_progress_specs" ]]; then
      INCOMPLETE_REASONS+=("progress.md is missing specification rows for: $(join_lines_csv "$missing_progress_specs")")
    fi

    if [[ -n "$unknown_progress_specs" ]]; then
      INCOMPLETE_REASONS+=("progress.md references unknown specifications: $(join_lines_csv "$unknown_progress_specs")")
    fi
  fi

  # If any of the above apply, it's incomplete
  if [[ ${#INCOMPLETE_REASONS[@]} -gt 0 ]]; then
    PRD_STATUS="incomplete"
    return 0
  fi

  # Check if todo.md has tasks, using progress.md for further determination
  local has_todo_tasks=false
  if [[ -f "$prd_dir/todo.md" ]]; then
    # Only unchecked checkbox tasks are executable input for Ralph.
    if grep -qE '^\s*-\s*\[[ ]\]' "$prd_dir/todo.md" 2>/dev/null; then
      has_todo_tasks=true
    fi
  fi

  # Check completion status in progress.md
  local pending_count
  local in_progress_count
  local done_count
  local active_spec_count
  pending_count="$(count_progress_spec_rows_by_status "$prd_dir" 'pending')"
  in_progress_count="$(count_progress_spec_rows_by_status "$prd_dir" 'in-progress')"
  done_count="$(count_progress_spec_rows_by_status "$prd_dir" 'done')"
  active_spec_count=$((pending_count + in_progress_count))

  # Status determination
  if [[ "$active_spec_count" -eq 0 && "$done_count" -eq "$spec_count" && "$has_todo_tasks" == "false" ]]; then
    # All specs done + no todo tasks -> done
    PRD_STATUS="done"
    return 0
  fi

  if [[ "$has_todo_tasks" == "true" && "$active_spec_count" -gt 0 ]]; then
    # Specs exist + todo has tasks + progress has pending/in-progress -> ready
    PRD_STATUS="ready"
    return 0
  fi

  if [[ "$active_spec_count" -gt 0 && "$has_todo_tasks" == "false" ]]; then
    # Pending specs exist but no todo tasks -> incomplete (needs todo creation)
    INCOMPLETE_REASONS+=("todo.md has no tasks (but pending specs exist)")
    PRD_STATUS="incomplete"
    return 0
  fi

  if [[ "$has_todo_tasks" == "true" && "$active_spec_count" -eq 0 ]]; then
    INCOMPLETE_REASONS+=("todo.md still has tasks but progress.md shows all specifications as done")
    PRD_STATUS="incomplete"
    return 0
  fi

  # Other cases are incomplete
  INCOMPLETE_REASONS+=("todo.md has no tasks, or inconsistency with progress.md")
  PRD_STATUS="incomplete"
  return 0
}

# Check PRD warnings (log output only)
# Args: PRD directory path
check_prd_warnings() {
  local prd_dir="$1"
  local prd_name
  prd_name="$(basename "$prd_dir")"

  # dependencies.md doesn't exist -> warn
  if [[ ! -f "$prd_dir/dependencies.md" ]]; then
    log "  [warn] $prd_name: dependencies.md does not exist"
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
      echo "::warning::$prd_name: dependencies.md does not exist"
    fi
  fi
}

# Create GitHub issue for incomplete PRDs
# Args: PRD name, incomplete reasons (variadic)
create_incomplete_issue() {
  local prd_name="$1"
  shift
  local reasons=("$@")

  if [[ -z "${GITHUB_ACTIONS:-}" ]]; then
    return 0
  fi

  # Check if gh command is available
  if ! command -v gh &>/dev/null; then
    log "  gh command not available, skipping issue creation"
    return 0
  fi

  if ! gh repo view >/dev/null 2>&1; then
    log "  gh repository context or authentication is unavailable, skipping issue creation"
    return 0
  fi

  local label="incomplete-prd"
  local title="Incomplete PRD: ${prd_name} — specifications or todo creation needed"

  # Create label if it doesn't exist
  if ! gh label list --search "$label" --json name -q '.[].name' 2>/dev/null | grep -qF "$label"; then
    gh label create "$label" --color "FBCA04" --description "PRD structure is incomplete and needs manual attention" 2>/dev/null || true
  fi

  # Check for existing open issue with same PRD name + label (prevent duplicates)
  local existing
  existing="$(gh issue list --label "$label" --state open --search "Incomplete PRD: ${prd_name}" --json number -q '.[].number' 2>/dev/null | head -1 || true)"
  if [[ -n "$existing" ]]; then
    log "  Existing issue #$existing found, skipping issue creation: $prd_name"
    return 0
  fi

  # Build issue body
  local body
  body="## Detected Issues"$'\n\n'
  for reason in "${reasons[@]}"; do
    body+="- [ ] ${reason}"$'\n'
  done
  body+=$'\n'"## Required Actions"$'\n\n'
  body+="Please resolve the issues above. The following skills may help:"$'\n\n'
  body+="- \`/spec-create\` — Create specifications"$'\n'
  body+="- \`/prd-enhance\` — Enhance and refine PRDs"$'\n'

  # Create issue
  if gh issue create --title "$title" --label "$label" --body "$body" 2>/dev/null; then
    log "  Issue created: $prd_name"
  else
    log "  Failed to create issue: $prd_name"
  fi
}

# Main
main() {
  log "PRD scan started: $PRDS_DIR"

  if [[ ! -d "$PRDS_DIR" ]]; then
    log "PRD directory does not exist: $PRDS_DIR"
    exit 0
  fi

  local ready_prds=()
  local incomplete_prds=()
  local incomplete_reason_blobs=()
  local done_prds=()

  # Determine status of each PRD
  for prd_dir in "$PRDS_DIR"/prd-*/; do
    [[ -d "$prd_dir" ]] || continue
    local prd_name
    prd_name="$(basename "$prd_dir")"
    local status
    check_prd_status "$prd_dir"
    status="$PRD_STATUS"

    case "$status" in
      ready)
        ready_prds+=("$prd_dir")
        log "  [ready]      $prd_name"
        check_prd_warnings "$prd_dir"
        ;;
      incomplete)
        incomplete_prds+=("$prd_dir")
        incomplete_reason_blobs+=("$(printf '%s\n' "${INCOMPLETE_REASONS[@]}")")
        log "  [incomplete] $prd_name"
        check_prd_warnings "$prd_dir"
        ;;
      done)
        done_prds+=("$prd_dir")
        log "  [done]       $prd_name"
        ;;
    esac
  done

  echo ""
  log "=== Scan Results ==="
  log "Ready: ${#ready_prds[@]}  Incomplete: ${#incomplete_prds[@]}  Done: ${#done_prds[@]}"

  # Notify and create issues for incomplete PRDs
  if [[ ${#incomplete_prds[@]} -gt 0 ]]; then
    echo ""
    log "=== Incomplete PRDs (manual action required) ==="
    local idx
    for idx in "${!incomplete_prds[@]}"; do
      local prd_dir="${incomplete_prds[$idx]}"
      local prd_name
      local reason_blob
      local reason
      local reasons=()
      prd_name="$(basename "$prd_dir")"
      reason_blob="${incomplete_reason_blobs[$idx]}"

      while IFS= read -r reason; do
        [[ -n "$reason" ]] || continue
        reasons+=("$reason")
      done <<< "$reason_blob"

      # Log reasons
      for reason in "${reasons[@]}"; do
        log "  - $prd_name: $reason"
      done

      # Output warning annotations in GitHub Actions
      if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::warning::Incomplete PRD: $prd_name — specifications or todo creation needed"
      fi

      # Create issue
      if [[ ${#reasons[@]} -gt 0 ]]; then
        create_incomplete_issue "$prd_name" "${reasons[@]}"
      fi
    done
  fi

  # Exit if no ready PRDs
  if [[ ${#ready_prds[@]} -eq 0 ]]; then
    log "No actionable PRDs found. Exiting."
    exit 0
  fi

  # Select and run the first ready PRD
  local target_prd="${ready_prds[0]}"
  local target_name
  target_name="$(basename "$target_prd")"
  local target_branch
  target_branch=$(get_prd_branch "$target_prd")

  echo ""
  log "=== Execution Target ==="
  log "PRD: $target_name"
  log "Branch: ${target_branch:-(not specified)}"
  log "Max iterations: $MAX_ITERATIONS"

  if [[ "$DRY_RUN" == "true" ]]; then
    log "[dry-run] Skipping ralph.sh execution"
    exit 0
  fi

  # Switch branch
  if [[ -n "$target_branch" ]]; then
    if ! ensure_checked_out_branch "$target_branch" "[orchestrator] "; then
      exit 1
    fi
  fi

  log "Starting ralph.sh..."
  "$SCRIPT_DIR/ralph.sh" --tool claude --prd "$target_prd" "$MAX_ITERATIONS"
  local exit_code=$?

  exit $exit_code
}

main "$@"
