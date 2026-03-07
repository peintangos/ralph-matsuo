#!/bin/bash
set -euo pipefail

# Optional project bootstrap hook for GitHub Actions.
#
# Use this script to install project-specific dependencies or perform
# stack-specific setup before running Ralph. Keep it idempotent.
#
# Examples:
# - npm ci
# - pnpm install --frozen-lockfile
# - uv sync --frozen
# - pip install -r requirements.txt
# - cargo fetch
# - make bootstrap
#
# If your project needs no extra setup, leave this script as-is.

echo "No project-specific bootstrap configured. Skipping."
