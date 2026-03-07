---
name: test-guidelines
description: Review testing strategy and guidelines
---

## Task

When writing or reviewing tests, apply this project's testing strategy and guidelines.

## Testing Strategy

### Automated Tests

#### Fast Tests
- Write tests for the smallest practical unit in your project: function, module, service, CLI command, API handler, component, or equivalent
- Prefer deterministic tests with minimal external setup
- Follow the existing placement and naming conventions already used in the repo or documented in `CLAUDE.md` / `docs/architecture.md`

#### Integration or E2E Tests
- Add broader tests only where behavior crosses process, network, storage, browser, or framework boundaries
- Use the project's existing integration or E2E framework if one exists
- Follow the existing placement and execution conventions documented in the repo
- If these tests require a separate runtime or server, document that setup in the relevant spec or task notes

## Rules

- Follow documented project conventions first; if none exist, follow the dominant pattern already present in the codebase
- Prefer the fastest test level that gives reliable signal
- Keep tests close to the behavior they validate, unless the repo has a central test layout
- Do not assume a JavaScript-specific toolchain or directory layout
