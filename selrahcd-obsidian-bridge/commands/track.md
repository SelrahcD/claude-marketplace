---
name: track
description: Captures a learning, insight, or discovery from the current session into an Obsidian note and links it in the daily note. Use when you want to track, save, log, or remember something.
argument-hint: "[optional topic description]"
---

# Track Learning to Obsidian

Capture a notable learning, insight, or discovery from the current conversation and save it as a structured Obsidian note.

## Steps

### 1. Load project config

Check if `.claude/obsidian-bridge.json` exists at the git repo root (use `git rev-parse --show-toplevel`). If found, read it to get:

- `project` and top-level `tags` — used for tagging and context later.
- `notes` — the always-on project notes.
- `tracking[]` (optional) — additional ad-hoc tracked entries. Each has `label`, `description`, `notes`, and an optional `tags` (falls back to top-level `tags`).

Treat the top-level project (`project` / `tags` / `notes`) as the always-on default entry. For the matching logic in step 4, the top-level entry uses its `project` name and top-level `tags` as the match target in place of `description`/`label`.

Keep the loaded entries (project + each `tracking[]` entry) available to subsequent steps. If the config file is not found, continue without project context.

### 2. Detect topic

If `$ARGUMENTS` was provided, use it as the topic hint.

Otherwise, analyze the current conversation to identify the most notable learning, insight, or discovery. Look for:
- New concepts the user encountered
- Surprising behavior or gotchas
- Techniques or patterns applied
- Decisions made and their rationale

### 3. Confirm topic

Present the detected topic as a short phrase (3-8 words) to the user. Ask them to confirm or adjust. Wait for their response before continuing.

Example: "I'd like to track: **Scrutiny Mode pattern for review-friendly refactoring**. Does this capture what you want to track, or would you prefer a different topic?"

### 4. Propose note location

**First**, scan the entries you loaded in step 1 (the always-on project entry plus any `tracking[]` entries). For each entry, check whether its match target semantically matches the topic (`description` and `label` for tracking entries; `project` name and top-level `tags` for the always-on entry). Use your judgment — this is not a substring check.

If any entry matches, offer that entry's note path as the **first option**:

> "This looks related to the tracked entry **<label or project name>** (`<note path>`). Append to that note, or create a new one?"

If multiple entries match, list them all and let the user pick. If the user picks a tracked note, skip the location-suggestion logic below and use that path as the destination. Note whether the final destination is an existing tracked entry or a new note — step 9 uses this.

Otherwise, use the Obsidian MCP `list_directory` tool to check what folders exist in the vault. Suggest a location based on the topic:

- **Technical concepts** (language features, libraries, patterns) → a subfolder under `🧠 Ressources/`
- **Project-specific learnings** → near the project note if one is referenced in `.claude/obsidian-bridge.json`
- **General insights** → vault root

Default to `📝 Notes/` if no clear directory matches the topic. Present the suggested path (folder + filename) to the user and ask them to confirm or provide a different location. Use the topic phrase as the filename with words capitalized.

Example: "I'll create the note at **🧠 Ressources/Development/Scrutiny Mode - Review-Friendly Refactoring Pattern.md**. Good location, or would you prefer somewhere else?"

### 5. Draft note content

Generate a structured Obsidian note with:

- A `# Title` heading matching the topic
- Tags formatted as `#tag` inline below the title. Tag source: if the destination is a tracked entry, use that entry's `tags` (falling back to top-level `tags` when the entry omits its own); otherwise use the top-level `tags`.
- A short summary paragraph of the learning (2-3 sentences)
- Key points, details, or code snippets as bullet points or fenced code blocks
- `[[wiki-links]]` to related notes where appropriate

### 6. Present draft for validation

Show the complete note content to the user. Ask them to approve it or request changes. Do **NOT** write anything to the vault until the user explicitly approves.

### 7. Write the note

Use the Obsidian MCP `write_note` tool to create the note at the confirmed path.

### 8. Link in daily note

Compute today's daily note path: `🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md` (using today's date).

Use the Obsidian MCP `read_note` tool to read the daily note. Find the `## What did I do?` section, then locate the tasks code block (` ```tasks ... ``` `).

Use `patch_note` to insert a bullet point **after** the closing backticks of that tasks block. Ensure there is a blank line before and after the inserted entry for valid markdown spacing:

```
- Tracked: [[Note Title]] #tag1 #tag2
```

If the daily note doesn't exist or the section can't be found, tell the user and skip this step.

### 9. Offer to register in tracking

If the destination of the note (chosen in step 4) was an **already-tracked entry**, skip this step.

Otherwise, apply the registration heuristic. Prompt "Add this to tracking?" only when **at least one** of these signals is present:

- The note documents an **ongoing effort** — refactor, migration, investigation, multi-session debugging.
- The note is structured to be **appended over time** — has a "Progress", "Decisions", "Log", or similar section.
- The user explicitly said **"track"**, **"follow up"**, **"keep notes on"**, or a close variant.
- The user invoked `/track` with a topic that names an effort rather than a one-off insight.

If at least one signal matches, prompt with a single y/N including a suggested `label` (kebab-cased from the topic):

> "This note looks like it could be revisited later. Add to `.claude/obsidian-bridge.json` tracking as **`<suggested-label>`**? (y/N)"

On accept, append a new entry to the `tracking[]` array in `.claude/obsidian-bridge.json`:

```json
{
  "label": "<suggested-label>",
  "description": "<one-sentence description of the effort>",
  "notes": ["<path that was just written>"],
  "tags": ["<suggested-label>"]
}
```

If the file does not yet contain a `tracking` array, create it. Preserve the rest of the file untouched.

On decline, do not ask again for the same note in this session.

### 10. Confirm

Tell the user:
- The note was created, including its full vault path
- Whether the daily note was updated or skipped
- Whether a tracking entry was registered (and under which label)
