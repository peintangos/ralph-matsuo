#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
npx cdk destroy --force
