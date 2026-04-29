---
name: vault-index
description: Use when working with the Obsidian vault via MCP (reading, writing, or referencing notes), or when the user mentions a tracked effort (refactor, migration, investigation, ongoing work). Surfaces the tracked notes index from the repo's `.claude/obsidian-bridge.json` and prompts registration of new long-lived notes.
---

# Vault Index

Help the agent reach for the right Obsidian vault note without scanning, by surfacing a small per-repo index of tracked notes and registering new long-lived ones as they are created.

## When this skill applies

Invoke this skill whenever the current task involves the Obsidian vault — explicit MCP calls (`mcp__obsidian__read_note`, `mcp__obsidian__write_note`, `mcp__obsidian__patch_note`, etc.) or the user talking about something they're tracking, following up on, or maintaining notes about across sessions.

## Steps

### 1. Load the index

1. Run `git rev-parse --show-toplevel` to find the repo root.
2. Read `.claude/obsidian-bridge.json` from the repo root.
3. If the file does not exist, exit silently — this skill is a no-op outside configured repos.
4. Parse the file. The schema:

   ```json
   {
     "project": "Project Name",
     "tags": ["tag-a"],
     "notes": ["🦺 Projects/Project Name.md"],
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

5. The `tracking` array is optional. Treat the top-level `project` / `tags` / `notes` as the always-on default entry. For matching purposes (step 2), the top-level entry uses its `project` name and top-level `tags` as the match target in place of `description`/`label`.
6. List the project entry and each `tracking[]` entry (label / project name, description, note paths) so subsequent steps and the user have the index visible.
7. If the current task is read-only (e.g., `mcp__obsidian__read_note` only, no write), the loaded index is now available for the agent's reasoning — no further action from this skill is required.

### 2. Before writing or appending a note via Obsidian MCP

Check whether the current topic semantically matches an existing entry's `description` or `label` (use your own judgment — this is **not** a substring match). If a match is found, surface that entry's note paths to the user as a candidate destination *before* proposing a fresh one.

Example:

> "This looks related to the tracked entry **auth-refactor** (`🦺 Projects/Auth Refactoring.md`). Append to that note, or create a new one?"

If multiple entries match, list them and let the user pick. If none match, fall back to the normal location-proposal flow (whatever the calling command or context already does).

### 3. After writing a new note via Obsidian MCP

Apply the registration heuristic. Prompt "Add this to tracking?" only when **at least one** of these signals is present:

- The note documents an **ongoing effort** — refactor, migration, investigation, multi-session debugging.
- The note is structured to be **appended over time** — has a "Progress", "Decisions", "Log", or similar section.
- The user explicitly said **"track"**, **"follow up"**, **"keep notes on"**, or a close variant.
- The user invoked `/track` with a topic that names an effort rather than a one-off insight.

If at least one signal matches, prompt with a single y/N including a suggested `label` (kebab-cased from the topic):

> "This note looks like it could be revisited later. Add to `.claude/obsidian-bridge.json` tracking as **`<suggested-label>`**? (y/N)"

On accept, append the new entry to `.claude/obsidian-bridge.json`:

```json
{
  "label": "<suggested-label>",
  "description": "<one-sentence description of the effort>",
  "notes": ["<path that was just written>"],
  "tags": ["<suggested-label>"]
}
```

If the file does not yet contain a `tracking` array, create it. Preserve the rest of the file untouched (no reformatting of unrelated keys).

On decline, do **not** ask again for the same note within this session. Other notes still go through the check.

## Notes

- This skill is purely instructional. It does not introduce new tools.
- The `track` and `til` commands embed the same registration logic inline so they remain self-contained when used explicitly. Keep the wording in this skill and in those commands consistent if you change one.
