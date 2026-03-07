#!/bin/bash
# PreToolUse hook: Default docs-first guardrail before source code changes
#
# Before Edit/Write on files under src/ or test/,
# check if there are uncommitted changes in docs/.
# Block (exit 2) if no documentation changes exist.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then exit 0; fi

# Only applies to source code (src/ or test/)
if [[ ! "$FILE_PATH" =~ /(src|test)/ ]]; then exit 0; fi

# OK if there are uncommitted changes (unstaged + staged + untracked) in docs/
cd "$CLAUDE_PROJECT_DIR" || exit 0
CHANGES=$(git status --porcelain docs/ 2>/dev/null)

if [ -n "$CHANGES" ]; then
  exit 0
fi

echo "Please update the target PRD's todo.md before modifying source code." >&2
exit 2
