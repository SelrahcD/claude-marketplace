# Obsidian Bridge — Tracking Index Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the obsidian-bridge plugin so a per-repo `.claude/obsidian-bridge.json` can index multiple Obsidian vault notes (project + ad-hoc tracked efforts), and so the agent surfaces / registers them automatically through a new skill and the existing `track`/`til` commands.

**Architecture:** Pure documentation / instructions plugin — no executable code. Changes are confined to markdown files (skill body + commands + README), one new skill directory, and JSON config bumps (plugin manifest + marketplace). Schema is extended additively so existing configs keep working untouched.

**Tech Stack:** Markdown skill/command instructions, JSON config files. No tests run automatically — verification is reading file contents back after each change.

**Reference spec:** `docs/superpowers/specs/2026-04-29-obsidian-bridge-tracking-index-design.md`

---

## File Structure

| File | Action | Responsibility |
| --- | --- | --- |
| `selrahcd-obsidian-bridge/skills/vault-index/SKILL.md` | Create | New skill — surfaces tracked entries, prompts registration |
| `selrahcd-obsidian-bridge/commands/track.md` | Modify | Load `tracking[]`, suggest tracked location, post-write registration prompt |
| `selrahcd-obsidian-bridge/commands/til.md` | Modify | Same three additions as `track.md` (only when standalone-note path is taken) |
| `selrahcd-obsidian-bridge/commands/init-obsidian-bridge.md` | Modify | Mention `tracking[]` field in step 6, no init-time prompt |
| `selrahcd-obsidian-bridge/.claude-plugin/plugin.json` | Modify | Declare `skills` path + bump version to 1.6.0 |
| `.claude-plugin/marketplace.json` | Modify | Bump obsidian-bridge entry version to 1.6.0 |
| `selrahcd-obsidian-bridge/README.md` | Modify | Document new skill and the extended schema |

The skill body and the matching command edits share wording for the registration prompt and the heuristic. The wording lives in two places (skill + each command) on purpose — commands stay self-contained and readable. If the wording diverges later, fix it in all three places.

---

## Task 1: Create the `vault-index` skill

**Files:**
- Create: `selrahcd-obsidian-bridge/skills/vault-index/SKILL.md`

- [ ] **Step 1: Create the skill directory and file**

Create the skill at `selrahcd-obsidian-bridge/skills/vault-index/SKILL.md` with the following content:

````markdown
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

5. The `tracking` array is optional. Treat the top-level `project` / `tags` / `notes` as the always-on default entry.

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
````

- [ ] **Step 2: Verify file content**

```bash
cat selrahcd-obsidian-bridge/skills/vault-index/SKILL.md | head -5
```

Expected first lines:
```
---
name: vault-index
description: Use when working with the Obsidian vault via MCP (reading, writing, or referencing notes), or when the user mentions a tracked effort (refactor, migration, investigation, ongoing work). Surfaces the tracked notes index from the repo's `.claude/obsidian-bridge.json` and prompts registration of new long-lived notes.
---
```

- [ ] **Step 3: Commit**

```bash
git add selrahcd-obsidian-bridge/skills/vault-index/SKILL.md
git commit -m "feat(obsidian-bridge): add vault-index skill"
```

---

## Task 2: Update `track.md` — load `tracking[]`

**Files:**
- Modify: `selrahcd-obsidian-bridge/commands/track.md`

- [ ] **Step 1: Replace step "1. Load project config"**

Find this block in `selrahcd-obsidian-bridge/commands/track.md`:

```markdown
### 1. Load project config

Check if `.claude/obsidian-bridge.json` exists at the git repo root (use `git rev-parse --show-toplevel`). If found, read it to get the project name and tags. These will be used later for tagging and context. If not found, continue without project context.
```

Replace with:

```markdown
### 1. Load project config

Check if `.claude/obsidian-bridge.json` exists at the git repo root (use `git rev-parse --show-toplevel`). If found, read it to get:

- `project` and top-level `tags` — used for tagging and context later.
- `notes` — the always-on project notes.
- `tracking[]` (optional) — additional ad-hoc tracked entries. Each has `label`, `description`, `notes`, and an optional `tags` (falls back to top-level `tags`).

Keep the loaded entries (project + each `tracking[]` entry) available to subsequent steps. If the config file is not found, continue without project context.
```

- [ ] **Step 2: Verify the edit**

```bash
grep -A 8 "### 1. Load project config" selrahcd-obsidian-bridge/commands/track.md
```

Expected output: the new wording above.

---

## Task 3: Update `track.md` — suggest tracked location first

**Files:**
- Modify: `selrahcd-obsidian-bridge/commands/track.md`

- [ ] **Step 1: Insert tracked-location check in step 4**

Find this block in `selrahcd-obsidian-bridge/commands/track.md`:

```markdown
### 4. Propose note location

Use the Obsidian MCP `list_directory` tool to check what folders exist in the vault. Suggest a location based on the topic:
```

Replace with:

```markdown
### 4. Propose note location

**First**, scan the entries you loaded in step 1 (the always-on project entry plus any `tracking[]` entries). If any entry's `description` or `label` semantically matches the topic (use your judgment — this is not a substring check), offer that entry's note path as the **first option**:

> "This looks related to the tracked entry **<label>** (`<note path>`). Append to that note, or create a new one?"

If multiple entries match, list them all and let the user pick. If the user picks a tracked note, skip the location-suggestion logic below and use that path as the destination.

Otherwise, use the Obsidian MCP `list_directory` tool to check what folders exist in the vault. Suggest a location based on the topic:
```

- [ ] **Step 2: Verify the edit**

```bash
grep -A 5 "First.*scan the entries" selrahcd-obsidian-bridge/commands/track.md
```

Expected: lines from the inserted paragraph.

---

## Task 4: Update `track.md` — add registration step

**Files:**
- Modify: `selrahcd-obsidian-bridge/commands/track.md`

- [ ] **Step 1: Renumber and insert the new step**

Find these blocks (currently steps 8 and 9) at the end of `selrahcd-obsidian-bridge/commands/track.md`:

```markdown
### 8. Link in daily note
```

and

```markdown
### 9. Confirm

Tell the user:
- The note was created, including its full vault path
- Whether the daily note was updated or skipped
```

Insert a **new step 9** between them, and renumber the existing "Confirm" to step 10. The new step 9 content:

```markdown
### 9. Offer to register in tracking

Apply the registration heuristic. Prompt "Add this to tracking?" only when **at least one** of these signals is present:

- The note documents an **ongoing effort** — refactor, migration, investigation, multi-session debugging.
- The note is structured to be **appended over time** — has a "Progress", "Decisions", "Log", or similar section.
- The user explicitly said **"track"**, **"follow up"**, **"keep notes on"**, or a close variant.
- The user invoked `/track` with a topic that names an effort rather than a one-off insight.

If the destination of the note was an **already-tracked entry** (chosen in step 4), skip this step.

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
```

The "Confirm" section (now step 10) keeps its current body but its heading becomes:

```markdown
### 10. Confirm
```

And add a third bullet to its body so it reads:

```markdown
### 10. Confirm

Tell the user:
- The note was created, including its full vault path
- Whether the daily note was updated or skipped
- Whether a tracking entry was registered (and under which label)
```

- [ ] **Step 2: Verify the edit**

```bash
grep -E "^### (8|9|10)\." selrahcd-obsidian-bridge/commands/track.md
```

Expected output:
```
### 8. Link in daily note
### 9. Offer to register in tracking
### 10. Confirm
```

- [ ] **Step 3: Commit (Tasks 2–4 together)**

```bash
git add selrahcd-obsidian-bridge/commands/track.md
git commit -m "feat(obsidian-bridge): teach /track about tracking[] entries"
```

---

## Task 5: Update `til.md` — load `tracking[]`

**Files:**
- Modify: `selrahcd-obsidian-bridge/commands/til.md`

- [ ] **Step 1: Replace step "1. Load project config"**

Find this block in `selrahcd-obsidian-bridge/commands/til.md`:

```markdown
### 1. Load project config

Check if `.claude/obsidian-bridge.json` exists at the git repo root (use `git rev-parse --show-toplevel`). If found, read it to get the project name and tags. These will be used later for tagging and context. If not found, continue without project context.
```

Replace with the same wording used in Task 2 step 1:

```markdown
### 1. Load project config

Check if `.claude/obsidian-bridge.json` exists at the git repo root (use `git rev-parse --show-toplevel`). If found, read it to get:

- `project` and top-level `tags` — used for tagging and context later.
- `notes` — the always-on project notes.
- `tracking[]` (optional) — additional ad-hoc tracked entries. Each has `label`, `description`, `notes`, and an optional `tags` (falls back to top-level `tags`).

Keep the loaded entries (project + each `tracking[]` entry) available to subsequent steps. If the config file is not found, continue without project context.
```

- [ ] **Step 2: Verify**

```bash
grep -A 8 "### 1. Load project config" selrahcd-obsidian-bridge/commands/til.md
```

Expected: the new wording.

---

## Task 6: Update `til.md` — suggest tracked location first (standalone path only)

**Files:**
- Modify: `selrahcd-obsidian-bridge/commands/til.md`

- [ ] **Step 1: Insert the check at the top of step 5**

Find this block in `selrahcd-obsidian-bridge/commands/til.md`:

```markdown
### 5. Propose note location (standalone only)

If the user chose **standalone note** format, propose a location before drafting:

Use the Obsidian MCP `list_directory` tool to check what folders exist in the vault. Suggest a location based on the topic:
```

Replace with:

```markdown
### 5. Propose note location (standalone only)

If the user chose **standalone note** format, propose a location before drafting.

**First**, scan the entries you loaded in step 1 (the always-on project entry plus any `tracking[]` entries). If any entry's `description` or `label` semantically matches the topic (use your judgment — this is not a substring check), offer that entry's note path as the **first option**:

> "This looks related to the tracked entry **<label>** (`<note path>`). Append to that note, or create a new one?"

If multiple entries match, list them all and let the user pick. If the user picks a tracked note, skip the location-suggestion logic below and use that path as the destination.

Otherwise, use the Obsidian MCP `list_directory` tool to check what folders exist in the vault. Suggest a location based on the topic:
```

- [ ] **Step 2: Verify**

```bash
grep -A 5 "First.*scan the entries" selrahcd-obsidian-bridge/commands/til.md
```

Expected: lines from the inserted paragraph.

---

## Task 7: Update `til.md` — add registration step

**Files:**
- Modify: `selrahcd-obsidian-bridge/commands/til.md`

- [ ] **Step 1: Renumber and insert the new step**

Find these blocks (currently steps 8 and 9) at the end of `selrahcd-obsidian-bridge/commands/til.md`:

```markdown
### 8. Write content
```

and

```markdown
### 9. Confirm

Tell the user:
- What was added to the TIL section (inline bullets or a wiki-link)
- The standalone note path if one was created
- If the daily note update was skipped and why
```

Insert a **new step 9** between them, renumbering the existing "Confirm" to step 10. New step 9 content:

```markdown
### 9. Offer to register in tracking (standalone only)

If the user chose **inline format** (no standalone note was created), skip this step.

If the destination of the standalone note was an **already-tracked entry** (chosen in step 5), skip this step.

Otherwise, apply the registration heuristic. Prompt "Add this to tracking?" only when **at least one** of these signals is present:

- The note documents an **ongoing effort** — refactor, migration, investigation, multi-session debugging.
- The note is structured to be **appended over time** — has a "Progress", "Decisions", "Log", or similar section.
- The user explicitly said **"track"**, **"follow up"**, **"keep notes on"**, or a close variant.

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
```

The "Confirm" section (now step 10) keeps its current body but its heading becomes:

```markdown
### 10. Confirm
```

And add a fourth bullet:

```markdown
### 10. Confirm

Tell the user:
- What was added to the TIL section (inline bullets or a wiki-link)
- The standalone note path if one was created
- If the daily note update was skipped and why
- Whether a tracking entry was registered (and under which label)
```

- [ ] **Step 2: Verify**

```bash
grep -E "^### (8|9|10)\." selrahcd-obsidian-bridge/commands/til.md
```

Expected output:
```
### 8. Write content
### 9. Offer to register in tracking (standalone only)
### 10. Confirm
```

- [ ] **Step 3: Commit (Tasks 5–7 together)**

```bash
git add selrahcd-obsidian-bridge/commands/til.md
git commit -m "feat(obsidian-bridge): teach /til about tracking[] entries"
```

---

## Task 8: Update `init-obsidian-bridge.md` to mention `tracking[]`

**Files:**
- Modify: `selrahcd-obsidian-bridge/commands/init-obsidian-bridge.md`

- [ ] **Step 1: Replace the example JSON in step 6**

Find this block in `selrahcd-obsidian-bridge/commands/init-obsidian-bridge.md`:

```markdown
### 6. Write the config file

Ensure the `.claude/` directory exists at the repo root (create it if needed). Write `obsidian-bridge.json` inside it:

```json
{
  "project": "<project name>",
  "tags": ["<tag1>", "<tag2>"],
  "notes": ["<path/to/note.md>"]
}
```
```

Replace with:

```markdown
### 6. Write the config file

Ensure the `.claude/` directory exists at the repo root (create it if needed). Write `obsidian-bridge.json` inside it:

```json
{
  "project": "<project name>",
  "tags": ["<tag1>", "<tag2>"],
  "notes": ["<path/to/note.md>"]
}
```

The schema also supports an optional `tracking[]` array for ad-hoc tracked efforts (refactors, migrations, investigations) that the agent should remember alongside the project. Do **not** prompt for tracking entries during init — they get added later through `/track`, `/til`, or organic Obsidian MCP calls. For reference, a fully populated config looks like:

```json
{
  "project": "<project name>",
  "tags": ["<tag1>"],
  "notes": ["<path/to/note.md>"],
  "tracking": [
    {
      "label": "<kebab-case-label>",
      "description": "<one-sentence description>",
      "notes": ["<vault-relative path>"],
      "tags": ["<optional-override-tag>"]
    }
  ]
}
```
```

- [ ] **Step 2: Verify**

```bash
grep -A 2 "tracking\[\] array for ad-hoc" selrahcd-obsidian-bridge/commands/init-obsidian-bridge.md
```

Expected: the new paragraph.

- [ ] **Step 3: Commit**

```bash
git add selrahcd-obsidian-bridge/commands/init-obsidian-bridge.md
git commit -m "docs(obsidian-bridge): mention tracking[] schema in init command"
```

---

## Task 9: Update `plugin.json` — declare skills + bump version

**Files:**
- Modify: `selrahcd-obsidian-bridge/.claude-plugin/plugin.json`

- [ ] **Step 1: Replace the file content**

Replace the entire file with:

```json
{
  "name": "obsidian-bridge",
  "version": "1.6.0",
  "description": "Auto-document Claude sessions to an Obsidian vault via SessionEnd hook",
  "author": {
    "name": "Selrahcd",
    "url": "https://github.com/SelrahcD"
  },
  "repository": "https://github.com/SelrahcD/claude-marketplace",
  "license": "MIT",
  "keywords": ["obsidian", "documentation", "hooks", "session-log"],
  "skills": "./skills/"
}
```

Note: the version bumps from `1.5.1` → `1.6.0` (minor, because we are adding a new skill). The `skills` path is added because we now ship one.

- [ ] **Step 2: Verify JSON is valid**

```bash
jq . selrahcd-obsidian-bridge/.claude-plugin/plugin.json
```

Expected: pretty-printed JSON with `"version": "1.6.0"` and `"skills": "./skills/"` present.

---

## Task 10: Update `marketplace.json` — bump version

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Bump the obsidian-bridge entry version**

Find this block in `.claude-plugin/marketplace.json`:

```json
{
  "name": "obsidian-bridge",
  "source": "./selrahcd-obsidian-bridge",
  "description": "Auto-document Claude sessions to an Obsidian vault via SessionEnd hook",
  "version": "1.5.1"
}
```

Replace `"1.5.1"` with `"1.6.0"`. Leave everything else in the marketplace file untouched.

- [ ] **Step 2: Verify**

```bash
jq '.plugins[] | select(.name == "obsidian-bridge") | .version' .claude-plugin/marketplace.json
```

Expected output:
```
"1.6.0"
```

- [ ] **Step 3: Commit (Tasks 9–10 together)**

```bash
git add selrahcd-obsidian-bridge/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore(obsidian-bridge): bump to 1.6.0 and declare skills path"
```

---

## Task 11: Update `README.md` — document skill and schema

**Files:**
- Modify: `selrahcd-obsidian-bridge/README.md`

- [ ] **Step 1: Expand the "Configure project-specific notes" section**

Find this block in `selrahcd-obsidian-bridge/README.md`:

```markdown
### Step 4: Configure project-specific notes (optional)

In any git repo, create `.claude/obsidian-bridge.json`:

```json
{
  "project": "My Project",
  "tags": ["my-project"],
  "notes": ["🦺 Projects/My Project.md"]
}
```

- `project`: name used in wiki-links
- `tags`: applied as #tags to each entry (without # prefix)
- `notes`: vault-relative paths to project notes to update
```

Replace with:

```markdown
### Step 4: Configure project-specific notes (optional)

In any git repo, create `.claude/obsidian-bridge.json`:

```json
{
  "project": "My Project",
  "tags": ["my-project"],
  "notes": ["🦺 Projects/My Project.md"]
}
```

- `project`: name used in wiki-links
- `tags`: applied as #tags to each entry (without # prefix)
- `notes`: vault-relative paths to project notes to update

#### Optional: tracked efforts

You can also list ad-hoc tracked efforts (a refactor in progress, an investigation, a migration) under a `tracking[]` array. Each entry pins a vault note to a focus area so the `vault-index` skill, `/track`, and `/til` can surface the right note without scanning the whole vault.

```json
{
  "project": "My Project",
  "tags": ["my-project"],
  "notes": ["🦺 Projects/My Project.md"],
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
- `label`: kebab-case identifier, unique within the file
- `description`: one-sentence explanation of the effort
- `notes`: vault-relative paths
- `tags`: optional, falls back to top-level `tags` when absent

You don't have to write `tracking` entries by hand. The plugin will offer to register a new tracked entry whenever it writes a note that looks like it documents an ongoing effort.
```

- [ ] **Step 2: Add a "Skills" section after "Daily note format"**

Find this line in `selrahcd-obsidian-bridge/README.md`:

```markdown
## Environment variables
```

Insert a new section **immediately before** it:

```markdown
## Skills

### `vault-index`

Triggers when you work with the Obsidian vault via MCP, or when you mention a tracked effort. It reads `.claude/obsidian-bridge.json`, surfaces the tracked notes as candidate destinations before writing, and offers to register new long-lived notes in the index after they're written.

The `track` and `til` commands embed the same logic inline so they remain self-contained when invoked explicitly.

```

- [ ] **Step 3: Verify**

```bash
grep -E "^## (Skills|Environment variables)" selrahcd-obsidian-bridge/README.md
```

Expected output:
```
## Skills
## Environment variables
```

- [ ] **Step 4: Commit**

```bash
git add selrahcd-obsidian-bridge/README.md
git commit -m "docs(obsidian-bridge): document vault-index skill and tracking schema"
```

---

## Task 12: Final smoke check

**Files:**
- Read-only verification.

- [ ] **Step 1: Confirm version sync**

```bash
jq -r '.version' selrahcd-obsidian-bridge/.claude-plugin/plugin.json
jq -r '.plugins[] | select(.name == "obsidian-bridge") | .version' .claude-plugin/marketplace.json
```

Both must print `1.6.0`.

- [ ] **Step 2: Confirm new skill is in place**

```bash
ls selrahcd-obsidian-bridge/skills/vault-index/SKILL.md
```

Expected: file path printed (no error).

- [ ] **Step 3: Confirm command edits are present**

```bash
grep -c "tracking\[\]" selrahcd-obsidian-bridge/commands/track.md
grep -c "tracking\[\]" selrahcd-obsidian-bridge/commands/til.md
grep -c "tracking\[\]" selrahcd-obsidian-bridge/commands/init-obsidian-bridge.md
```

Each must print at least `1`.

- [ ] **Step 4: Confirm README mentions the new skill**

```bash
grep -c "vault-index" selrahcd-obsidian-bridge/README.md
```

Must print at least `1`.

- [ ] **Step 5: Confirm git log**

```bash
git log --oneline -8
```

Expected: the six commits from Tasks 1, 4, 7, 8, 10, 11, all on `main`.

No final commit needed for this task — it is verification only.

---

## Done criteria

- `selrahcd-obsidian-bridge/skills/vault-index/SKILL.md` exists with the documented frontmatter and body.
- `track.md`, `til.md`, and `init-obsidian-bridge.md` reflect the schema changes per their respective tasks.
- `plugin.json` and `marketplace.json` both report `1.6.0`.
- `README.md` documents the `vault-index` skill and the optional `tracking[]` schema.
- All edits are committed; smoke checks in Task 12 pass.
