---
name: issue
description: "Create a GitHub issue. Use when the user casually says 'create an issue for this'."
argument-hint: "[Rough description of the issue content]"
allowed-tools: Bash
---

Based on the user's request, create a GitHub issue.

## Steps

1. **Format content**: From the user's request (`$ARGUMENTS` or conversation context), compose:
   - **Title**: Concise and clear
   - **Body**: Background, goals, acceptance criteria, etc. formatted in Markdown

2. **Confirm with user**: Display the formatted content before creating
   ```
   Will create the following issue:

   Title: [title]
   Labels: [labels if any]

   Body:
   [body]

   Proceed?
   ```

3. **Create**: Once approved, create with `gh issue create`

## Issue Template

The body should follow this basic structure (adjust flexibly based on content):

```markdown
## Overview
[What you want to do / What's the problem]

## Details
[Background and specific content]

## Acceptance Criteria
- [ ] [Criteria 1]
- [ ] [Criteria 2]
```

## Rules

- Match the user's language
- Interpret the intent from rough requests and format appropriately
- Ask questions before creating if anything is unclear
- Only add labels or assignees if the user specifies them
- Display the issue URL after creation
