---
name: roadmap-update
description: Update roadmap.md and progress.md to reflect the latest development status
user-invocable: true
---

# Roadmap & Progress Update

## Overview

Update `docs/roadmap.md` (vision and plans) and each PRD's `progress.md` (development progress) to their latest state.
Keep `progress.md` aligned with `docs/prds/_template/progress.md`.

## Steps

### 1. Assess Current State

Read all of the following:
- `docs/roadmap.md`
- `docs/prds/*/progress.md` (across all PRDs)
- `docs/prds/*/specifications/spec-*.md` (across all PRDs)
- `docs/prds/*/knowledge.md` (across all PRDs)

### 2. Update progress.md

Update each PRD's `docs/prds/prd-{slug}/progress.md`:
- Check completion status of each specification and update state
  - `pending`: Specification created but not started
  - `in-progress`: Development underway
  - `done`: All acceptance criteria met and complete
- Keep the exact column order `Specification | Title | Status | Completed On | Notes`
- Keep exactly one row per file under `specifications/spec-*.md`
- Update completion dates only for `done` specifications
- Add missing specification rows if any, but do not introduce duplicate or unknown rows
- Update `## Summary` so the done count and current focus match the current spec set

### 3. Update roadmap.md

- Reflect any changes to vision or plans
- Add new enhancements or direction changes
- Mark completed milestones as done

### 4. Report Changes

Report updated content to the user.

### 5. Update TODO

- If roadmap changes require adding new tasks or modifying existing tasks in each PRD's `docs/prds/prd-{slug}/todo.md`, reflect those changes as unchecked checkbox lines (`- [ ]`)

## Notes

- progress.md should be fact-based (no speculation)
- progress.md must keep the template schema; do not rewrite it into a different table layout
- roadmap.md is for vision and plans only. Detailed progress goes in progress.md
- This skill only updates documents. No source code implementation or changes
