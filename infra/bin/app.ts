#!/usr/bin/env node
import * as cdk from "aws-cdk-lib";
import { RunnerStack } from "../lib/runner-stack";

const app = new cdk.App();

new RunnerStack(app, "RalphRunnerStack", {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
  description: "Self-hosted GitHub Actions runner for Ralph with Claude Code OAuth",
});
