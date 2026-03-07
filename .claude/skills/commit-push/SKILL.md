---
name: commit-push
description: "Commit changes and push to remote. Use when the user casually says 'commit' or 'push'."
argument-hint: "[Rough description of commit message or content]"
allowed-tools: Bash
---

Based on the user's request, commit changes and push to the remote.

## Steps

1. **Check status**: Run the following in parallel to understand the current state
   - `git status` to check changed files
   - `git diff` to check unstaged changes
   - `git diff --cached` to check staged changes
   - `git log --oneline -5` to check recent commit style

2. **Create commit message**: Compose an appropriate commit message from `$ARGUMENTS` or conversation context
   - **Use Conventional Commits format** (e.g., `feat: add new feature`, `fix: fix bug`, `docs: update documentation`, `chore: maintenance`)
   - If the user specified a message, respect it
   - If not specified, create a concise message from the changes

3. **Confirm with user**: Display the content before committing for confirmation
   ```
   Will commit & push the following:

   Branch: [branch]
   Files:
   - [file1]
   - [file2]

   Commit message:
   [message]

   Proceed?
   ```

4. **Commit & push**: Once approved, execute the following
   - Stage target files with `git add` (avoid `git add .`, specify filenames explicitly)
   - Verify no sensitive files (.env, credentials) are included
   - Commit with `git commit` (include Co-Authored-By)
   - Push to remote with `git push`

## Rules

- Match the user's language
- Never commit sensitive files (.env, credentials, secrets). Warn if they are included
- Do not use `git add .` or `git add -A`; specify files explicitly
- Do not force push. Confirm with the user if needed
- Append the following to commit messages:
  ```
  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  ```
- Display commit hash and push destination after pushing
- Use `-u origin [branch]` if the remote branch doesn't exist
