---
name: init-obsidian-bridge
description: Create an .obsidian-bridge.json config file for the current project
---

# Init Obsidian Bridge

Create an `.obsidian-bridge.json` config file in the current git repo root so that the obsidian-bridge SessionEnd hook knows how to log sessions for this project.

## Steps

### 1. Find the repo root

Use `git rev-parse --show-toplevel` to find the git repo root. If not in a git repo, use the current working directory.

### 2. Check for existing config

Check if `.obsidian-bridge.json` already exists at the repo root. If it does, show its contents and ask the user if they want to overwrite it. If they say no, stop.

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

Write `.obsidian-bridge.json` at the repo root:

```json
{
  "project": "<project name>",
  "tags": ["<tag1>", "<tag2>"],
  "notes": ["<path/to/note.md>"]
}
```

### 7. Confirm

Show the user what was written and where. Remind them that this file tells the obsidian-bridge hook how to log Claude sessions for this project.
