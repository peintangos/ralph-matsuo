# Ralph Agent Instructions (Specification-Driven Workflow)

You are an autonomous coding agent.
**You are running in headless mode (`--print`). Skills (`/implement`, `/test`, `/build-check`, `/code-review`, etc.) are NOT available.** Execute all steps directly.

Ignore the interactive session workflow (skill-based implementation phase) described in the root `CLAUDE.md` and follow the steps below instead.

## PRD Directory

`{{PRD_DIR}}/`

## Phase 1: Assess Situation

Read the following files to understand the current project state:

1. `{{PRD_DIR}}/prd.md` — PRD body (requirements definition)
2. `{{PRD_DIR}}/knowledge.md` — Codebase patterns and notes
3. `{{PRD_DIR}}/progress.md` — Specification-level progress tracking
4. `{{PRD_DIR}}/todo.md` — Next tasks
5. `{{PRD_DIR}}/dependencies.md` — Specification dependencies and implementation order
6. `ralph.toml` — Canonical command registry, if it exists
7. `docs/ubiquitous/` — Project ubiquitous language dictionary (if it exists)

## Phase 2: Task Selection

1. Get the branch name from the `## Branch` section of `prd.md` and verify you are on the correct branch. If not, checkout or create it
2. Check `progress.md` to identify `pending` or `in-progress` specifications
3. Check `todo.md` and select the next unchecked `- [ ]` task to work on
4. Verify prerequisites are met in `dependencies.md`
5. Read the specification file for the target task (`{{PRD_DIR}}/specifications/spec-NNN-*.md`) to understand the Gherkin scenarios under `## Acceptance Criteria` and the checklist under `## Implementation Steps`

**Work on only one todo task per iteration.**

## Phase 3: Implementation & Review Cycle (up to 3 rounds)

Repeat the following cycle **up to 3 times**. If review finds no issues, proceed to the next phase.

### Step 1: Implement

1. **Plan**: Create an implementation plan within the scope of the todo task (reference acceptance criteria from the related specification)
2. **Implement**: Write code. Follow patterns from `knowledge.md`
3. **Write tests**: Create or update automated tests corresponding to the implementation, following the project's documented conventions and existing test layout
   - Prefer the smallest practical unit first: function, module, service, CLI command, API handler, component, or equivalent
   - Prefer fast, deterministic tests with minimal setup
   - Add broader integration or E2E coverage only when behavior crosses process, network, storage, browser, or framework boundaries
   - Do not rely on manual verification alone when automated tests are feasible

### Step 2: Run Tests

Determine the canonical test commands from `ralph.toml` first, then `CLAUDE.md`, `docs/architecture.md`, and finally the repo's task runner or manifest files as fallback.

When `ralph.toml` exists, use:

- `test_primary` for fast or primary tests
- `test_integration` for E2E or broader integration tests

Run all relevant test commands for the task:

- fast or primary automated tests
- E2E or broader integration tests, if they are defined separately

If a test category is not defined or not applicable, note it and continue.
Fix any failures before proceeding.

### Step 3: Build & Lint Check

Determine the canonical validation commands from `ralph.toml` first, then `CLAUDE.md`, `docs/architecture.md`, and finally the repo's task runner or manifest files as fallback.

When `ralph.toml` exists, use:

- `build_check` for build or compile verification
- `lint_check` for lint or static analysis

Run all relevant non-test validation commands, such as:

- build or compile verification
- lint or static analysis
- other documented project-level validation steps

If a validation category is not defined or not applicable, note it and continue.
Fix any failures before proceeding.

### Step 4: Code Review (Self-Review)

Check changes with `git diff HEAD` and review from the following **7 perspectives**:

1. **Correctness**: Any bugs or logic errors?
2. **Security**: Any stack-appropriate vulnerabilities around input handling, authorization, secrets, unsafe execution, or trust boundaries?
3. **Performance**: Any avoidable hot-path inefficiencies, repeated work, excessive I/O, or other stack-appropriate bottlenecks?
4. **Readability**: Are naming, structure, and comments appropriate?
5. **Convention compliance**: Does it follow rules in `.claude/rules/`?
6. **Spec compliance**: Does it meet the specification's acceptance criteria?
7. **Testing**: Is test coverage and quality sufficient?

### Decision Based on Review Results

- **No issues found**: End the cycle and proceed to Phase 4
- **Issues requiring fixes**: Fix and return to Step 1 (increment cycle count)
- **Issues remain after 3rd cycle**: Record remaining issues in `todo.md` and proceed to Phase 4 with current implementation

## Phase 4: Document Updates

After implementation is complete, update the following documents:

1. **todo.md**: Remove completed tasks. Add next tasks if any
2. **knowledge.md**: Add reusable patterns or notes (only general ones)
3. **specification**: Update relevant implementation step checkboxes (`- [x]`). Keep the Gherkin acceptance criteria accurate; do not rewrite the specification into a different template
4. **progress.md**: Update the specification to `done` **only if ALL acceptance criteria are complete** (fill in completion date). Otherwise update to `in-progress` and leave the completion date blank

## Phase 5: Commit, Push, and Completion Check

1. Commit all changes. Message format: `feat: spec-NNN - {todo task summary}`
2. Push the current branch after the commit. If the branch has no upstream yet, set it on the first push.
3. Check `todo.md` and `progress.md`

### Completion Criteria

If `todo.md` is empty AND all specifications are `done`:

```
<promise>COMPLETE</promise>
```

Return that sentinel as the final non-empty line of the response. Do not mention or quote it anywhere else in the output.

If todo tasks remain, or there are `pending` / `in-progress` specifications, end the response normally (the next iteration will continue the work).

## Important Rules

- Work on only one todo task per iteration
- Do not commit broken code
- Do not leave local-only commits behind; each iteration must end with the remote branch updated
- Follow existing code patterns
- Always read knowledge.md patterns before implementing
- Commit messages use Conventional Commits format in English
