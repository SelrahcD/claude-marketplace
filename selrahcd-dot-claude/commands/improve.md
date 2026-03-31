---
name: improve
description: Analyze the current conversation for friction and issues, process pending observations, and implement durable improvements
---
Read the `improve` skill and its supporting files:
- `retro-process.md` for the orchestration flow
- `solution-hierarchy.md` for the prioritization framework

## Phase 1: Analyze the conversation

Scan the current conversation for:

- **Errors:** failed commands, wrong paths, syntax errors, test failures
- **Inefficiencies:** multiple searches for the same thing, irrelevant file reads, repeated patterns
- **Corrections:** user corrections to your work, reverted changes, abandoned approaches
- **Friction:** moments where the workflow felt slow or awkward

For each finding, perform a brief 5 whys root cause analysis (2-3 levels deep is enough — go deeper only if the root cause isn't clear).

Create `~/.claude/retro/` directory if it doesn't exist.

Save each finding to `~/.claude/retro/observations.md` using the observation format from the skill, with:

- **Status:** `pending`
- **Root cause:** filled in from the 5 whys analysis

Present all findings to the user with their root causes.

## Phase 2: Process all pending observations

Follow the retrospective process from `retro-process.md`:

1. Load all pending observations from `~/.claude/retro/observations.md` (including those just added from Phase 1)
2. Present one at a time — ask if worth addressing
3. For confirmed findings, use the `claude-code-optimizer` skill to research and propose solutions
4. Pass the solution hierarchy as context to the optimizer — solutions should be ordered from most to least durable
5. User picks a solution — implement it immediately
6. Update observation status and append to `~/.claude/retro/log.md`
7. Continue until all pending observations are processed
8. Summarize: "Improve complete. N findings reviewed, M addressed, K skipped."
