---
name: prepare-for-ai
description: Audit a codebase for AI-readability smells (hidden domain, naming, conditionals, cohesion, module boundaries) and apply fixes one at a time via the refactoring skill. Two phases — scan then apply — with a review gate between.
---

Audit and prepare a codebase for AI agents. Find code that hides intent, hurts local reasoning, or forces shotgun surgery, then fix it one refactor at a time.

Optional argument: `$ARGUMENTS` — a path or glob to scope the scan. If empty, ask in Phase 0.

## Phase 0 — Mode selection

Use `AskUserQuestion` with one question:

- **Question**: "How should /prepare-for-ai scope the scan?"
- **Header**: "Mode"
- **Options**:
  - **Hotspots × smells** — "Use `git log` churn (last 6 months) crossed with file size to scan the top ~15 hotspots. Tornhill-style: only refactor code that actually changes." *(Recommended)*
  - **Severity only** — "Scan everything in the repository, rank by smell weight (god file > hidden domain > conditional maze > naming). Expensive on large repos."
  - **User-directed** — "Scan only a path / glob you provide."

If the user picks **User-directed** and `$ARGUMENTS` is empty, ask a follow-up: "Which path or glob?"

If `$ARGUMENTS` is non-empty, default the question to **User-directed** with the provided scope but still confirm the mode.

## Phase 1 — Scan (delegated to subagent)

Invoke the `prepare-for-ai-scanner` subagent via the `Agent` tool. Pass:

- `mode`: the choice from Phase 0
- `scope`: resolved file list or root path
- For hotspot mode, do not pre-resolve hotspots — let the subagent compute them. Pass only the repository root.

The subagent returns a structured report in chat (see the report format in `skills/prepare-for-ai/SKILL.md`). Capture it.

If the report says "No findings in scope", state that and stop. Offer to widen scope or try another mode.

## Phase 2 — Present findings

Show the user the subagent's report verbatim. Then ask:

```
Pick findings to refactor by number (e.g. "2, 5, 11"),
or "all" to apply every actionable finding in order,
or "quit" to stop here.

Note: findings under "Tech-layer organization" are report-only —
slice extraction is a human-led decision and will be skipped if
included in your selection.
```

Parse the user's reply. Filter out any selected findings whose category is "Tech-layer organization" and tell the user they were skipped with the reason.

## Phase 3 — Apply (one refactor at a time)

For each selected finding, in the order the user listed them:

1. **Announce** the finding being addressed: `"Refactor N/M: <category> in <file:line> — <focal symbol>"`.
2. **Load the refactor recipe**: read `skills/prepare-for-ai/smells/<NN-name>.md`. The "Refactor recipe" section names the Fowler refactorings to apply.
3. **Hand off to the `refactoring` skill** (`skills/refactoring/SKILL.md`). Seed its SETUP state with:
   - **Target**: the file:line and focal symbol from the finding.
   - **Goal** (in user's words, paraphrased): "Apply <category> remediation: <one-line refactor description from the smell file>." For example: *"Apply Switch-as-Table remediation: replace the constant-returning switch in `recommendSnack` with a `Map<Creature, SnackRecommendation>` lookup."*
   - The refactoring skill handles plan, safety net, per-refactoring commits, and verification. Each named refactoring becomes its own commit. A smell fix may take several commits — that is expected.
4. **After the refactoring skill returns COMPLETE**: confirm the smell is resolved (re-read the file briefly). If a follow-up smell surfaced during the refactor, mention it but do not act on it — it goes in a new run if the user wants.
5. **Gate**: ask the user explicitly:
   - "Continue to the next refactor?"
   - "Skip the next one?"
   - "Stop here?"

   This gate is deliberate — agentic refactoring at speed produces cognitive overload (Tornhill, *Compressed Cognition*). Force a deliberate cadence.

If the refactoring skill transitions to BLOCKED or VIOLATION_DETECTED, stop the loop. Report what happened. Do not move to the next finding.

## Phase 4 — Wrap-up

When the loop ends (by completion, skip-to-stop, or user halt):

1. List the commits produced (`git log --oneline <starting-ref>..HEAD`).
2. Summarise: N refactors attempted, M completed, K skipped.
3. Mention any tech-layer findings the user should think about manually.
4. Suggest re-running `/prepare-for-ai` after a few feature changes to catch new hotspots.

## Rules

- **No file edits outside the refactoring skill.** The command orchestrates; the refactoring skill executes.
- **No batch refactoring.** Always one finding at a time, with a user gate between.
- **Tech-layer findings are never applied.** Report only.
- **The scanner is read-only.** It returns a report in chat; nothing on disk.
- **One smell can produce several commits.** That is fine — the refactoring skill enforces one Fowler refactoring per commit, and a smell may need a chain of refactorings.
