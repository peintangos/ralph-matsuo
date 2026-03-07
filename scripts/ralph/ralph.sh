#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop (Specification-Driven)
# Usage: ./ralph.sh --tool claude --prd <prd_dir> [max_iterations]
#
# Exit codes:
#   0 = all tasks complete
#   2 = max iterations reached with work still remaining
#   1+ = configuration or runtime error

set -euo pipefail

# Parse arguments
TOOL="claude"
MAX_ITERATIONS=10
MAX_ITERATIONS_EXIT_CODE=2
PRD_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    --prd)
      PRD_DIR="$2"
      shift 2
      ;;
    --prd=*)
      PRD_DIR="${1#*=}"
      shift
      ;;
    --help|-h)
      echo "Usage: ./ralph.sh --tool claude --prd <prd_dir> [max_iterations]"
      echo ""
      echo "Options:"
      echo "  --tool <claude>       AI tool to use (default: claude)"
      echo "  --prd <prd_dir>       Path to PRD directory (required)"
      echo "  max_iterations        Maximum number of iterations (default: 10)"
      echo ""
      echo "Example:"
      echo "  ./ralph.sh --tool claude --prd docs/prds/prd-my-feature 5"
      exit 0
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Validate tool choice
if [[ "$TOOL" != "claude" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'claude'."
  exit 1
fi

if ! command -v "$TOOL" >/dev/null 2>&1; then
  echo "Error: Required tool '$TOOL' is not installed or not in PATH."
  exit 1
fi

# Validate PRD directory
if [[ -z "$PRD_DIR" ]]; then
  echo "Error: --prd option is required."
  echo "Usage: ./ralph.sh --tool claude --prd <prd_dir> [max_iterations]"
  exit 1
fi

if [[ ! -d "$PRD_DIR" ]]; then
  echo "Error: PRD directory '$PRD_DIR' does not exist."
  exit 1
fi

if [[ ! -f "$PRD_DIR/prd.md" ]]; then
  echo "Error: prd.md not found in '$PRD_DIR'."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_TEMPLATE="$(<"$SCRIPT_DIR/CLAUDE.md")"
PROMPT="${PROMPT_TEMPLATE//\{\{PRD_DIR\}\}/$PRD_DIR}"
RUN_OUTPUT=""

is_complete_output() {
  local output="$1"
  local last_non_empty_line

  last_non_empty_line="$(printf '%s\n' "$output" | awk 'NF { last = $0 } END { print last }')"
  [[ "$last_non_empty_line" == "<promise>COMPLETE</promise>" ]]
}

run_agent() {
  local prompt="$1"
  local tmp_output
  local exit_code=0

  tmp_output="$(mktemp)"

  if printf '%s\n' "$prompt" | claude --dangerously-skip-permissions --print 2>&1 | tee "$tmp_output" >&2; then
    exit_code=0
  else
    exit_code=$?
  fi

  RUN_OUTPUT="$(cat "$tmp_output")"
  rm -f "$tmp_output"

  return "$exit_code"
}

echo "Starting Ralph - Tool: $TOOL - PRD: $PRD_DIR - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo ""
  echo "==============================================================="
  echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "  PRD: $PRD_DIR"
  echo "==============================================================="

  # Run the selected tool
  if run_agent "$PROMPT"; then
    agent_exit=0
  else
    agent_exit=$?
  fi
  OUTPUT="$RUN_OUTPUT"

  if [[ "$agent_exit" -ne 0 ]]; then
    echo ""
    echo "Ralph failed: $TOOL exited with status $agent_exit during iteration $i." >&2
    exit "$agent_exit"
  fi

  # Check for completion signal
  if is_complete_output "$OUTPUT"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) with work still remaining."
echo "Check $PRD_DIR/progress.md for status and rerun Ralph to continue."
exit "$MAX_ITERATIONS_EXIT_CODE"
