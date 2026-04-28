#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
pnpm exec cdk destroy --force
