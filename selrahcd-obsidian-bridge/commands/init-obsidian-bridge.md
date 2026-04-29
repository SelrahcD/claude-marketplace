---
name: init-obsidian-bridge
description: Create a .claude/obsidian-bridge.json config file for the current project
---

# Init Obsidian Bridge

Create a `.claude/obsidian-bridge.json` config file in the current git repo so that the obsidian-bridge SessionEnd hook knows how to log sessions for this project.

## Steps

### 1. Find the repo root

Use `git rev-parse --show-toplevel` to find the git repo root. If not in a git repo, use the current working directory.

### 2. Check for existing config

Check if `.claude/obsidian-bridge.json` already exists at the repo root. If it does, show its contents and ask the user if they want to overwrite it. If they say no, stop.

### 3. Ask for project name

Suggest a project name based on the git repo folder name (title-cased, e.g. `claude-marketplace` -> `Claude Marketplace`). Let the user confirm or provide a different name.

### 4. Ask for tags

Suggest tags based on the project name (kebab-cased, e.g. `Claude Marketplace` -> `claude-marketplace`). Let the user confirm or provide different tags. Tags should not include the `#` prefix.

### 5. Discover Obsidian note paths

Check if `OBSIDIAN_VAULT_PATH` environment variable is set.

**If set:** List directories and markdown files in the vault that look like project notes. Good places to look:
- Files directly under vault root matching the project name
- Files in directories that contain "Project" in their name (e.g. `🦺 Projects/`)

Present the matching files to the user and let them pick which ones to include. They can also type custom paths.

**If not set:** Ask the user to type vault-relative note paths manually. Explain these are paths relative to the Obsidian vault root.

The `notes` array can be empty if the user doesn't want project-specific note updates.

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

### 7. Confirm

Show the user what was written and where (`.claude/obsidian-bridge.json`). Remind them that this file tells the obsidian-bridge hook how to log Claude sessions for this project.
