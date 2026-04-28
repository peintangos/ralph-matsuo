# Contributing

## Before You Open A Pull Request

Ralph Matsuo is a template and automation repository. Changes should preserve two properties:

- the repository remains adoptable as a starter for another codebase
- the built-in automation stays understandable for first-time users

For non-trivial changes, explain the user-facing effect in the pull request body and mention whether the change affects:

- interactive Claude workflows under `.claude/`
- headless execution under `scripts/ralph/`
- GitHub Actions automation under `.github/workflows/`
- public onboarding in `README.md`

## Development Setup

Recommended local prerequisites:

- `bash`
- `git`
- `mise`
- `pnpm`
- `jq`
- `rg` (recommended for local development)

Some workflows and examples also assume:

- `claude`
- `gh`

Those tools are not required for every documentation-only change, but they are part of the supported operating model.

## Validation

Run the full local validation suite before opening a pull request:

```bash
mise trust .mise.toml
mise install
pnpm run validate
```

Key commands:

- `pnpm test`: shell syntax checks for maintained scripts
- `pnpm run test:orchestrator`: regression tests for Ralph loop and orchestrator behavior
- `pnpm run test:repo-lint`: regression tests for repository policy checks
- `pnpm run lint:repo`: release-readiness checks for repository hygiene and OSS metadata

If you change GitHub Actions, also run workflow-specific checks if available in your environment.

## Editing Guidance

- Keep repository-facing documentation in English unless there is a strong reason not to.
- Prefer small, explicit shell scripts over clever one-liners.
- Preserve the PRD directory contract under `docs/prds/prd-{slug}/`.
- Do not add project-specific product logic to this template unless it clearly generalizes.
- When changing automation behavior, update the public documentation in the same pull request.

## Pull Request Expectations

Include:

- a concise summary of what changed
- validation results
- any assumptions, limitations, or follow-up work

If a change intentionally alters the public workflow or file contract, call that out explicitly.
