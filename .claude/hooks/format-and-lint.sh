#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then exit 0; fi
if [[ ! -f "$FILE_PATH" ]]; then exit 0; fi
if [[ "$FILE_PATH" == */node_modules/* ]]; then exit 0; fi
if [[ "$FILE_PATH" == */.git/* ]]; then exit 0; fi
if [[ "$FILE_PATH" == */dist/* ]]; then exit 0; fi
if [[ "$FILE_PATH" == */build/* ]]; then exit 0; fi
if [[ "$FILE_PATH" == */target/* ]]; then exit 0; fi
if [[ "$FILE_PATH" == */.next/* ]]; then exit 0; fi
if [[ "$FILE_PATH" == */.venv/* ]]; then exit 0; fi

CONFIG_FILE="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/hooks/project-commands.sh"

if [[ ! -f "$CONFIG_FILE" ]]; then exit 0; fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

run_configured_command() {
  local template="$1"

  if [[ -z "$template" ]]; then
    return 0
  fi

  local escaped_file
  printf -v escaped_file '%q' "$FILE_PATH"

  local command="$template"
  command="${command//\{file\}/$escaped_file}"

  bash -lc "$command" >/dev/null 2>&1 || true
}

run_configured_command "${POST_EDIT_FORMAT_CMD:-}"
run_configured_command "${POST_EDIT_LINT_FIX_CMD:-}"
