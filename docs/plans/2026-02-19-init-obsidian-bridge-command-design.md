# Init Obsidian Bridge Command Design

## Goal

A command that interactively creates `.obsidian-bridge.json` config files in project repos.

## Command: `init-obsidian-bridge`

**Location:** `selrahcd-obsidian-bridge/commands/init-obsidian-bridge.md`

**Flow:**
1. Check if `.obsidian-bridge.json` already exists at git repo root — warn and ask to overwrite if so
2. Ask for project name (suggest from git repo name / folder name)
3. Ask for tags (suggest kebab-cased project name)
4. If `OBSIDIAN_VAULT_PATH` is set, list project-like directories in the vault to help pick note paths. Otherwise ask for paths manually.
5. Write `.obsidian-bridge.json` at git repo root
6. Confirm what was written

**Output format:**
```json
{
  "project": "Project Name",
  "tags": ["tag1", "tag2"],
  "notes": ["🦺 Projects/Project Name.md"]
}
```

**Plugin version bump:** 1.0.0 -> 1.1.0 (new command = minor)
