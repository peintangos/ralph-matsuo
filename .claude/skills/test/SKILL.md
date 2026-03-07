---
name: test
description: "Run tests and return a summary. Test logs are contained within the forked context; only the summary is returned to the main context."
user_invocable: true
context: fork
allowed-tools: Bash, Read
---

# Test Execution

Run tests based on arguments and output only a results summary.

## Argument Interpretation

- No arguments or `all` -> Run both primary tests and E2E/integration tests when available
- `unit` -> Run only the fast or primary test command
- `e2e` -> Run only the E2E/integration command

## 1. Discover Test Commands

Read `ralph.toml` first if it exists, then `CLAUDE.md` and `docs/architecture.md`. Inspect common project files at the repo root only as needed (for example `Makefile`, `justfile`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, or other task-runner files).

Identify the best available commands for:

- fast or primary automated tests
- E2E or broader integration tests, if they exist separately

Prefer commands explicitly defined in `ralph.toml`. If the registry is missing or incomplete, prefer commands explicitly documented in project docs. Only then infer them from the repo's task runner or manifest files.

When `ralph.toml` exists, use:

- `test_primary` for fast or primary tests
- `test_integration` for E2E or broader integration tests

Command selection rules:

- For `unit`, run the fast or primary test command
- For `e2e`, run the E2E or broader integration command only
- For `all`, run all distinct discovered test commands
- If only a single general test command exists, use it for `unit` and `all`

If the requested command category does not exist, report it as `SKIPPED`.

## 2. Run Primary Tests (for unit / all)

Run the selected fast or primary test command.

- On success: Record test count and pass count
- On failure: Extract failed test names and error messages

## 3. Run E2E Tests (for e2e / all)

Run the selected E2E or broader integration command.

- On success: Record test count and pass count
- On failure: Extract failed test names and error messages

## 4. Output Summary

Output results in the following format. Do not output the full test log.

```
## Test Results

- Primary Tests: PASS (X passed) / FAIL (X passed / Y failed) / SKIPPED
- E2E / Integration Tests: PASS (X passed) / FAIL (X passed / Y failed) / SKIPPED

### Failure Details (failures only)
- `test name` — error message
```
