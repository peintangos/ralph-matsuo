---
name: code-review
description: "Conduct a code review. Analyze changes from 7 perspectives and present results."
user_invocable: true
context: fork
agent: code-reviewer
---

# Code Review

Follow these steps to conduct a code review.

## 1. Identify Change Scope

```bash
git diff --name-only HEAD
git diff --name-only
git diff --name-only --cached
```

Run the above commands to get a list of changed files. Also check untracked files with `git status`.

## 2. Read Project Rules

Read all rule files under `.claude/rules/` to understand project conventions.

## 3. Identify Target Specification

Search for `docs/prds/*/todo.md` using Glob to determine which specification corresponds to the current task. If found, Read the specification to understand acceptance criteria. Skip if not found.

## 4. Conduct Review

Read changed files and review from the following 7 perspectives:

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
