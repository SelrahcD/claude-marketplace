---
name: til
description: Adds a TIL (Today I Learned) entry to the daily note, optionally creating a standalone note for deeper topics. Use when you learned something, TIL, today I learned, or want to note a quick discovery.
argument-hint: "[optional TIL description]"
---

# TIL — Today I Learned

Capture something you just learned as a TIL entry in today's daily note. Quick facts become inline bullets; deeper topics get their own standalone note with a wiki-link in the daily note.

## Steps

### 1. Load project config

Check if `.obsidian-bridge.json` exists at the git repo root (use `git rev-parse --show-toplevel`). If found, read it to get the project name and tags. These will be used later for tagging and context. If not found, continue without project context.

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

### 5. Draft content

**If inline format:** Draft 1-3 concise bullet points. Use `[[wiki-links]]` to related concepts where appropriate.

**If standalone note format:** Draft two things:
1. The full standalone note with:
   - A `# Title` heading
   - Tags from the project config (formatted as `#tag` inline below the title)
   - A clear explanation of the learning
   - Examples or code snippets if relevant
   - `[[wiki-links]]` to related notes
2. The TIL section entry: a wiki-link to the new note with a brief summary.

### 6. Present draft for validation

Show the complete draft to the user — the TIL entry and the standalone note content if applicable. Ask them to approve it or request changes. Do **NOT** write anything to the vault until the user explicitly approves.

### 7. Write content

**If standalone note:** Propose a location for the note first. Use the Obsidian MCP `list_directory` tool to check what folders exist in the vault. Suggest a location based on the topic (technical concepts under `🧠 Ressources/`, project-specific near the project note, general at vault root). Default to vault root if unsure. Ask the user to confirm the path. Then create the note with `write_note`.

**For both formats:** Read today's daily note at `🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md` (using today's date) with `read_note`. Find the `## TIL ?` section. Use `patch_note` to append the entry at the end of the TIL section (before the next `##` heading). Ensure blank line spacing for valid markdown.

Entry format for inline:
```
- **Topic title**: concise explanation with [[wiki-links]]
```

Entry format for standalone link:
```
- [[Note Title]] — brief one-line summary
```

If the daily note doesn't exist or the TIL section can't be found, tell the user and skip this step.

### 8. Confirm

Tell the user:
- What was added to the TIL section (inline bullets or a wiki-link)
- The standalone note path if one was created
- If the daily note update was skipped and why
