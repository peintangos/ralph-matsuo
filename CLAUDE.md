# CLAUDE.md

## Project Overview

Ralph Matsuo is a docs-first OSS template for Claude Code and Ralph Loop.

This repository contains:

- reusable planning documents under `docs/prds/`
- a canonical Ralph command registry in `ralph.toml`
- interactive Claude Code skills under `.claude/skills/`
- headless execution scripts under `scripts/ralph/`
- GitHub Actions that connect issue intake, planning documents, autonomous execution, and PR creation
- local validation scripts for repository policy and workflow regressions

### Core Principle

Planning updates documents. Execution reads documents.

The active PRD directory is the control plane for feature work. Ralph should work from explicit artifacts such as `prd.md`, `specifications/`, `dependencies.md`, `progress.md`, and `todo.md` rather than from ad-hoc instructions alone.

### Tech Stack

- Runtime: Bash and Node.js (tooling only)
- Languages: Markdown, Bash, YAML, TOML
- Package manager: npm
- Automation: Git, GitHub Actions, Claude Code CLI
- Validation entry points: `npm test`, `npm run test:doc-contracts`, `npm run test:orchestrator`, `npm run lint:repo`

### Project Command Registry

The canonical registry file is `ralph.toml`.

- `test_primary` - unit or primary repository tests
- `test_integration` - integration / E2E tests when they exist
- `build_check` - build verification
- `lint_check` - linting or static analysis
- `format_fix` - formatter (when configured)

Those role names are stable across repositories. The command strings stored in `ralph.toml` are repository-specific implementation details. This template repository intentionally leaves non-applicable roles as `N/A` until adopters replace them with real commands.

## Document System

### PRD Directory Structure

Each PRD is managed under `docs/prds/prd-{slug}/` with the following structure:

```text
docs/prds/prd-{slug}/
├── prd.md              # PRD body (requirements definition)
├── knowledge.md        # Reusable patterns and implementation notes
├── progress.md         # Specification-level progress tracking
├── todo.md             # Next executable tasks
├── dependencies.md     # Specification dependencies and implementation order
└── specifications/     # Feature specs in Gherkin format
    ├── spec-001-*.md
    ├── spec-002-*.md
    └── ...
```

Use `docs/prds/_template/` as the baseline when creating new PRDs.

### Other Documents

- `ralph.toml` — canonical Ralph command registry
- `docs/architecture.md` — system architecture and control flow
- `docs/roadmap.md` — repo-level direction and active PRDs
- `README.md` — public entry point

### File Roles

- **`prd.md`**: defines the delivery scope and target branch in `## Branch`
- **`knowledge.md`**: stores reusable patterns, integration notes, and non-obvious lessons; do not use it as a task diary
- **`progress.md`**: tracks specification status using the exact values `pending`, `in-progress`, or `done`, with the exact columns `Specification | Title | Status | Completed On | Notes` and one row per specification file
- **`todo.md`**: lists executable tasks in priority order using unchecked checkbox lines (`- [ ]`); each unchecked task should be small enough for one `/implement` run or one Ralph iteration
- **`dependencies.md`**: records dependency order between specifications
- **`specifications/`**: holds Gherkin-oriented specs with scenarios under `## Acceptance Criteria` and checkbox tasks under `## Implementation Steps`
- **`ralph.toml`**: maps Ralph command roles such as tests, build checks, lint checks, and format fixes to the repository's existing commands

## Workflow

### Session Start

1. Run `/catchup` to summarize current state
2. Read the target PRD's `todo.md`
3. Confirm the next task is explicit and executable

### Planning Phase (Documents Only)

Use the following skills or plan mode to update planning artifacts:

- `/prd-create` / `/prd-enhance`
- `/spec-create`
- `/roadmap-update`
- `/req-update`
- `/docs-review`

The output of planning is a PRD set with:

- clear scope in `prd.md`
- executable steps in `specifications/`
- dependency order in `dependencies.md`
- a prioritized next-task list in `todo.md`

No source code changes should happen in this phase.

### Interactive Execution

In interactive sessions, use `/implement` to complete one todo task at a time.

Expected cycle:

1. gather context from the related PRD and specification
2. implement the task and add or update tests
3. run `/test`
4. run `/build-check` if the repository defines build or lint commands
5. run `/code-review`
6. update `progress.md`, `specifications/`, `todo.md`, and `knowledge.md`
7. commit with `/commit-push`

### Autonomous Execution (Ralph Loop)

For headless execution, Ralph uses `scripts/ralph/CLAUDE.md` as the instruction source:

```bash
./scripts/ralph/ralph.sh --tool claude --prd docs/prds/prd-{slug} [max_iterations]
```

Ralph Loop works from the same planning artifacts as interactive mode, but executes without slash commands.

If the PRD branch named in `prd.md` does not exist yet, Ralph creates it from the current HEAD before starting work.

The orchestrator processes at most one ready PRD per invocation. If multiple PRDs are ready, it selects the first `docs/prds/prd-*` directory in shell sort order, runs that PRD, and exits so a later scheduled or manual run can re-evaluate the remaining PRDs from the repository default branch state.

Each iteration should:

1. pick one todo task
2. implement it and write tests
3. run the configured tests and validation commands
4. update planning documents
5. commit on the PRD branch

See `scripts/ralph/CLAUDE.md` for the exact headless workflow.

### Completion Expectations

When work changes behavior or development flow, update the relevant documents:

- target PRD files under `docs/prds/prd-{slug}/`
- `docs/architecture.md` when structure or control flow changes
- `docs/roadmap.md` when priorities or active tracks change
- `README.md` when public-facing usage, setup, or automation behavior changes
