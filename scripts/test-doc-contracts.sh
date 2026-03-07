#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

assert_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if ! grep -Fq -- "$needle" "$file"; then
    echo "Assertion failed: $message" >&2
    echo "Expected to find: $needle" >&2
    echo "File: $file" >&2
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if grep -Fq -- "$needle" "$file"; then
    echo "Assertion failed: $message" >&2
    echo "Unexpectedly found: $needle" >&2
    echo "File: $file" >&2
    exit 1
  fi
}

assert_contains ".claude/skills/prd-create/SKILL.md" "Specification | Title | Status | Completed On | Notes" "prd-create must document the exact progress.md schema"
assert_contains ".claude/skills/prd-enhance/SKILL.md" "Specification | Title | Status | Completed On | Notes" "prd-enhance must document the exact progress.md schema"
assert_contains ".claude/skills/spec-create/SKILL.md" "Specification | Title | Status | Completed On | Notes" "spec-create must document the exact progress.md schema"
assert_contains ".claude/skills/spec-create/SKILL.md" "- [ ] spec-NNN:" "spec-create must require unchecked checkbox todo tasks"
assert_contains ".claude/skills/spec-create/SKILL.md" '```gherkin' "spec-create must keep Gherkin acceptance criteria"
assert_contains ".claude/skills/implement/SKILL.md" 'first unchecked `- [ ]` task' "implement must select executable checkbox tasks"
assert_contains ".claude/skills/implement/SKILL.md" 'mark the progress row as `done` and fill in the completion date' "implement must define done semantics for progress.md"
assert_contains ".claude/skills/setup-ralph-matsuo/SKILL.md" "unit or primary test framework, whether it is already installed" "setup-ralph-matsuo must confirm unit test framework readiness"
assert_contains ".claude/skills/setup-ralph-matsuo/SKILL.md" "whether the repository's requirements call for integration or E2E coverage" "setup-ralph-matsuo must ask whether integration coverage is required"
assert_contains ".claude/skills/setup-ralph-matsuo/SKILL.md" 'keep `test_primary` pointed at the smallest practical automated test level' "setup-ralph-matsuo must keep test_primary aligned with real automated tests"
assert_contains ".claude/skills/setup-ralph-matsuo/SKILL.md" 'if requirements call for integration coverage but tooling is missing, report the gap instead of pretending setup is complete' "setup-ralph-matsuo must surface missing integration tooling"
assert_contains ".claude/skills/setup-ralph-matsuo/SKILL.md" "Start by asking which language the user wants for ongoing conversation." "setup-ralph-matsuo must ask for conversation language first"
assert_contains ".claude/skills/setup-ralph-matsuo/SKILL.md" 'Persist that choice in `.claude/rules/language.md`' "setup-ralph-matsuo must persist the selected conversation language"
assert_contains ".claude/skills/setup-ralph-matsuo/SKILL.md" "continue the rest of the setup conversation, summaries, and next-step guidance in that language" "setup-ralph-matsuo must continue in the selected language"
assert_contains ".claude/rules/language.md" 'Use the language selected during `/setup-ralph-matsuo` for all ongoing assistant responses in this repository.' "conversation language rule must be persisted in language.md"
assert_not_contains ".claude/rules/language.md" "Write all outputs in English." "language rule must no longer force English"
assert_contains ".claude/skills/roadmap-update/SKILL.md" "Specification | Title | Status | Completed On | Notes" "roadmap-update must preserve the exact progress.md schema"
assert_contains "scripts/ralph/CLAUDE.md" 'select the next unchecked `- [ ]` task' "headless Ralph must describe unchecked checkbox tasks"
assert_contains "scripts/ralph/CLAUDE.md" "Prefer the smallest practical unit first" "headless Ralph must prefer unit-level automated tests when feasible"
assert_contains "scripts/ralph/CLAUDE.md" "Do not rely on manual verification alone when automated tests are feasible" "headless Ralph must require automated tests when feasible"
assert_contains "scripts/ralph/CLAUDE.md" 'Update relevant implementation step checkboxes (`- [x]`)' "headless Ralph must update implementation step checkboxes"
assert_not_contains "scripts/ralph/CLAUDE.md" 'Update relevant acceptance criteria checkboxes (`- [x]`)' "headless Ralph must not assume checklist-style acceptance criteria"
assert_contains "docs/prds/_template/specifications/spec-001-example.md" '```gherkin' "spec template must keep Gherkin acceptance criteria"
assert_contains "docs/prds/_template/specifications/spec-001-example.md" "- [ ] [Executable task sized for one Ralph iteration]" "spec template must keep checkbox implementation steps"
assert_contains "CLAUDE.md" "Specification | Title | Status | Completed On | Notes" "root CLAUDE must describe the exact progress.md schema"

echo "All docs contract checks passed."
