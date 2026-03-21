# Continuous Improvement Loop — Design

## Philosophy

Every friction moment is an improvement opportunity. The loop has three phases:

1. **Capture** (`/note`) — Log observations during work. Quick, low-friction.
2. **Review** (`/review`) — Scan the conversation for unlogged issues with 5 whys root cause analysis.
3. **Retrospective** (`/retro`) — Process all pending observations, delegate to `claude-code-optimizer` to find the best solution, then implement immediately.

The output isn't a document. It's **working improvements** to skills, commands, CLAUDE.md, AGENTS.md, hooks, linter rules, etc.

## Commands

### `/note "description"` — Quick capture

- Appends to `~/.claude/retro/observations.md`
- Captures: timestamp, description, current project, what was happening
- Claude may suggest noting obvious failures (errors, multiple retries, user corrections) — user confirms before logging
- Fast: "Noted." and back to work
- No analysis — just records what happened and context

### `/review` — Conversation analysis with 5 whys

- Scans the current conversation for:
  - Errors: failed commands, wrong paths, syntax errors, test failures
  - Inefficiencies: multiple searches, irrelevant file reads, repeated patterns
  - Corrections: user corrections, reverted changes, abandoned approaches
  - Friction: moments where the workflow felt slow or awkward
- For each finding, performs 5 whys root cause analysis while context is fresh
- Saves analyzed findings to `~/.claude/retro/observations.md` with root cause attached
- Presents findings to user for awareness
- Does NOT implement solutions (that's `/retro`)

### `/retro` — Process observations and implement improvements

- Reads all pending observations from `~/.claude/retro/observations.md`
- Presents one at a time:
  - For observations with root cause: presents the finding and root cause
  - For observations without root cause: asks clarifying questions first
- User confirms the finding is worth addressing
- Delegates to the `claude-code-optimizer` skill with the problem statement and root cause
- Optimizer researches and proposes validated solutions ordered by the solution hierarchy
- User picks a solution → Claude implements it immediately
- Updates observation status to `addressed` or `skipped`
- Logs the improvement to `~/.claude/retro/log.md`
- Continues to next observation until all are processed
- Summary: "Retro complete. N findings reviewed, M addressed, K skipped."

## Proactive Suggestions

During normal work (not just during `/note`), Claude may suggest capturing an observation when it spots clear failures:

- Failed commands (non-zero exit codes)
- Multiple search attempts for the same thing
- User corrections to Claude's work

Claude asks: "Want me to note this for review?" — only logs if user agrees. Never logs silently. Never suggests for minor issues.

## Storage

All files in `~/.claude/retro/`:

### `observations.md`

```markdown
## [2026-03-21 14:32] Title

- **Status:** pending | addressed | skipped
- **Project:** project-name
- **Context:** What was happening when this was observed
- **Details:** The observation itself
- **Root cause:** (filled by /review, empty for /note captures)
- **Resolution:** (filled by /retro when addressed)
```

### `log.md`

Append-only audit trail of improvements made:

```markdown
## [2026-03-21 15:00] Improvement title

- **Source:** observation title or conversation finding
- **Root cause:** Why this happened
- **Solution:** What was implemented
- **Type:** skill | command | claude-md | hook | linter | test | type-system
- **Files changed:** list of modified files
```

## Solution Hierarchy

Used by the optimizer when proposing solutions. Most to least durable:

1. **Type system / compiler checks** — impossible to bypass
2. **Linter rules** — fast, deterministic, runs on every save
3. **Tests** — catches regressions, documents behavior
4. **Pre-commit hooks** — last automated gate before commit
5. **Claude hooks** — PreToolUse, PostToolUse, UserPromptSubmit
6. **Skills or commands** — new or improved existing ones
7. **CLAUDE.md / AGENTS.md** — project context and conventions
8. **Prompt instructions** — least durable, only when nothing else fits

## File Structure

```
selrahcd-dot-claude/
├── skills/improve/
│   ├── SKILL.md                 # Philosophy + observation format + proactive rules
│   ├── retro-process.md         # Retro orchestration flow
│   └── solution-hierarchy.md    # Prioritization framework
├── commands/
│   ├── note.md                  # /note — quick capture
│   ├── review.md                # /review — conversation scan + 5 whys
│   └── retro.md                 # /retro — process + optimize + implement
```

## Flow Diagram

```
/note ──→ observations.md ←── /review (with 5 whys)
                │
            /retro
                │
    ┌───────────┴───────────┐
    │  For each observation  │
    │  1. Present finding    │
    │  2. Confirm worth it   │
    │  3. → claude-code-     │
    │     optimizer          │
    │  4. Pick solution      │
    │  5. Implement          │
    │  6. Log to log.md      │
    └────────────────────────┘
```

## Inspiration Sources

- [review-conversation skill](handfree-recipe project) — note capture, AskUserQuestion review, solution hierarchy
- [NTCoding track-and-improve](https://github.com/NTCoding/claude-skillz/tree/main/track-and-improve) — 5 whys root cause analysis
- [Self-Improving Coding Agents](https://addyosmani.com/blog/self-improving-agents/) — compound learning, 4 memory channels
- [MindStudio Learnings Loop](https://www.mindstudio.ai/blog/how-to-build-learnings-loop-claude-code-skills) — raw observations → consolidated principles
- [claude-reflect](https://github.com/BayramAnnakov/claude-reflect) — hybrid capture + review
- [AccidentalRebel Session Retrospective](https://www.accidentalrebel.com/building-a-session-retrospective-skill-for-claude-code.html) — JSONL session analysis
