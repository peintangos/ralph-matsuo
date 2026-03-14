#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
npm install
npx cdk deploy --require-approval never --outputs-file cdk-outputs.json
