---
name: labels
description: Use when the user wants to list, define, refine, or remove labels in the directory-aware vault context, or when the agent has used a label that has no description and wants to register one. Wraps the `obsidian-context labels` and `obsidian-context label set/remove` CLI.
---

# Manage Labels

Labels are user-defined filter categories for vault entries (`obsidian-context list --label X`). Each label has a description so future sessions know what it means.

## When this skill applies

- The user says "show me my labels" or asks what labels exist.
- The agent referenced a label in `add-file` / `add-directory` that doesn't have a description in `obsidian-context labels`. Offer to register one.
- The user wants to refine an existing label's description or remove one.

## Steps

### 1. List existing labels

```bash
obsidian-context labels
```

To see where each definition came from (debugging refinements across levels):

```bash
obsidian-context labels --show-source
```

### 2. Define or refine a label

```bash
obsidian-context label set "<name>" "<description>" --scope <scope>
```

`label set` upserts (no `--force` needed; the closest level's description wins on read by design). Pick scope thoughtfully: a label that means the same thing across all your work belongs in `--scope global`; a project-specific meaning belongs in `--scope local`.

### 3. Remove a label

```bash
obsidian-context label remove "<name>" --scope <scope>
```

This removes the description; entries that still reference the label keep working but show `<no description>` until redefined.

## Notes

- Label names are kebab-case by convention (no enforcement). Pick names that describe a category, not an individual entry.
- Labels merge closest-wins across the directory tree, so you can have a global default and a more specific local override.
