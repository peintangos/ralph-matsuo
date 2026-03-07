#!/bin/bash
# Extract PRD slug from issue body (GitHub Forms format) and validate format
# Usage: parse-issue-body.sh <issue_body_file> [repo_root]
# On success: outputs slug to GITHUB_OUTPUT
# On failure: outputs error to GITHUB_OUTPUT and exits with code 1

set -euo pipefail

ISSUE_BODY_FILE="${1:?Please specify the path to the issue body file}"
REPO_ROOT="${2:-.}"

# Extract slug from the ### PRD Slug section
slug=$(awk '
  $0 == "### PRD Slug" { found=1; next }
  found && /^### / { exit }
  found { print }
' "$ISSUE_BODY_FILE" | sed '/^[[:space:]]*$/d' | tr -d '[:space:]')

# --- Validation (format and duplicates only) ---
error=""

if [[ -z "$slug" ]]; then
  error="PRD slug is empty. Please enter a value using lowercase letters, numbers, and hyphens."
elif [[ ! "$slug" =~ ^[a-z][a-z0-9-]*$ ]]; then
  error="PRD slug '${slug}' has an invalid format. Must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
elif [[ -d "$REPO_ROOT/docs/prds/prd-${slug}" ]]; then
  error="PRD slug '${slug}' already exists (docs/prds/prd-${slug}/). Please use a different slug."
fi

if [[ -n "$error" ]]; then
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "valid=false" >> "$GITHUB_OUTPUT"
    echo "error=${error}" >> "$GITHUB_OUTPUT"
  fi
  echo "Error: $error"
  exit 1
fi

# Success
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "valid=true" >> "$GITHUB_OUTPUT"
  echo "slug=${slug}" >> "$GITHUB_OUTPUT"
fi

echo "Slug extracted successfully: ${slug}"
