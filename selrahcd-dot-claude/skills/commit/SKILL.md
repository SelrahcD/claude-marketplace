---
name: commit
description: Create git commits with meaningful messages. Use when the user says "commit", wants to commit changes, or has finished implementing a feature.
user-invocable: true
context: fork
allowed-tools:
  - Glob
  - Grep
  - Read
  - Bash
  - AskUserQuestion
---

# Commit

Create git commits with well-structured commit messages following conventional commit standards.

## Usage

`/commit` - Analyze staged and unstaged changes, generate a commit message, and create the commit.

## Instructions

When this skill is invoked, follow these steps:

### 1. Gather Information (run in parallel)

Run the following bash commands in parallel:

- `git status` - See all untracked files (never use -uall flag)
- `git diff` - See unstaged changes
- `git diff --cached` - See staged changes
- `git log --oneline -10` - See recent commit messages for style reference

### 2. Analyze Changes

- Review all staged and unstaged changes
- Understand what was modified, added, or deleted
- Identify the nature of the changes (feature, fix, refactor, docs, chore, etc.)

### 3. Verify Logical Grouping

Check if all changes belong together in a single commit. Changes are logically grouped if they:

- Relate to a single feature, fix, or task
- Share the same commit type (all docs, all refactor, etc.)
- Would make sense to revert together

**If changes are NOT logically grouped:**

1. Identify logical groupings (e.g., "docs changes", "new feature X", "refactor Y", "config updates")
2. Use AskUserQuestion to ask the user which grouping to commit first
3. Present 2-4 grouping options based on the changes detected
4. Include an "All changes" option if the user wants to commit everything together anyway

Example groupings to detect:

- Documentation vs code changes
- Different features or modules
- Test additions vs implementation
- Config/tooling vs application code
- Refactoring vs new functionality

After the user selects a grouping, only stage and commit those files. Repeat the commit process for remaining changes if the user wants multiple commits.

**If changes ARE logically grouped:** Proceed to step 4.

### 4. Draft Commit Message

- Summarize the nature of the changes (only for the selected grouping)
- Use conventional commit format: `type(scope): description`
- Focus on the "why" rather than the "what"
- Keep it concise (1-2 sentences)

Common types:

- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code restructuring without behavior change
- `docs` - Documentation only
- `chore` - Maintenance tasks
- `test` - Adding or updating tests

### 5. Stage and Commit

Run sequentially:

1. Add only the files from the selected grouping: `git add <files>`
2. Create the commit using a HEREDOC for proper formatting:

```bash
git commit -m "$(cat <<'EOF'
type(scope): description

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

3. Run `git status` to verify success

### 6. Report Results

Report to the user:

- The commit hash
- The commit message
- A summary of what was committed

## Safety Rules

- NEVER update git config
- NEVER run destructive commands (push --force, hard reset)
- NEVER skip hooks (--no-verify)
- NEVER use git commit --amend unless explicitly requested
- NEVER commit files that may contain secrets (.env, credentials.json)
- Do NOT push unless explicitly requested

## Notes

- If there are no changes to commit, inform the user
- If pre-commit hooks fail, fix the issue and create a NEW commit
- After a partial commit (when changes were split into groups), inform the user about remaining uncommitted changes and offer to continue with another commit
