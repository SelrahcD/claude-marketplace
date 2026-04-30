# obsidian-vault-context

A directory-aware index of Obsidian vault notes and directories, queryable from any working directory via the `obsidian-context` CLI.

## What it does

When you work in a code project that lives outside your vault, this plugin lets you tell the agent "these vault notes/directories are relevant when working here". The index lives in `.obsidian-vault-context.json` files at any directory level, plus a global `~/.obsidian-vault-context.json`. The CLI walks up the directory tree, merges all discovered configs (closest-first), and answers filtered queries — so the agent doesn't need to scan the vault.

## How it relates to `obsidian-bridge`

This plugin is a sibling to `obsidian-bridge`. It does **not** replace it. `obsidian-bridge` continues to read its own `.claude/obsidian-bridge.json` for project name, tags, tracking entries, and the SessionEnd auto-doc. This plugin uses a different file (`.obsidian-vault-context.json`, at the directory root) for the directory-aware index. A future release of `obsidian-bridge` may merge into this file, but for now they coexist.

## Prerequisites

- `bash` (3.2+; works with the macOS system bash and any modern Linux bash)
- `jq`

## Installation

Add the plugin to your Claude Code marketplace and enable it:

```
/plugin install obsidian-vault-context@selrahcd-marketplace
```

The CLI `obsidian-context` is automatically available on PATH while the plugin is enabled.

## Config file schema

Per-directory: `<dir>/.obsidian-vault-context.json`. Global: `~/.obsidian-vault-context.json`. Same shape both places.

```json
{
  "files": [
    {
      "path": "🦺 Projects/Marketplace.md",
      "description": "Active marketplace project notes",
      "labels": ["marketplace", "project"]
    }
  ],
  "directories": [
    {
      "path": "🦺 Projects/",
      "description": "All projects live here",
      "labels": ["projects"]
    }
  ],
  "labels": {
    "marketplace": "Notes related to the marketplace plugin work",
    "project": "Active project context",
    "projects": "Top-level projects folder"
  }
}
```

All top-level keys are optional. Unknown top-level keys produce a soft warning but do not error (forward compat for other plugins extending the file).

## CLI reference

### Global flags

- `--json` — structured output instead of human-readable.
- `--cwd <path>` — pretend the CLI was invoked from `<path>`.
- `--help` — usage.

### Read

```
obsidian-context list [--kind files|directories]
                      [--label <name>]... [--any]
                      [--search <term>]
                      [--show-source]
                      [--json]

obsidian-context labels [--search <term>]
                        [--show-source]
                        [--json]

obsidian-context where [--json]
```

`list` returns merged file and directory entries from every config encountered walking up from CWD plus the global config. `--label` repeats are AND by default; `--any` switches to OR. `--show-source` adds a `from: <path>` line under each entry showing which config it came from. Default human output omits it; JSON output always includes the `source` field.

`labels` returns the merged label vocabulary — closest-wins on the description text. `--show-source` includes the path of the config whose description won.

`where` is a debugging aid: it prints the absolute paths of all configs the CLI loaded for the current CWD.

### Write

```
obsidian-context add file <vault-path>      --description <text> [--label <name>]... [--scope <scope>] [--force]
obsidian-context add directory <vault-path> --description <text> [--label <name>]... [--scope <scope>] [--force]
obsidian-context remove file <vault-path>      [--scope <scope>]
obsidian-context remove directory <vault-path> [--scope <scope>]
obsidian-context label set <name> <description> [--scope <scope>]
obsidian-context label remove <name>             [--scope <scope>]
```

`--scope` values:

- `local` (default) — closest existing `.obsidian-vault-context.json` at or above CWD. If none exists, the CLI errors and asks you to choose a different scope.
- `current-directory` — `$PWD/.obsidian-vault-context.json`, creating it if absent.
- `global` — `~/.obsidian-vault-context.json`, creating it if absent.
- `<path>` — `<path>/.obsidian-vault-context.json`. The directory must exist; the file is created if absent. To address a directory literally named `local` / `current-directory` / `global`, prefix it with `./` or use an absolute path.

`--force` overwrites an existing entry's description and labels (without it, conflicting writes error out).

## Skills

The plugin ships four skills:

- `read-context` — auto-invoked when the user mentions vault tracking, ongoing efforts, or vault writes. Runs `obsidian-context list` to surface relevant entries.
- `add-file` — register a new vault file entry via `obsidian-context add file`.
- `add-directory` — register a new vault directory entry.
- `labels` — list, define, refine, or remove label descriptions.

All skills are model-invocable and user-invocable.

## Labels in practice

Labels are entirely user-defined. Some patterns that work well:

- `til-target` — "this note is where TILs about X land"
- `track-target` — "this note is where ongoing-effort updates go"
- `daily-note` — "use today's daily note"
- `read-only` — "consult, don't write"
- `<project-name>` — "anything tagged with this is part of project X"

Define each label's description with `obsidian-context label set <name> "<description>"` so the next session knows what it means.

## Files reference

| File | Purpose |
| --- | --- |
| `bin/obsidian-context` | CLI dispatcher |
| `lib/traversal.sh` | Walk-up + global config discovery |
| `lib/schema.sh` | JSON shape validation |
| `lib/merge.sh` | Concat + closest-wins merge |
| `lib/scope.sh` | `--scope` resolution |
| `lib/write.sh` | Atomic read-modify-write |
| `lib/output.sh` | Human + `--json` formatters |
| `skills/<name>/SKILL.md` | Plugin skills |
| `tests/*.bats` | bats test suite |
