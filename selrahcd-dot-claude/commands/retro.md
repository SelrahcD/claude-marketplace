---
name: retro
description: Process pending observations with root cause analysis, find optimal solutions via the claude-code-optimizer, and implement improvements
---
Read the `improve` skill and its supporting files:
- `retro-process.md` for the orchestration flow
- `solution-hierarchy.md` for the prioritization framework

Follow the retrospective process from `retro-process.md` exactly:

1. Load pending observations from `~/.claude/retro/observations.md`
2. Present one at a time — ask if worth addressing
3. For confirmed findings, use the `claude-code-optimizer` skill to research and propose solutions
4. Pass the solution hierarchy as context to the optimizer — solutions should be ordered from most to least durable
5. User picks a solution — implement it immediately
6. Update observation status and append to `~/.claude/retro/log.md`
7. Continue until all pending observations are processed
8. Summarize: "Retro complete. N findings reviewed, M addressed, K skipped."
