---
name: prd-enhance
description: After MVP completion, interactively discuss the next scope and create a new PRD directory
user-invocable: true
argument-hint: "[New PRD slug]"
---

# PRD Enhancement (Next Scope Discussion)

Receives the new PRD slug as an argument: `$ARGUMENTS`

## Overview

After the current MVP or existing PRD is complete, interactively discuss the next scope and create a new PRD directory.
Use `docs/prds/_template/` as the baseline for file structure and formatting.

## Steps

### 1. Assess Current State

Read the following documents to understand the current state:
- `docs/prds/*/prd.md` (all PRDs)
- `docs/roadmap.md`
- `docs/prds/*/progress.md` (all PRDs)
- `docs/prds/*/specifications/spec-*.md` (all PRDs)

### 2. Discussion with User

Discuss the following topics with the user:
- Retrospective on current MVP/existing PRD (what went well, areas for improvement)
- Features and vision for the next phase
- Priority and constraints
- UX improvement points

### 3. Create New PRD Directory

Create the discussion results in `docs/prds/prd-{new-slug}/`. Same directory structure as `/prd-create`:

- `prd.md` — PRD body (including `## Branch` section)
- `progress.md` — Specification-level progress tracking
- `todo.md` — Next tasks
- `knowledge.md` — Initialize with empty template
- `dependencies.md` — Initialize with empty template

For `progress.md`, follow the template exactly:
- Keep the exact section name `## Specification Status`
- Keep the exact column order `Specification | Title | Status | Completed On | Notes`
- The `Status` column must be the third column
- Use only `pending`, `in-progress`, or `done`
- Remove template example rows before finishing
- After specifications are created, add exactly one row per `spec-*.md` file
- Update `## Summary` so the done count and current focus are accurate

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

### PRD Template

```markdown
# Product Requirements Document (PRD) - [Title]

## Branch

`ralph/{new-slug}`

## Overview

[What this PRD achieves]

## Background

[Why this PRD is needed. Context from existing PRDs]

## Product Principles

[Design principles and values for this PRD]

## Scope

### In Scope
- [Feature 1]
- [Feature 2]

### Out of Scope
- [Features not included]

## Target Users

[Updated personas and target users]

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

### 4. Follow-up Work

- Guide the user to create specifications for each decided feature using `/spec-create`
- Update `docs/roadmap.md` to add the new PRD vision
- After specification creation, sync `progress.md` so filenames, titles, and row count all match the `specifications/` directory

## Notes

- Prioritize dialogue with the user; don't unilaterally draft content
- Maintain consistency with existing PRDs
- This skill only updates documents. No source code implementation or changes
