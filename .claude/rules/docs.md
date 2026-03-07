---
paths:
  - "docs/**"
---

# Documentation Editing Rules

## PRD Directory Structure

Each PRD is managed under `docs/prds/prd-{slug}/` with the following structure:

```
docs/prds/prd-{slug}/
├── prd.md              # PRD body (requirements definition)
├── knowledge.md        # Codebase patterns and notes
├── progress.md         # Specification-level progress tracking
├── todo.md             # Next tasks to work on
├── dependencies.md     # Specification dependencies and implementation order
└── specifications/     # Feature specs in Gherkin format
    ├── spec-001-*.md
    ├── spec-002-*.md
    └── ...
```

### Other Documents

- `docs/architecture.md` — System architecture (update when structure changes)
- `docs/roadmap.md` — Project roadmap (vision and plans)

## Completion Checklist

- [ ] Update specification completion status in the target PRD's `progress.md`
- [ ] Update acceptance criteria and implementation steps in related `specifications/`
- [ ] Update `docs/architecture.md` if structural changes were made
- [ ] Update `docs/roadmap.md` if vision or plans are affected
- [ ] Remove completed tasks from the target PRD's `todo.md` and add next tasks
- [ ] Add reusable patterns to `knowledge.md`

## README.md

- Update the overview section of README.md when creating a PRD (reference the target PRD's `prd.md` for details)
- Update the relevant section of README.md when the tech stack changes
