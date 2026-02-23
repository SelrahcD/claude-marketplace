---
name: track
description: Captures a learning, insight, or discovery from the current session into an Obsidian note and links it in the daily note. Use when you want to track, save, log, or remember something.
argument-hint: "[optional topic description]"
---

# Track Learning to Obsidian

Capture a notable learning, insight, or discovery from the current conversation and save it as a structured Obsidian note.

## Steps

### 1. Load project config

Check if `.claude/obsidian-bridge.json` exists at the git repo root (use `git rev-parse --show-toplevel`). If found, read it to get the project name and tags. These will be used later for tagging and context. If not found, continue without project context.

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

Use the Obsidian MCP `list_directory` tool to check what folders exist in the vault. Suggest a location based on the topic:

- **Technical concepts** (language features, libraries, patterns) → a subfolder under `🧠 Ressources/`
- **Project-specific learnings** → near the project note if one is referenced in `.claude/obsidian-bridge.json`
- **General insights** → vault root

Default to vault root if unsure. Present the suggested path (folder + filename) to the user and ask them to confirm or provide a different location. Use the topic phrase as the filename with words capitalized.

Example: "I'll create the note at **🧠 Ressources/Development/Scrutiny Mode - Review-Friendly Refactoring Pattern.md**. Good location, or would you prefer somewhere else?"

### 5. Draft note content

Generate a structured Obsidian note with:

- A `# Title` heading matching the topic
- Tags from the project config (formatted as `#tag` inline below the title)
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

### 9. Confirm

Tell the user:
- The note was created, including its full vault path
- Whether the daily note was updated or skipped
