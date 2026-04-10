---
name: code-review
description: "Conduct a code review. Analyze changes from 7 perspectives and present results."
user_invocable: true
context: fork
agent: codex:codex-rescue
---

# Code Review

Follow these steps to conduct a code review. You only have access to the Bash tool — use shell commands (`cat`, `find`, `git`) for all file reading.

## 1. Identify Change Scope

```bash
git diff --name-only HEAD
git diff --name-only
git diff --name-only --cached
git status
```

Run the above commands to get a list of changed files and untracked files.

## 2. Read Project Rules

```bash
find .claude/rules -type f -name '*.md' -exec cat {} +
```

Read all rule files under `.claude/rules/` to understand project conventions.

## 3. Identify Target Specification

```bash
find docs/prds -name 'todo.md' 2>/dev/null
```

If found, read the todo file and the corresponding specification to understand acceptance criteria. Skip if not found.

## 4. Conduct Review

Read each changed file with `cat` and review from the following **7 perspectives**:

1. **Correctness**: Any bugs or logic errors?
2. **Security**: Any stack-appropriate vulnerabilities around input handling, authorization, secrets, unsafe execution, or trust boundaries?
3. **Performance**: Any avoidable hot-path inefficiencies, repeated work, excessive I/O, or other stack-appropriate bottlenecks?
4. **Readability**: Are naming, structure, and comments appropriate?
5. **Convention compliance**: Does it follow project rules (`.claude/rules/`)?
6. **Spec compliance**: Does it meet specification acceptance criteria? (if specification exists)
7. **Testing**: Is test coverage and quality sufficient? (if tests exist)

## 5. Review Results Report

Output results in the following format:

```
## Code Review Results

**Overall Verdict**: No Issues / Needs Changes

### Findings

#### Must Fix
- [file:line] Description

#### Should Fix
- [file:line] Description

#### Nice to Have
- [file:line] Description

### Spec Compliance Check
- [ ] Acceptance criteria 1: PASS / FAIL
- [ ] Acceptance criteria 2: PASS / FAIL
```
