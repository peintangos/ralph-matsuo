---
name: spec-create
description: Create a new feature specification and update progress.md and roadmap.md
user-invocable: true
argument-hint: "[PRD slug] [Feature name]"
---

# Feature Specification Creation

Arguments: `$ARGUMENTS` (PRD slug and feature name)

## Identify Target PRD

1. If a PRD slug is specified in `$ARGUMENTS`, use it
2. If not specified, search for `docs/prds/*/prd.md` using Glob
   - If only one is found: use that PRD
   - If multiple are found: confirm with the user

The target PRD path is `docs/prds/prd-{slug}/` below.

## Steps

1. **Check PRD requirements**: Read `docs/prds/prd-{slug}/prd.md` and identify which PRD requirement this feature corresponds to. Also read `docs/ubiquitous/glossary.md` to use consistent terminology in the specification
2. **Check existing specifications**: Check `docs/prds/prd-{slug}/specifications/` for duplicates. Check existing spec numbers and determine the next number
3. **Create specification**: Create `docs/prds/prd-{slug}/specifications/spec-NNN-<slug>.md` using `docs/prds/_template/specifications/spec-001-example.md` as the baseline
4. **Update progress.md**: Add the new specification to `docs/prds/prd-{slug}/progress.md` using the exact template schema from `docs/prds/_template/progress.md`
5. **Update dependencies.md**: Add the new specification's dependencies to `docs/prds/prd-{slug}/dependencies.md`
6. **Check roadmap.md**: Reflect in `docs/roadmap.md` as needed

## Specification Template (Gherkin Format)

~~~markdown
# spec-NNN: [Feature Name]

## Overview

[What this specification covers]

## Acceptance Criteria

```gherkin
Feature: [Feature Name]

  Background:
    [Background description for this feature]

  Scenario: [Scenario name 1]
    Given [Precondition]
    When [Action/Event]
    Then [Expected result]

  Scenario: [Scenario name 2]
    Given [Precondition]
    When [Action/Event]
    Then [Expected result]
```

## Implementation Steps

- [ ] [First executable task]
- [ ] [Next executable task]
- [ ] [Add or update tests]
- [ ] Review (build check + lint + `/code-review`)
~~~

## Progress Update Rules

- Keep the exact section name `## Specification Status`
- Keep the exact column order `Specification | Title | Status | Completed On | Notes`
- Add exactly one row for the new `spec-NNN-<slug>.md` file
- Use `pending` as the initial status
- Keep `Completed On` and `Notes` empty for a new specification
- Update `## Summary` so the done count and current focus remain accurate

### 7. Update TODO

- Add the specification's implementation steps as unchecked checkbox tasks to `docs/prds/prd-{slug}/todo.md`
- Format each task as `- [ ] spec-NNN: [task summary]`
- Keep each todo task small enough for one `/implement` run or one Ralph iteration

## Notes

- Filename format: `spec-NNN-<slug>.md` (e.g., `spec-001-transaction-crud.md`)
- NNN is a zero-padded 3-digit sequential number
- Gherkin Given/When/Then can be in any language
- `progress.md` must keep one row per specification file; do not invent alternate table layouts
- `todo.md` executable tasks must remain unchecked checkbox lines (`- [ ]`)
- Always include a review step (build check + lint + `/code-review`) at the end of implementation steps
- After creating the specification, check if any new domain terms should be added to `docs/ubiquitous/glossary.md`
- This skill only updates documents. No source code implementation or changes
