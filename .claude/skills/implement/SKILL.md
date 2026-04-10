---
name: implement
description: "Pick the top task from todo and implement it with tests and review based on related documents"
user-invocable: true
argument-hint: "[PRD slug or task specification (auto-detected if omitted)]"
---

# Task Implementation

Arguments: `$ARGUMENTS`

## Identify Target PRD

1. If a PRD slug is specified in `$ARGUMENTS`, use it
2. If not specified, search for `docs/prds/*/todo.md` using Glob
   - If only one is found: use that PRD
   - If multiple are found: confirm with the user
   - If none are found: confirm with the user

The target PRD path is `docs/prds/prd-{slug}/` below.

## Steps

### 1. Get Task

- Read `docs/prds/prd-{slug}/todo.md` and identify the first unchecked `- [ ]` task (or the task specified in `$ARGUMENTS`)

### 2. Gather Context

- Identify and read the related specification (`docs/prds/prd-{slug}/specifications/`)
- Check `docs/prds/prd-{slug}/knowledge.md` if it exists
- Read `docs/ubiquitous/glossary.md` if it exists to align on project terminology
- Investigate related source code using Grep / Glob

### 3. Implement

- Implement the task
- Create or update corresponding tests following the project's documented conventions and existing test layout

### 4. Review Cycle

Execute the following in order:

1. Run `/test` to execute tests
2. Run `/build-check` to run build and lint checks
3. **If the change affects web UI** (pages, components, styles, layouts), use `chrome-devtools` MCP to verify the rendered output visually:
   - Navigate to the relevant page and take a screenshot
   - Check for visual issues: images not loading, layout clipping, overflow, border rendering, responsive breakpoints
   - Fix any visual defects before proceeding
4. Run `/code-review` to conduct code review
5. If there are findings, fix them and re-review as needed

### 5. Update Records

- Check off the completed implementation step checkboxes in the related specification
- Mark the completed task in `docs/prds/prd-{slug}/todo.md` as `- [x]` (do not remove it) and keep remaining executable tasks as unchecked `- [ ]` lines
- Update `docs/prds/prd-{slug}/progress.md` using the exact template schema
  - If all acceptance criteria for that specification are complete, mark the progress row as `done` and fill in the completion date
  - Otherwise mark the progress row as `in-progress` and leave the completion date blank
- Record learnings in `docs/prds/prd-{slug}/knowledge.md`

### 6. Completion Report

- Report what was done to the user
- Suggest using `/commit-push` to commit

## Notes

- Aim to complete one task per execution
- Do not mark a specification `done` just because one todo item was completed
- If tests don't pass, record as a blocker in `todo.md` and report to the user
