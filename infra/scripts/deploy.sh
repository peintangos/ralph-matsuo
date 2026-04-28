#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm install --frozen-lockfile
pnpm exec cdk deploy --require-approval never --outputs-file cdk-outputs.json
