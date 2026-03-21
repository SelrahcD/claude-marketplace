---
name: improve
description: Continuous improvement feedback loop that captures observations during work (/note), analyzes root causes with 5 whys (/review), and implements durable improvements via the claude-code-optimizer (/retro). Triggers on retrospective, retro, improvement, feedback loop, root cause, 5 whys, observation, friction.
---

# Continuous Improvement Loop

Every friction moment is an improvement opportunity. This skill powers a three-phase feedback loop:

1. **Capture** (`/note`) — Log observations during work. Quick, low-friction.
2. **Review** (`/review`) — Scan the conversation for unlogged issues with 5 whys root cause analysis.
3. **Retrospective** (`/retro`) — Process all pending observations, delegate to `claude-code-optimizer` to find the best solution, then implement immediately.

The output isn't a document. It's **working improvements** to skills, commands, CLAUDE.md, AGENTS.md, hooks, linter rules, etc.

## Storage

All files in `~/.claude/retro/`:

- `observations.md` — Pending and processed observations
- `log.md` — Append-only audit trail of improvements made

## Observation Format

Each observation in `observations.md` follows this template:

```markdown
## [YYYY-MM-DD HH:MM] Title

- **Status:** pending | addressed | skipped
- **Project:** project-name
- **Context:** What was happening when this was observed
- **Details:** The observation itself
- **Root cause:** (filled by /review, empty for /note captures)
- **Resolution:** (filled by /retro when addressed)
```

## Log Entry Format

Each entry in `log.md` follows this template:

```markdown
## [YYYY-MM-DD HH:MM] Improvement title

- **Source:** observation title or conversation finding
- **Root cause:** Why this happened
- **Solution:** What was implemented
- **Type:** skill | command | claude-md | hook | linter | test | type-system
- **Files changed:** list of modified files
```

## Proactive Suggestions

During normal work (not just during `/note`), you may suggest capturing an observation when you spot clear failures:

- Failed commands (non-zero exit codes)
- Multiple search attempts for the same thing
- User corrections to your work
- Repeated trial-and-error patterns

Ask: "Want me to note this for review?" — only log if user agrees. Never log silently. Never suggest for minor issues. One prompt, then move on.

## Supporting Files

- See [retro-process.md](retro-process.md) for the full retrospective orchestration flow
- See [solution-hierarchy.md](solution-hierarchy.md) for the prioritization framework used when proposing solutions
