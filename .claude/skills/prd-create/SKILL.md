---
name: prd-create
description: Interactively create the initial MVP PRD and split into specifications
user-invocable: true
argument-hint: "[PRD slug]"
---

# PRD Creation (Initial MVP)

Receives the PRD slug as an argument: `$ARGUMENTS`

## Overview

Interactively create the initial MVP PRD for a new project and generate a complete document set under `docs/prds/prd-{slug}/`.
Use `docs/prds/_template/` as the baseline for file structure and formatting.

## Interaction Modes

This skill supports two interaction modes for the discussion phase (Step 2). Identify the mode at the start of the session. The mode only changes how deeply the discussion is conducted; the generated artifacts and their format are identical in both modes.

### Ambiguous Mode (default)

Discuss the topics in Step 2 at a natural pace. Accept high-level or partial answers, and fill remaining gaps with reasonable defaults so momentum is preserved. Use this mode unless the user explicitly asks for deeper interrogation.

### Grill Me Mode

Interrogate every aspect of the plan until the user and the assistant reach shared understanding. Trigger this mode when the user says things like "grill me", "徹底的に質問して", "詰めて", "grill meモードで", or otherwise requests thorough/rigorous questioning.

Rules for Grill Me Mode:

- Walk the decision tree branch by branch. Resolve dependencies between decisions in order — do not move to a decision that depends on an unresolved earlier one.
- Ask questions **one at a time**. Wait for the user's answer before asking the next question.
- For every question, present the recommended answer alongside the question, with a brief reason so the user can agree, tweak, or overrule.
- If a question can be answered by exploring the codebase (existing docs, `docs/ubiquitous/glossary.md`, `docs/roadmap.md`, `docs/prds/_template/`, related source), investigate first and bring the finding to the user **instead of** asking.
- Continue until no unresolved branch materially affects PRD scope, functional requirements, UX, or system requirements. Only then proceed to Step 3.

## Prerequisites

### Verify Repository Initialization

Before starting PRD creation, confirm that the project is backed by a git repository with a remote configured.

1. Check git initialization:
   - Run `git rev-parse --is-inside-work-tree` (or check for a `.git` directory)
2. Check remote repository:
   - Run `git remote -v` and confirm at least one remote (typically `origin`) exists
3. If either check fails:
   - Stop PRD creation and invoke the `init-repo` skill to initialize git and create the remote repository
   - After `init-repo` completes, return here and continue with `## Steps`
4. If both checks pass, proceed to the next prerequisite

Rationale: PRD artifacts (`docs/prds/prd-{slug}/`), roadmap updates, and README changes are meant to be version-controlled and pushed. Creating them before the repository exists risks losing work and breaks the downstream Ralph Loop workflow, which assumes a branch can be created and pushed from `prd.md`'s `## Branch`.

### Confirm Security Scan Workflow

The template ships with `.github/workflows/security-scan.yml`, which runs `npm audit`, Semgrep, and Snyk on a weekly schedule and on dependency changes. Before continuing, decide whether this project needs it.

1. Check whether `.github/workflows/security-scan.yml` exists.
   - If it does **not** exist, skip this prerequisite (the user already made a decision in a previous run).
2. If it exists, ask the user explicitly:
   - "This repository includes `security-scan.yml` (npm audit + Semgrep + Snyk). Enable it for this project, or disable it?"
   - Briefly summarize what each scanner covers and that Snyk requires `SNYK_TOKEN` as an Actions secret to run.
3. Apply the choice:
   - **Enable**: leave the file in place. If the project does not have a `package.json` / `package-lock.json`, warn the user that `npm audit` and Snyk jobs will fail until those files exist, and offer to narrow the `paths:` triggers or remove those jobs.
   - **Disable**: delete `.github/workflows/security-scan.yml` (do not comment out — keep the workflows directory clean). Tell the user they can restore it from the template later if needed.
4. Do not create a commit at this point. The deletion (if any) will be picked up by the normal commit flow at the end of PRD creation.

Rationale: keeping or removing CI security scans is a project-wide decision, not a per-PRD one, but `/prd-create` is the first interactive entry point for a fresh template clone, so it is the natural place to surface the choice. Asking once and gating on file existence avoids re-prompting on later `/prd-create` invocations.

## Steps

### 1. Assess Current State

Check the following:
- Project purpose and background (confirm through conversation with user)
- Existing documents (under `docs/`)
- `docs/ubiquitous/glossary.md` — review existing terms to ensure terminology consistency in the new PRD

### 2. Discussion with User

Discuss the following topics with the user, following the active interaction mode (see `## Interaction Modes`):

- Product vision and purpose
- Target users (personas)
- Feature prioritization for MVP
- Technical constraints
- UX requirements

In Grill Me Mode, treat the list above as the **root** of the decision tree. Expand each topic into sub-decisions (for example, "Feature prioritization" implies ordering, MVP cut line, out-of-scope rationale) and resolve them in dependency order, one question at a time, with a recommended answer attached to each question.

### 3. Create PRD Directory

Create the `docs/prds/prd-{slug}/` directory and generate the following files.
Match the templates under `docs/prds/_template/` instead of inventing new section names or table layouts.

#### 3-1. PRD Body: `prd.md`

### PRD Template

```markdown
# Product Requirements Document (PRD) - MVP

## Branch

`ralph/{slug}`

## Overview

[What this product achieves]

## Background

[Why this product is needed]

## Product Principles

[Design principles and values]

## Scope

### In Scope
- [Feature 1]
- [Feature 2]

### Out of Scope
- [Features not included]

## Target Users

[Personas and target users]

## Use Cases

[Key use cases]

## Functional Requirements

[Specific functional requirements]

## UX Requirements

[User experience requirements]

## System Requirements

[Technical and system requirements]

## Milestones

| Milestone | Description | Target Date |
|-----------|-------------|-------------|
| ... | ... | ... |
```

#### 3-2. Progress: `progress.md`

Create `progress.md` from `docs/prds/_template/progress.md`.

Requirements:
- Keep the exact section name `## Specification Status`
- Keep the exact column order `Specification | Title | Status | Completed On | Notes`
- The `Status` column must be the third column
- Use only `pending`, `in-progress`, or `done`
- Remove template example rows before finishing
- After specifications are created, add exactly one row per `spec-*.md` file
- Keep `Completed On` and `Notes` empty until there is real content to record
- Update `## Summary` so the counts and current focus match the current spec set

Correct shape:

```markdown
# Progress - [PRD Title]

Use only these status values: `pending`, `in-progress`, `done`

## Specification Status

| Specification | Title | Status | Completed On | Notes |
|---------------|-------|--------|--------------|-------|
| spec-001-xxx | [Title] | pending | | |
| spec-002-xxx | [Title] | pending | | |

## Summary

- Done: 0/2
- Current focus: spec-001-xxx
```

#### 3-3. TODO: `todo.md`

Add tasks derived from milestones. Each task should be executable in one implementation pass.

#### 3-4. Knowledge: `knowledge.md`

Initialize with an empty template.

#### 3-5. Dependencies: `dependencies.md`

Initialize with an empty template (Mermaid graph + implementation order table).

### Optional Sections (add as needed)

- Market analysis
- Competitive analysis
- Security requirements
- Privacy requirements
- Performance requirements
- Marketing plan

### 4. Split into Specifications

Based on the PRD's functional requirements, split into individual specifications in consultation with the user:
- Guide them to create each specification using `/spec-create`
- Confirm feature granularity and priority with the user
- After each specification is decided, update `progress.md` so the filename slug and title match the specification exactly
- Before finishing, verify that the number of rows in `progress.md` matches the number of files under `specifications/`

### 5. Update Roadmap

- Add the MVP vision and plan to `docs/roadmap.md`

### 6. Update README.md

- Add the project name and overview to README.md
- Include a link referencing `docs/prds/prd-{slug}/prd.md` for details

## Notes

- Prioritize dialogue with the user; don't unilaterally draft content
- Not all sections need to be decided at once; they can be filled in progressively
- After creating the PRD, check if any new domain terms should be added to `docs/ubiquitous/glossary.md`
- This skill only updates documents. No source code implementation or changes
- Respect the active interaction mode (see `## Interaction Modes`). If the user switches mode mid-session ("grill meに切り替えて" / "もう曖昧でいい"), adapt immediately and keep using the new mode until told otherwise
