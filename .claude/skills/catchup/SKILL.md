---
name: catchup
description: "Summarize the current project status at session start and suggest next actions"
user_invocable: true
context: fork
agent: catchup-reporter
---

# Catchup

Follow these steps to summarize the current project status and suggest next actions.

## 1. Check TODOs

Search for `docs/prds/*/todo.md` using Glob, then Read all PRD TODOs. Identify next tasks.

## 2. Read PRDs

Search for `docs/prds/*/prd.md` using Glob, then Read each PRD. Understand the overall project scope.

## 3. Read Progress & Roadmap

Read `docs/prds/*/progress.md` and `docs/roadmap.md` to understand current milestone progress.

## 4. Check Specification Status

List `docs/prds/*/specifications/spec-*.md` using Glob, then Read each specification. Tally implementation step checkboxes (`- [x]` / `- [ ]`) to understand completion status of each spec.

## 5. Check Knowledge

Search for `docs/prds/*/knowledge.md` using Glob, and Read if they exist. Understand reusable patterns and notes.

## 5.5. Check Ubiquitous Language & References

- Read `docs/ubiquitous/*.md` if it exists. Understand project terminology.
- Check `docs/references/` for awareness of available reference materials.

## 6. Output Summary and Suggestions

Output results in the following format (show progress per PRD):

```markdown
## Catchup

### Project Overview

[1-2 line summary from PRDs]

### Progress by PRD

#### prd-{slug1}

| Specification | Status | Notes |
| ------------- | ------ | ----- |
| spec-001-xxx  | done / in-progress / pending | ... |

#### prd-{slug2}

...

### Unresolved Blockers

- [Extracted from todo.md or specifications. "None" if empty]

### Suggested Next Actions

1. [Highest priority: first task in todo.md, or next unstarted specification step]
2. [Next]

### Knowledge

- [Key learnings from knowledge.md. "None" if empty]
```
