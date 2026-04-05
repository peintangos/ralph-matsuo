#!/bin/bash
# PostToolUse hook: Remind to run /save-lessons after git push
#
# Bash ツール実行後、コマンドが git push を含んでいたら
# /save-lessons の実行をリマインドする。

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then exit 0; fi

# git push を含むコマンドのみ対象
if echo "$COMMAND" | grep -q 'git push'; then
  echo "git push を検出しました。/save-lessons を実行してセッションの教訓を保存してください。"
fi

exit 0
