# /track and /til Commands Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add two interactive commands to the obsidian-bridge plugin that let users capture learnings (/track) and TIL entries (/til) from the current conversation into their Obsidian vault.

**Architecture:** Each command is a standalone markdown file in `selrahcd-obsidian-bridge/commands/`. Commands are step-by-step instructions that Claude follows interactively, using Obsidian MCP tools (`read_note`, `write_note`, `patch_note`) to read and modify vault content. Both commands follow a detect-confirm-draft-validate-write flow.

**Tech Stack:** Claude Code commands (markdown with YAML frontmatter), Obsidian MCP tools

---

### Task 1: Create the /track command

**Files:**
- Create: `selrahcd-obsidian-bridge/commands/track.md`

**Step 1: Write the command file**

Create `selrahcd-obsidian-bridge/commands/track.md` with the following content:

```markdown
---
name: track
description: Create an Obsidian note to capture a learning or insight from the current conversation, with a link in the daily note. Use when the user wants to save something notable from the session.
argument-hint: "[optional topic description]"
---

# Track a Learning

Create an Obsidian note capturing a learning or insight from the current conversation, then link it in today's daily note.

## Steps

### 1. Load project config

Check if `.obsidian-bridge.json` exists in the current git repo root (use `git rev-parse --show-toplevel` to find it). If it exists, read it to get project name and tags. If it doesn't exist, continue without project context.

### 2. Detect topic

If `$ARGUMENTS` is provided and non-empty, use it as the topic hint.

If no arguments, analyze the current conversation to identify the most notable learning, insight, or discovery. Look for:
- New concepts or techniques discussed
- Patterns or approaches explored
- Key realizations or "aha" moments
- Solutions to non-trivial problems

### 3. Confirm topic with user

Present the detected topic to the user as a short title (3-8 words). Ask them to confirm or provide a different topic. Wait for their response before continuing.

Example: "I'd like to track: **Scrutiny Mode pattern for review-friendly refactoring**. Does this capture what you want to track, or would you prefer a different topic?"

### 4. Propose note location

Suggest a vault folder for the note based on the topic. Use the Obsidian MCP `list_directory` tool to check what top-level folders exist in the vault.

Consider the topic when suggesting:
- Technical concepts → `🧠 Ressources/` and an appropriate subfolder
- Project-specific learnings → near the relevant project note
- General insights → vault root

Default to the vault root if unsure. Present the proposed path (folder + filename) and ask user to confirm or change.

Example: "I'll create the note at **🧠 Ressources/Development/Scrutiny Mode - Review-Friendly Refactoring Pattern.md**. Good location, or would you prefer somewhere else?"

### 5. Draft note content

Generate a structured note with:
- A clear title as the first heading
- Tags from `.obsidian-bridge.json` if available (as `#tag` in the content)
- A concise but thorough summary of the learning from the conversation
- Key points, examples, or code snippets where relevant
- `[[wiki-links]]` to related Obsidian notes where appropriate

### 6. Present draft for validation

Show the complete note content to the user. Ask them to approve, request changes, or provide edits. Do NOT write anything until the user explicitly approves.

Example: "Here's the draft note. Approve to write it, or tell me what to change."

### 7. Write the note

Use the Obsidian MCP `write_note` tool to create the note at the confirmed path.

### 8. Link in daily note

1. Compute today's daily note path: `🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md` (use today's date)
2. Use Obsidian MCP `read_note` to read the daily note
3. If the daily note doesn't exist, tell the user and skip this step
4. Find the `## What did I do?` section
5. Within that section, find the tasks code block (` ```tasks ... ``` `)
6. Use Obsidian MCP `patch_note` to insert a bullet point with a `[[wiki-link]]` to the new note, immediately after the closing backticks of the tasks block. Add a blank line before and after.

The entry format:
```
- Tracked: [[Note Title]] #tag1 #tag2
```

### 9. Confirm

Tell the user:
- The note was created (with its path)
- The daily note was updated with a link (or that it was skipped and why)
```

**Step 2: Verify the file was created correctly**

Read back `selrahcd-obsidian-bridge/commands/track.md` and verify it has:
- YAML frontmatter with `name: track`, `description`, and `argument-hint`
- All 9 steps clearly documented
- References to correct MCP tools and daily note path pattern

**Step 3: Commit**

```bash
git add selrahcd-obsidian-bridge/commands/track.md
git commit -m "feat(obsidian-bridge): add /track command for capturing learnings"
```

---

### Task 2: Create the /til command

**Files:**
- Create: `selrahcd-obsidian-bridge/commands/til.md`

**Step 1: Write the command file**

Create `selrahcd-obsidian-bridge/commands/til.md` with the following content:

```markdown
---
name: til
description: Add a "Today I Learned" entry to the daily note's TIL section. Can be inline or a new note with a link. Use when the user learned something worth recording.
argument-hint: "[optional TIL description]"
---

# Today I Learned

Add a TIL entry to today's daily note. The entry can be inline bullet points for quick facts, or a standalone note linked from the TIL section for deeper topics.

## Steps

### 1. Load project config

Check if `.obsidian-bridge.json` exists in the current git repo root (use `git rev-parse --show-toplevel` to find it). If it exists, read it to get project name and tags. If it doesn't exist, continue without project context.

### 2. Detect topic

If `$ARGUMENTS` is provided and non-empty, use it as the TIL topic hint.

If no arguments, analyze the current conversation to identify what the user learned. Look for:
- New APIs, tools, or libraries discovered
- Techniques or patterns learned
- Surprising behaviors or gotchas encountered
- Concepts clarified or deepened

### 3. Confirm topic with user

Present the detected TIL topic as a short phrase. Ask user to confirm or adjust. Wait for their response before continuing.

Example: "TIL topic: **React useActionState hook manages async state with automatic pending tracking**. Is this right, or would you phrase it differently?"

### 4. Decide format

Based on the topic complexity, propose one of:
- **Inline entry**: For quick facts or simple learnings. 1-3 bullet points appended directly to the TIL section.
- **New note + link**: For deeper topics that deserve their own note. A standalone note is created, and a `[[wiki-link]]` is added to the TIL section.

Present both options and your recommendation. Ask the user which format they prefer.

Example: "This seems like a quick fact — I'd suggest **inline bullets**. Or would you prefer a **standalone note** for more detail?"

### 5. Draft content

**If inline:**
Draft 1-3 concise bullet points summarizing the TIL. Include `[[wiki-links]]` where relevant.

**If standalone note:**
Draft the full note content with:
- A clear title as the first heading
- Tags from `.obsidian-bridge.json` if available
- Thorough explanation of what was learned
- Examples, code snippets, or references where relevant
- `[[wiki-links]]` to related notes

Also draft the TIL section entry: a bullet with a `[[wiki-link]]` to the new note.

### 6. Present draft for validation

Show the complete draft to the user (inline bullets or full note + link). Ask them to approve, request changes, or provide edits. Do NOT write anything until the user explicitly approves.

### 7. Write content

**If standalone note:**
1. Use Obsidian MCP `write_note` to create the note at the chosen path
2. Propose the location first (same logic as /track step 4: suggest based on topic, default to vault root, ask user to confirm)

**For both formats:**
1. Compute today's daily note path: `🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md`
2. Use Obsidian MCP `read_note` to read the daily note
3. If the daily note doesn't exist, tell the user and skip the daily note update
4. Find the `## TIL ?` section
5. Use Obsidian MCP `patch_note` to append the entry (inline bullets or wiki-link) at the end of the TIL section, before the next `##` heading

**Inline entry format:**
```
- **Topic title**: concise explanation with [[wiki-links]]
```

**Standalone note link format:**
```
- [[Note Title]] — brief one-line summary
```

### 8. Confirm

Tell the user:
- What was added to the TIL section (inline content or link)
- If a standalone note was created, its path
- If the daily note update was skipped, why
```

**Step 2: Verify the file was created correctly**

Read back `selrahcd-obsidian-bridge/commands/til.md` and verify it has:
- YAML frontmatter with `name: til`, `description`, and `argument-hint`
- All 8 steps clearly documented
- Both inline and standalone note flows covered
- References to correct MCP tools and daily note path pattern

**Step 3: Commit**

```bash
git add selrahcd-obsidian-bridge/commands/til.md
git commit -m "feat(obsidian-bridge): add /til command for TIL entries"
```

---

### Task 3: Bump plugin version

**Files:**
- Modify: `selrahcd-obsidian-bridge/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

**Step 1: Update plugin.json version**

In `selrahcd-obsidian-bridge/.claude-plugin/plugin.json`, change `"version": "1.1.1"` to `"version": "1.2.0"`.

**Step 2: Update marketplace.json version**

In `.claude-plugin/marketplace.json`, find the obsidian-bridge entry and change `"version": "1.1.1"` to `"version": "1.2.0"`.

**Step 3: Verify versions match**

Read both files and confirm the obsidian-bridge version is `1.2.0` in both places.

**Step 4: Commit**

```bash
git add selrahcd-obsidian-bridge/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore(obsidian-bridge): bump version to 1.2.0 for new commands"
```

---

### Task 4: Manual testing

**Step 1: Test /track command**

In a Claude Code session within this repo:
1. Have a conversation about something technical
2. Run `/track` (no arguments) — verify it detects a topic, asks for confirmation, drafts a note, asks for approval, writes to Obsidian, and links in the daily note
3. Run `/track some specific topic` — verify it uses the argument as the topic hint

**Step 2: Test /til command**

1. Run `/til` (no arguments) — verify topic detection, format choice (inline vs standalone), draft, approval, and write
2. Run `/til something I learned` — verify argument is used as hint
3. Test the inline path (approve inline bullets)
4. Test the standalone note path (choose new note)

**Step 3: Verify Obsidian vault**

Open Obsidian and verify:
- New notes exist at the expected paths
- Daily note has entries in both "What did I do?" and "TIL ?" sections
- Wiki-links resolve correctly
- Tags appear correctly
