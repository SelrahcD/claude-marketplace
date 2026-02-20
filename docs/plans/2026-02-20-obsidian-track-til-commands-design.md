# Design: /track and /til Commands for obsidian-bridge

**Date:** 2026-02-20
**Plugin:** selrahcd-obsidian-bridge
**Version bump:** 1.1.1 -> 1.2.0 (new features)

## Overview

Two new commands for the obsidian-bridge plugin that let users capture learnings and insights from Claude conversations into their Obsidian vault during a session (as opposed to the existing SessionEnd auto-documentation).

## Command: /track

**Purpose:** Create a standalone Obsidian note to capture a learning or insight from the current conversation, with a link added to the daily note's "What did I do?" section.

**Input:** Optional argument describing what to track. If omitted, Claude analyzes the conversation to propose a topic.

### Flow

1. **Detect topic** — Use `$ARGUMENTS` if provided, otherwise analyze conversation context.
2. **Confirm topic** — Present detected topic to user. Wait for confirmation or edits.
3. **Propose location** — Suggest a vault folder based on topic and `.obsidian-bridge.json` config. Default to vault root. Ask user to confirm or change.
4. **Draft note content** — Generate structured note with:
   - Meaningful title (becomes filename)
   - Content: summary of the learning/insight from conversation
   - Tags from `.obsidian-bridge.json` if available
   - Wiki-links to related vault notes where relevant
5. **Present draft for validation** — Show full draft. Wait for approval or edits.
6. **Write note** — Use `mcp__obsidian__write_note` to create the note.
7. **Link in daily note** — Read today's daily note (`🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md`), find `## What did I do?` section, append a bullet with `[[wiki-link]]` to the new note after the tasks code block.

## Command: /til

**Purpose:** Add a "Today I Learned" entry to the daily note's TIL section. Can be inline bullets or a standalone note with a link.

**Input:** Optional argument describing the TIL. If omitted, Claude analyzes the conversation to propose what was learned.

### Flow

1. **Detect topic** — Use `$ARGUMENTS` if provided, otherwise analyze conversation context.
2. **Confirm topic** — Present detected TIL topic. Wait for confirmation or edits.
3. **Decide format** — Propose one of:
   - **Inline entry**: 1-3 bullet points appended directly to TIL section
   - **New note + link**: Standalone note for deeper topics, with `[[wiki-link]]` in TIL section
   - Ask user to confirm format.
4. **Draft content** — Generate draft (inline bullets or full note).
5. **Present draft for validation** — Show to user. Wait for approval or edits.
6. **Write content** — If standalone note: create with `mcp__obsidian__write_note`. Then read daily note, find `## TIL ?` section, append entry using `mcp__obsidian__patch_note`.

## Shared Patterns

- Both commands use the daily note path: `🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md`
- Both read `.obsidian-bridge.json` for project context (tags, project name)
- Both require user confirmation at topic detection and content draft stages
- Both use Obsidian MCP tools: `read_note`, `write_note`, `patch_note`

## Files to Create/Modify

1. **Create** `selrahcd-obsidian-bridge/commands/track.md`
2. **Create** `selrahcd-obsidian-bridge/commands/til.md`
3. **Update** `selrahcd-obsidian-bridge/.claude-plugin/plugin.json` — bump version to 1.2.0
4. **Update** `.claude-plugin/marketplace.json` — bump obsidian-bridge version to 1.2.0
