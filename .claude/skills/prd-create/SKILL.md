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

## Steps

### 1. Assess Current State

Check the following:
- Project purpose and background (confirm through conversation with user)
- Existing documents (under `docs/`)

### 2. Discussion with User

Discuss the following topics with the user:
- Product vision and purpose
- Target users (personas)
- Feature prioritization for MVP
- Technical constraints
- UX requirements

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
- This skill only updates documents. No source code implementation or changes
