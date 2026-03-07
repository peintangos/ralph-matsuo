---
name: ralph-registry-setup
description: "Inspect the repository and interactively create or update ralph.toml so Ralph has canonical test, build, lint, and format commands without depending on a package manager"
user_invocable: true
argument-hint: "[optional notes about preferred task runners or constraints]"
---

# Ralph Command Registry Setup

Arguments: `$ARGUMENTS`

## Goal

Create or update `ralph.toml` as the canonical Ralph command registry for the current repository.

The registry should map Ralph command roles to the repository's existing commands. Keep the registry stack-agnostic: Ralph standardizes the role names, while each repository keeps its own task runner.

## Registry Roles

Use these keys:

- `test_primary`
- `test_integration`
- `build_check`
- `lint_check`
- `format_fix`

Use the literal string `"N/A"` when a role does not apply.

## Steps

### 1. Inspect Current State

Read these first:

- `ralph.toml` if it already exists
- `CLAUDE.md`
- `docs/architecture.md`

Then inspect common task-runner files only as needed, such as:

- `package.json`
- `Makefile`
- `justfile`
- `pyproject.toml`
- `Cargo.toml`
- `go.mod`
- `composer.json`
- repo-level shell scripts

### 2. Detect Candidate Commands

Find the best existing command for each Ralph role.

Selection rules:

- Prefer `ralph.toml` if it already contains a valid mapping
- Prefer documented repo-level wrappers over framework-specific subcommands when both exist
- Reuse existing commands instead of inventing new ones
- Do not assume a build or lint step exists just because a stack usually has one

### 3. Resolve Ambiguity Interactively

Ask the user only when a role is missing or multiple commands are plausible.

If `$ARGUMENTS` contains constraints such as "do not use npm as canonical", honor them by keeping the registry as the source of truth and treating npm, make, just, cargo, pytest, and similar tools as underlying implementations only.

### 4. Write The Registry

Update `ralph.toml` with the final mappings.

Rules:

- Preserve existing valid entries unless they conflict with the user's request
- Write shell command strings exactly as they should be executed
- Use `"N/A"` explicitly instead of leaving keys blank

### 5. Sync Project Docs

After updating the registry, make sure these files point to it as the source of truth:

- `CLAUDE.md`
- `docs/architecture.md`

If those docs already list concrete commands, rewrite them in terms of the registry roles and note the current underlying commands only as implementation details.

### 6. Report Back

Summarize:

- the final `ralph.toml` mappings
- any roles set to `"N/A"`
- any ambiguous areas the user may still want to refine later

## Notes

- Keep this skill focused on command registry setup only
- Do not set up CI, hooks, or unrelated project automation here
- Only introduce wrapper scripts when an existing command is too fragile or too complex to store directly in `ralph.toml`
