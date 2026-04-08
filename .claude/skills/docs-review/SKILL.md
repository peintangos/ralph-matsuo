---
name: docs-review
description: Review all documents under docs/ for consistency and make necessary corrections
user-invocable: true
---

# Documentation Consistency Review

## Overview

Investigate all documents under `docs/` and verify/correct consistency with the current codebase.

## Steps

### 1. Read All Documents

Read all of the following:
- `docs/prds/*/prd.md` (all PRDs)
- `docs/roadmap.md`
- `docs/prds/*/progress.md` (all PRDs)
- `docs/prds/*/specifications/spec-*.md` (all PRDs)
- `docs/prds/*/knowledge.md` (all PRDs)
- `docs/prds/*/dependencies.md` (all PRDs)
- `docs/architecture.md`
- `docs/ubiquitous/*.md` (ubiquitous language dictionary)
- `docs/references/` (reference materials)

### 2. Code Consistency Check

- Check if code under `src/` matches the description in `docs/architecture.md`
- Check if `package.json` dependencies match the tech stack description
- Check if `specifications/` acceptance criteria match actual implementation

### 3. Cross-Document Consistency Check

- Verify specifications exist for each PRD's functional requirements in `prd.md`
- Verify each PRD's `progress.md` status matches actual development state
- Verify `roadmap.md` reflects the latest discussions
- Verify PRD references in `specifications/` are correct
- Verify `dependencies.md` dependency relationships are correct
- Verify terminology consistency: terms used in PRDs, specifications, and code should match definitions in `docs/ubiquitous/glossary.md`

### 4. Execute Corrections

- If inconsistencies are found, present the corrections to the user before making them
- Confirm with the user for major changes

### 5. Report

Report corrected items and remaining issues to the user.

### 6. Update TODO

- Add tasks to the target PRD's `todo.md` for inconsistencies found during review (if needed)

## Notes

- Keep corrections minimal and respect existing content
- Confirm with the user when in doubt
- This skill only updates documents. No source code implementation or changes
