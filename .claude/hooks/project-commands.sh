#!/bin/bash

# Optional project-specific commands for the post-edit hook.
# Use `{file}` as a placeholder for the edited file path.
#
# Example shape:
# POST_EDIT_FORMAT_CMD="[your formatter command] {file}"
# POST_EDIT_LINT_FIX_CMD="[your lint auto-fix command] {file}"
#
# Leave values empty if your project does not use automatic post-edit commands.

# shellcheck disable=SC2034
POST_EDIT_FORMAT_CMD=""
# shellcheck disable=SC2034
POST_EDIT_LINT_FIX_CMD=""
