---
name: setup-ralph-matsuo
description: "Interactively adapt the Ralph Matsuo template to the current repository by filling project docs, rules, roadmap, and ralph.toml in one setup pass"
user_invocable: true
argument-hint: "[optional notes about your stack, workflow, or automation constraints]"
---

# Setup Ralph Matsuo

Arguments: `$ARGUMENTS`

## Goal

Get the current repository from "template copied" to "ready for the first PRD" in one guided setup pass.

## Use This When

- the repository still contains Ralph template wording
- `CLAUDE.md`, `docs/architecture.md`, or `docs/roadmap.md` are not project-specific yet
- you want one interactive setup flow instead of editing each file manually

## Files To Review First

Read these first:

- `README.md`
- `CLAUDE.md`
- `docs/architecture.md`
- `docs/roadmap.md`
- `ralph.toml`
- `.claude/rules/*.md`

Inspect root task-runner or manifest files only as needed, such as:

- `package.json`
- `Makefile`
- `justfile`
- `pyproject.toml`
- `Cargo.toml`
- `go.mod`
- repo-level shell scripts

## Workflow

### 1. Confirm The Adoption Scope

Assume the repository already contains the Ralph template structure unless the files clearly show otherwise.

If the user wants the bundled GitHub automation, prefer copying these template units as-is:

- `.claude/`
- `scripts/ralph/`
- `docs/prds/_template/`
- `.github/`
- `CLAUDE.md`
- `ralph.toml`

If `.github/` is missing, ask whether GitHub automation should be enabled now or deferred.

### 2. Gather Project-Specific Inputs Interactively

Ask concise questions and only ask what cannot be inferred from the repo.

Start by asking which language the user wants for ongoing conversation.

Persist that choice in `.claude/rules/language.md` before asking the rest of the setup questions.

After the user selects the language, continue the rest of the setup conversation, summaries, and next-step guidance in that language.

Cover these areas:

- preferred conversation language for this repository setup and future Claude interactions
- project name and one-paragraph purpose
- primary stack and runtime surfaces
- unit or primary test framework, whether it is already installed, and which command should back `test_primary`
- whether the repository's requirements call for integration or E2E coverage, and if so which framework and command should back `test_integration`
- any missing test dependencies or setup steps that must be completed before Ralph should implement feature work autonomously
- command registry choices for tests, integration tests, build, lint, and format
- any extra repo-specific git and docs conventions that differ from the template
- current roadmap focus or active workstream

If `$ARGUMENTS` already contains useful constraints, reuse them instead of re-asking.

### 3. Update The Core Docs

Rewrite template wording so it matches the current repository:

- `CLAUDE.md`
- `docs/architecture.md`
- `docs/roadmap.md`

Rules:

- keep `ralph.toml` as the canonical command registry
- describe command roles in a stack-agnostic way
- treat concrete commands as repo-specific implementation details
- preserve any valid existing project-specific content

### 4. Update Rules Only Where Needed

Review `.claude/rules/*.md` and change only the files that need repo-specific conventions.

Do not rewrite the rules wholesale if the current defaults are still acceptable.

Treat `.claude/rules/language.md` as the source of truth for conversation language after the user picks it.

### 5. Set Up `ralph.toml`

Create or update `ralph.toml` as part of the same setup flow.

Use the same selection rules as `/ralph-registry-setup`:

- reuse existing project commands instead of inventing new ones
- prefer repo-level wrappers over framework-specific subcommands
- use `"N/A"` when a role does not apply
- keep the registry source-of-truth independent from any particular package manager
- confirm the underlying test framework or runner exists before finalizing `test_primary` or `test_integration`
- keep `test_primary` pointed at the smallest practical automated test level for the repo, not lint or unrelated validation, unless the user explicitly accepts that limitation
- keep `test_integration` as `"N/A"` only when broader tests do not apply; if requirements call for integration coverage but tooling is missing, report the gap instead of pretending setup is complete

If command choices are ambiguous, ask the user before writing them.

### 6. Report The Result

Summarize:

- which files were updated
- the final `ralph.toml` mappings
- the selected unit/primary test framework and command
- whether integration or E2E coverage is required, and the selected framework and command or the reason it is `"N/A"`
- any missing test dependencies or setup work still required before autonomous implementation is trustworthy
- any template areas intentionally left unchanged
- the next recommended command, usually `/prd-create`, `/spec-create`, or `/catchup`

## Notes

- Keep this skill focused on repository setup, not feature planning
- Prefer one setup pass that leaves the repo usable immediately
- Do not invent architecture or workflow details that the repo and user do not support
