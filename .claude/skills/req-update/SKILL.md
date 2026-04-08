---
name: req-update
description: "Analyze the impact of requirements changes/additions and report update proposals for all documents. Only a summary is returned to the main context."
argument-hint: "[PRD slug] [Description of changes/additions]"
user-invocable: true
context: fork
allowed-tools: Read, Glob, Grep
---

# Requirements Change Impact Analysis

Analyze the impact of requirements changes/additions based on `$ARGUMENTS` and report update proposals for all documents.

## Identify Target PRD

1. If a PRD slug is specified in `$ARGUMENTS`, use it
2. If not specified, search for `docs/prds/*/prd.md` using Glob
   - If only one is found: use that PRD
   - If multiple are found: analyze impact across all PRDs

The target PRD path is `docs/prds/prd-{slug}/` below.

## 1. Read All Documents

Read all of the following:

- `docs/prds/prd-{slug}/prd.md`
- `docs/prds/prd-{slug}/specifications/spec-*.md` (search with Glob)
- `docs/prds/prd-{slug}/progress.md`
- `docs/prds/prd-{slug}/todo.md` (if exists)
- `docs/prds/prd-{slug}/dependencies.md` (if exists)
- `docs/roadmap.md`
- `docs/architecture.md`
- `docs/ubiquitous/glossary.md` (if exists)
- `docs/references/` (if exists)

## 2. Codebase Investigation

Investigate code related to keywords in `$ARGUMENTS`:

- Search for related code using Grep
- Identify related files using Glob
- List affected implementation files

## 3. Impact Analysis

Interpret the content of `$ARGUMENTS` and determine:

- **Change type**: Requirement change / Requirement addition / Both
- **Affected documents**: Which of PRD / specifications / progress / roadmap / todo / architecture / dependencies
- **Affected code**: Whether existing implementation is impacted

## 4. Draft Update Proposals for Each Document

For each affected document, describe specific update content:

- **PRD**: Row additions/changes in the functional requirements table, scope updates, etc.
- **Specifications**: Scenario additions/changes, acceptance criteria updates, implementation step additions/changes
- **Progress**: New spec row additions, status changes
- **Roadmap**: Milestone content updates, dependency changes
- **TODO**: Task additions/changes/deletions
- **Architecture**: Data model changes, etc. (when applicable)
- **Dependencies**: Specification dependency relationship changes

Update proposals should clearly state "what existing text to change to what" or "what to append."

## 5. Report Output

Output in the following structured format. This becomes the summary returned to the main context.

```
## Requirements Update Impact Analysis Report

### Change Summary
- Type: Requirement Change / Requirement Addition
- Content: [Summary]

### Impact Scope Summary

| Document | Impact | Change Summary |
|----------|--------|----------------|
| PRD | Changed / Added / None | [Summary] |
| Specification | ... | ... |
| Progress | ... | ... |
| Roadmap | ... | ... |
| TODO | ... | ... |
| Architecture | ... | ... |
| Dependencies | ... | ... |

### Code Impact
- [file path]: [Impact summary]
(If unimplemented: "No relevant code")

### Update Proposals for Each Document

#### PRD (`docs/prds/prd-{slug}/prd.md`)
[Specific update content. What existing text changes to what, or content to append]

#### Specification (`docs/prds/prd-{slug}/specifications/spec-NNN-slug.md`)
[Specific update content]

...(listed for each affected document)

### TODO Impact
- [Tasks to add/change/delete]

### Notes
- [Points to note during updates, consistency considerations, etc.]
```

## Notes

- Don't create update proposals based on speculation; cite existing document text accurately before presenting change proposals
- For documents with no impact, explicitly state "No impact" rather than forcing update proposals
- Update proposals are just proposals; they are applied after user approval in the main context
- This skill only updates documents. No source code implementation or changes
