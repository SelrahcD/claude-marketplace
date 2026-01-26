---
name: worktree
description: Create isolated git worktrees for feature work
---

# Worktree - Git Worktree Management

Create isolated git worktrees for feature work.

## Usage
```
/worktree <branch>
```

Examples:
```
/worktree feature/new-auth
/worktree fix/login-bug
/worktree refactor/database-layer
```

## Process

Invoke the `using-git-worktrees` skill to:
- Create an isolated git worktree for the specified branch
- Smart directory selection for worktree location
- Safety verification before creating

Use when starting feature work that needs isolation from the current workspace or before executing implementation plans.
