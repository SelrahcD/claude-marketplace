---
name: add-directory
description: Use when an Obsidian vault directory (folder) is relevant to this working directory and not yet indexed, or when the user wants to register a vault directory. Adds an entry via the `obsidian-context add directory` CLI.
---

# Add Directory Entry

Register an Obsidian vault directory in the directory-aware index. Useful for "all notes in this folder are relevant" cases — a project root, a topic folder, an archive.

## When this skill applies

- A vault directory contains a cluster of notes that are all relevant to the current working directory.
- The user explicitly asks to register a vault directory.

## Steps

### 1. Determine the entry's fields

You need:
- `path` — the vault-relative directory path, ending with `/`. Example: `🦺 Projects/`.
- `description` — one-line explanation.
- `labels` — zero or more.

### 2. Check existing labels

```bash
obsidian-context labels
```

### 3. Pick a scope

See `add-file` skill for scope semantics — same rules apply.

### 4. Run the CLI

```bash
obsidian-context add directory "<vault-dir>/" \
  --description "<one-line description>" \
  --label "<label>" \
  --scope <scope>
```

### 5. Handle conflicts

Same as `add-file`: re-run with `--force` if user accepts overwrite.
