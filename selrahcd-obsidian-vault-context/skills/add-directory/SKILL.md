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

### 2. Verify the directory exists in the vault

**Do not register a directory that doesn't exist.** Use the `obsidian-cli` (via the `obsidian:obsidian-cli` skill, or directly if available on PATH) to confirm the directory is actually in the vault before adding it to the index.

If the directory is found, proceed.

If the directory is NOT found:
- List the parent directory in the vault (or search for similar directory names) to find candidates.
- Present the closest matches to the user ("I didn't find `<original path>/`. Did you mean `<candidate-1>/`, `<candidate-2>/`, or `<candidate-3>/`?").
- Wait for the user to pick one or correct the path. **Never silently substitute a different path** — confirm first.
- If the user wants to register a directory they plan to create shortly, let them confirm explicitly before proceeding.

### 3. Check existing labels

```bash
obsidian-context labels
```

### 4. Pick a scope

See `add-file` skill for scope semantics — same rules apply.

### 5. Run the CLI

```bash
obsidian-context add directory "<vault-dir>/" \
  --description "<one-line description>" \
  --label "<label>" \
  --scope <scope>
```

### 6. Handle conflicts

Same as `add-file`: re-run with `--force` if user accepts overwrite.
