# Dependencies — [PRD Title]

## Dependency Graph

```mermaid
graph LR
    %% Add only real dependencies between specifications.
    spec-001 --> spec-002
    spec-002 --> spec-003
```

## Implementation Order

| Order | Specification | Depends On | Why This Order | Notes |
|-------|---------------|------------|----------------|-------|
| 1 | spec-001-xxx | none | [foundation work] | |
| 2 | spec-002-xxx | spec-001 | [builds on shared base] | |
