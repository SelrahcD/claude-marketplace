---
name: review
description: Analyze the current conversation for errors, inefficiencies, and friction, then perform 5 whys root cause analysis
---
Read the `improve` skill for the observation format and storage location.

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

Do NOT implement solutions — that's what `/retro` is for.
