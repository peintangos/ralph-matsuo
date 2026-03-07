# Git Workflow Rules

## Branches

- For PRD-scoped work in interactive sessions, use the branch specified in the PRD's `## Branch` section (branch + PR approach)
- During Ralph Loop execution, use the same branch specified in the PRD's `## Branch` section
- If no PRD is active, stay on the current branch and follow repository policy; do not switch to `main` just because the session is interactive

## Commit Messages

- Use Conventional Commits format with English prefix and description
  - Prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`
  - Example: `feat: add link card component`
  - Via Ralph Loop: `feat: spec-NNN - {todo task summary}`

## Other

- Commit dependency lockfiles or generated metadata when they are intentionally updated and required by the project's tooling
