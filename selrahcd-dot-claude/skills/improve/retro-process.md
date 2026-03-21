# Retrospective Process

This is the orchestration flow for `/retro`. Follow these steps in order.

## Step 1: Load Observations

Read pending observations from `~/.claude/retro/observations.md`. Filter to entries with `**Status:** pending`. If none found, tell the user: "No pending observations. Use `/note` to capture observations or `/review` to scan the current conversation."

## Step 2: Present One at a Time

For each pending observation:

- **With root cause:** Present the finding and root cause analysis. Ask: "Is this worth addressing?"
- **Without root cause:** Ask clarifying questions to understand the issue. Perform a brief 5 whys analysis (2-3 levels deep). Then ask: "Is this worth addressing?"

If user says no: mark as `skipped` in observations.md, move to next.

## Step 3: Delegate to Optimizer

For confirmed observations, use the `claude-code-optimizer` skill with:

- **Problem statement:** The observation details
- **Root cause:** The 5 whys analysis
- **Context:** Pass the solution hierarchy from [solution-hierarchy.md](solution-hierarchy.md) — the optimizer should propose solutions ordered from most to least durable

The optimizer researches what's possible, validates feasibility, and proposes concrete solutions.

## Step 4: User Picks Solution

Present the optimizer's proposals. User selects which solution to implement. If user wants none: mark as `skipped`.

## Step 5: Implement Immediately

Implement the selected solution right now. This is the key differentiator — retro produces working improvements, not action items.

## Step 6: Update Records

After implementation:

1. In `~/.claude/retro/observations.md`: update the observation's status to `addressed` and fill in the **Resolution** field
2. In `~/.claude/retro/log.md`: append a new log entry with the improvement details

## Step 7: Continue and Summarize

Move to the next pending observation. After all are processed, summarize:

"Retro complete. N findings reviewed, M addressed, K skipped."
