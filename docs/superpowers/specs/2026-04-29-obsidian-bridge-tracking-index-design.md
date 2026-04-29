# Obsidian Bridge — Tracking Index

**Date:** 2026-04-29
**Plugin:** `selrahcd-obsidian-bridge`

## Problem

The plugin's per-repo config (`.claude/obsidian-bridge.json`) tracks only a single project entry — a project name, tags, and a flat list of project notes. When a user is working on a long-lived effort within the project (a refactor, a migration, an investigation), there is no way for the agent to know which Obsidian note is the "current focus" without scanning the vault.

The goal: let the repo carry a small, structured index of *all* the vault notes that are relevant to ongoing work, so the agent can append to the right note without searching, and so new long-lived notes get registered as they are created.

## Schema

The config file is extended additively. Existing fields keep their meaning. A new optional `tracking[]` array carries additional focus areas.

```json
{
  "project": "Claude Marketplace",
  "tags": ["claude-marketplace"],
  "notes": ["🦺 Projects/Claude Marketplace.md"],
  "tracking": [
    {
      "label": "auth-refactor",
      "description": "Migration of auth middleware to new session token format",
      "notes": ["🦺 Projects/Auth Refactoring.md"],
      "tags": ["auth-refactor"]
    }
  ]
}
```

Per tracking entry:
- `label` — kebab-case identifier, unique within the file.
- `description` — human-readable sentence describing what this entry is about.
- `notes` — array of vault-relative paths.
- `tags` — optional. Falls back to the top-level `tags` when absent.

Backwards compatibility: configs that lack `tracking` keep working untouched.

## New skill: `vault-index`

**Path:** `selrahcd-obsidian-bridge/skills/vault-index/SKILL.md`.

**Frontmatter:**
- `name: vault-index`
- `description:` Triggers when working with the Obsidian vault via MCP (reading, writing, or referencing notes) or when the user mentions a tracked effort (refactor, migration, investigation, ongoing work). Surfaces the tracked notes index from `.claude/obsidian-bridge.json` and prompts registration of new long-lived notes.

**Responsibilities (in order):**

1. **Load the index.** Run `git rev-parse --show-toplevel` to find the repo root. Read `.claude/obsidian-bridge.json`. List the `project` entry and each entry from `tracking[]` with label, description, and note paths. If the file is missing, exit silently — the skill is a no-op outside configured repos.

2. **Before writing or appending a note via Obsidian MCP**, check whether the topic semantically matches an existing entry's `description` or `label` (the agent judges the match — not a string substring check). If it does, surface that entry's note paths as a candidate destination *before* proposing a fresh one.

3. **After writing a new note via Obsidian MCP**, apply the registration heuristic. The skill prompts "Add this to tracking?" only when at least one of these signals is present:
   - The note documents an **ongoing effort** — refactor, migration, investigation, multi-session debugging.
   - The note is structured to be **appended over time** — has a "Progress", "Decisions", "Log", or similar section.
   - The user explicitly said **"track"**, **"follow up"**, **"keep notes on"**, or a close variant.
   - The user invoked `/track` with a topic that names an effort rather than a one-off insight.

   On a match, the skill prompts with a single y/N including a suggested `label` derived from the topic (kebab-cased). On accept, it appends the entry to `.claude/obsidian-bridge.json`. On decline, it does not ask again for that same note within the session — other notes still go through the check.

The skill is purely an instruction set. It does not introduce new tools.

## Command edits

### `track.md` and `til.md`

Two changes to each file, applied identically:

1. **Step "Load project config"**: extend to read the optional `tracking[]` array. Make the loaded entries (project + tracking) available to subsequent steps.

2. **Step "Propose note location"**: before suggesting a fresh location, scan tracked entries. If any entry's `description` or `label` semantically matches the topic, offer that entry's note path as the first option ("Append to tracked note `<path>`?" vs. "Create a new note?"). If none match, fall through to the existing logic.

3. **New step inserted between "Link in daily note" and "Confirm"**: apply the registration heuristic from the skill (same signals, same wording). If signals match, prompt "Add this to tracking?" with a suggested label. On accept, append to `.claude/obsidian-bridge.json`. The logic is inlined in each command rather than delegated to the skill — keeps commands self-contained and readable.

### `init-obsidian-bridge.md`

Minor update only:
- In step 6 ("Write the config file"), add a one-line note that the schema also supports an optional `tracking[]` array with a brief example.
- Do **not** prompt for tracking entries during init. They are added later via `/track`, `/til`, or by the skill on organic MCP calls.

## Files touched

- `selrahcd-obsidian-bridge/skills/vault-index/SKILL.md` (new)
- `selrahcd-obsidian-bridge/commands/track.md` (edit)
- `selrahcd-obsidian-bridge/commands/til.md` (edit)
- `selrahcd-obsidian-bridge/commands/init-obsidian-bridge.md` (edit)
- `selrahcd-obsidian-bridge/.claude-plugin/plugin.json` (version bump, declare `skills` path)
- `.claude-plugin/marketplace.json` (version bump)
- `selrahcd-obsidian-bridge/README.md` (document the new skill and schema)

## Out of scope

- A dedicated command to add or remove tracking entries (we picked lazy-registration through the existing surfaces).
- Migrating the implicit `project` entry into the `tracking[]` array (kept as a privileged top-level field).
- Validating that tracked note paths actually exist in the vault — left to the user.
- A PreToolUse hook on `mcp__obsidian__*` — considered as a safety net, deferred until skill triggering proves unreliable.
