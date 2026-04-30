---
name: read-context
description: Use when the user mentions vault tracking, asks where notes about a topic live, is about to write to the Obsidian vault, references an ongoing effort, or invokes anything that touches obsidian (MCP, obsidian-cli). Surfaces the merged directory-aware index of vault files and directories from `.obsidian-vault-context.json` files (per-directory + global).
---

# Read Vault Context

The user has a directory-aware index of relevant Obsidian vault notes and directories. Use the `obsidian-context` CLI to consult it before scanning the vault. The CLI is on PATH while this plugin is enabled.

## When this skill applies

Invoke this skill whenever the current task involves the Obsidian vault — explicit MCP/CLI calls, the user talking about something they're tracking, or any "where do my notes about X live?" question.

## Steps

### 1. Check what's known for this directory

Run:

```bash
obsidian-context list
```

This prints all known file and directory entries from every `.obsidian-vault-context.json` walking up from CWD plus the global config. Each entry has a path, labels, description, and a `from:` source. If output is empty, the user has no index here yet — fall back to your usual approach (asking, or using `obsidian-context add file` if a relevant note is created).

### 2. Narrow the list when the request is specific

If the user mentions a topic, refine with a search:

```bash
obsidian-context list --search "<keyword>"
```

If the user mentions a label they've used before:

```bash
obsidian-context list --label "<label-name>"
```

To see what labels exist:

```bash
obsidian-context labels
```

### 3. Use the entries

- For **read** intent: pick the matching entries and read those notes (via the obsidian MCP server or obsidian-cli).
- For **write** intent: consult the entries, propose the most relevant one as the destination, and confirm with the user before appending.
- If nothing matches and you create a new long-lived vault note during the session, offer to register it via the `add-file` skill.

## Notes

- The CLI is read-cheap — re-run with different filters as the conversation evolves.
- Entries from closer directories appear first; this is intentional. Prefer them when both close and far entries match.
- Use `obsidian-context where` to debug which config files are loaded.
