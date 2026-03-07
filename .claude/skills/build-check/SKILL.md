---
name: build-check
description: "Run build and lint checks, returning only a summary. Build logs are contained within the forked context; only the summary is returned to the main context."
user_invocable: true
context: fork
allowed-tools: Bash, Read
---

# Build & Lint Check

Follow these steps to run build and lint checks, outputting only a results summary.

> **Note**: Do not use `run_in_background` with the Bash tool.
> Run commands directly (foreground) with timeout control.
> No need to check processes with ps or grep.

## 1. Discover Validation Commands

Read `ralph.toml` first if it exists, then `CLAUDE.md` and `docs/architecture.md`. Inspect common project files at the repo root only as needed (for example `Makefile`, `justfile`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`, or other task-runner files).

Determine the canonical commands for:

- build or compile verification
- lint or static analysis

Prefer commands explicitly defined in `ralph.toml`. If the registry is missing or incomplete, prefer commands explicitly documented in project docs. Only then infer them from the repo's task runner or manifest files.

When `ralph.toml` exists, use:

- `build_check` for build or compile verification
- `lint_check` for lint or static analysis

Prefer repo-level wrappers such as `make`, `just`, or documented scripts over framework-specific subcommands when both exist.

If neither check is defined or applicable, report "No build or lint commands defined" and exit.

## 2. Run Build

If a build command exists, run it with a reasonable timeout (for example `timeout 300` when available).

- On success: Record build success
- On failure: Extract only **file name, line number, and error message** from the error output

## 3. Run Lint

If a lint or static-analysis command exists, run it with a reasonable timeout.

- On success: Record lint success
- On failure: Extract only **file name, line number, and error message** from the error output

## 4. Output Summary

Output results in the following format. Do not output the full build log.

```
## Build & Lint Check Results

- Build: PASS / FAIL / SKIPPED
- Lint: PASS / FAIL / SKIPPED

### Error Details (failures only)
- `filename:line` — error message
- `filename:line` — error message
```
