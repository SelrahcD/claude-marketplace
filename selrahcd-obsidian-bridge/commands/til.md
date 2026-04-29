---
name: til
description: Adds a TIL (Today I Learned) entry to the daily note, optionally creating a standalone note for deeper topics. Use when you learned something, TIL, today I learned, or want to note a quick discovery.
argument-hint: "[optional TIL description]"
---

# TIL — Today I Learned

Capture something you just learned as a TIL entry in today's daily note. Quick facts become inline bullets; deeper topics get their own standalone note with a wiki-link in the daily note.

## Steps

### 1. Load project config

Check if `.claude/obsidian-bridge.json` exists at the git repo root (use `git rev-parse --show-toplevel`). If found, read it to get:

- `project` and top-level `tags` — used for tagging and context later.
- `notes` — the always-on project notes.
- `tracking[]` (optional) — additional ad-hoc tracked entries. Each has `label`, `description`, `notes`, and an optional `tags` (falls back to top-level `tags`).

Treat the top-level project (`project` / `tags` / `notes`) as the always-on default entry. For the matching logic in step 5, the top-level entry uses its `project` name and top-level `tags` as the match target in place of `description`/`label`.

Keep the loaded entries (project + each `tracking[]` entry) available to subsequent steps. If the config file is not found, continue without project context.

### 2. Detect topic

If `$ARGUMENTS` was provided, use it as the TIL topic hint.

Otherwise, analyze the current conversation to identify what the user learned. Look for:
- New APIs, tools, or libraries discovered
- Techniques or patterns applied
- Surprising behaviors or gotchas encountered
- Concepts that were clarified or clicked into place

### 3. Confirm topic

Present the detected TIL topic as a short phrase to the user. Ask them to confirm or adjust. Wait for their response before continuing.

Example: "TIL topic: **React useActionState hook manages async state with automatic pending tracking**. Is this right, or would you phrase it differently?"

### 4. Decide format

Based on the topic complexity, propose one of two formats:

- **Inline entry**: For quick facts. 1-3 bullet points appended to the TIL section of the daily note.
- **New note + link**: For deeper topics that deserve more explanation, code examples, or context. A standalone note is created and a wiki-link is added to the TIL section.

Present both options with your recommendation. Ask the user to confirm.

Example: "This seems like a quick fact — I'd suggest **inline bullets**. Or would you prefer a **standalone note** for more detail?"

### 5. Propose note location (standalone only)

If the user chose **standalone note** format, propose a location before drafting.

**First**, scan the entries you loaded in step 1 (the always-on project entry plus any `tracking[]` entries). For each entry, check whether its match target semantically matches the topic (`description` and `label` for tracking entries; `project` name and top-level `tags` for the always-on entry). Use your judgment — this is not a substring check.

If any entry matches, offer that entry's note path as the **first option**:

> "This looks related to the tracked entry **<label or project name>** (`<note path>`). Append to that note, or create a new one?"

If multiple entries match, list them all and let the user pick. If the user picks a tracked note, skip the location-suggestion logic below and use that path as the destination. Note whether the final destination is an existing tracked entry or a new note — step 9 uses this.

Otherwise, use the Obsidian MCP `list_directory` tool to check what folders exist in the vault. Suggest a location based on the topic:

- **Technical concepts** (language features, libraries, patterns) → a subfolder under `🧠 Ressources/`
- **Project-specific learnings** → near the project note if one is referenced in `.claude/obsidian-bridge.json`
- **General insights** → vault root

Default to `📝 Notes/` if no clear directory matches the topic. Present the suggested path (folder + filename) and ask the user to confirm. Use the topic phrase as the filename with words capitalized.

Skip this step for inline format.

### 6. Draft content

**If inline format:** Draft 1-3 concise bullet points. Use `[[wiki-links]]` to related concepts where appropriate.

**If standalone note format:** Draft two things:
1. The full standalone note with:
   - A `# Title` heading
   - Tags formatted as `#tag` inline below the title. Tag source: if the destination is a tracked entry, use that entry's `tags` (falling back to top-level `tags` when the entry omits its own); otherwise use the top-level `tags`.
   - A clear explanation of the learning
   - Examples or code snippets if relevant
   - `[[wiki-links]]` to related notes
2. The TIL section entry: a wiki-link to the new note with a brief summary.

### 7. Present draft for validation

Show the complete draft to the user — the TIL entry and the standalone note content if applicable. Ask them to approve it or request changes. Do **NOT** write anything to the vault until the user explicitly approves.

### 8. Write content

1. **If standalone note:** Use `write_note` to create the note at the confirmed path.
2. Compute today's daily note path: `🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md` (using today's date).
3. Use `read_note` to read the daily note.
4. If the daily note doesn't exist, tell the user and skip the remaining sub-steps.
5. Find the `## TIL ?` section.
6. Use `patch_note` to append the entry at the end of the TIL section (before the next `##` heading). Ensure blank line spacing for valid markdown.

Entry format for inline:
```
- **Topic title**: concise explanation with [[wiki-links]]
```

Entry format for standalone link:
```
- [[Note Title]] — brief one-line summary
```

### 9. Offer to register in tracking (standalone only)

If the user chose **inline format** (no standalone note was created), skip this step.

If the destination of the standalone note (chosen in step 5) was an **already-tracked entry**, skip this step.

Otherwise, apply the registration heuristic. Prompt "Add this to tracking?" only when **at least one** of these signals is present:

- The note documents an **ongoing effort** — refactor, migration, investigation, multi-session debugging.
- The note is structured to be **appended over time** — has a "Progress", "Decisions", "Log", or similar section.
- The user explicitly said **"track"**, **"follow up"**, **"keep notes on"**, or a close variant.
- The user invoked `/til` for a topic that names an ongoing effort rather than a one-off fact.

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

On decline, do not ask again for the same note in this session. Other notes still go through the check.

### 10. Confirm

Tell the user:
- What was added to the TIL section (inline bullets or a wiki-link)
- The standalone note path if one was created
- If the daily note update was skipped and why
- Whether a tracking entry was registered (and under which label)
