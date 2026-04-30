---
name: add-file
description: Use when a relevant Obsidian vault note is discovered or created during a session and is not yet indexed in `.obsidian-vault-context.json`, or when the user wants to register a vault file for future context. Adds an entry via the `obsidian-context add file` CLI.
---

# Add File Entry

Register an Obsidian vault file in the directory-aware index so future sessions can find it via `obsidian-context list`.

## When this skill applies

- A new long-lived vault note was created and you want it surfaced from this directory in future sessions.
- The user explicitly asks to register a vault file.
- An existing vault note keeps coming up in conversations and isn't yet indexed.

## Steps

### 1. Determine the entry's fields

You need:
- `path` — the vault-relative path (no leading slash). Example: `🦺 Projects/Marketplace.md`.
- `description` — one-line explanation of what the note is. The agent reads this in future sessions to decide relevance.
- `labels` — zero or more existing or new labels.

### 2. See what labels exist before inventing new ones

Run:

```bash
obsidian-context labels
```

Prefer reusing existing labels. If you do invent a new one, register its description right after via the `labels` skill.

### 3. Pick a scope

Default scope is `local` (closest existing config above CWD). Override when needed:

- `--scope current-directory` — write to a config in `$PWD` (creates if absent).
- `--scope global` — write to `~/.obsidian-vault-context.json`.
- `--scope <dir>` — write to that directory's config.

Prompt the user when the scope is ambiguous (e.g. they say "track this for clientA" — use `--scope <clientA-dir>`).

### 4. Run the CLI

```bash
obsidian-context add file "<vault-path>" \
  --description "<one-line description>" \
  --label "<label1>" --label "<label2>" \
  --scope <scope>
```

### 5. Handle conflicts

If the CLI reports a conflict (entry already exists with different fields), tell the user and ask whether to overwrite. If yes, re-run with `--force`.

## Notes

- The CLI is idempotent for identical re-adds — running twice with the same args is fine.
- If `--scope local` errors with "no existing config found at or above $PWD", switch to `--scope current-directory` (creates one here) or pick a directory explicitly.
