# Obsidian Vault Context

**Date:** 2026-04-30
**Plugin:** `selrahcd-obsidian-vault-context` (new, sibling to `selrahcd-obsidian-bridge`)

## Problem

When working in a code project that lives outside the user's Obsidian vault, the agent has no cheap way to know which vault notes and directories are relevant to that project. Today, finding the right destination note (or the right reference material) requires either scanning the vault each time or hard-coding paths in a single per-repo config that lives only at the project root.

Two needs are unmet:

1. **Directory-aware context.** A user working in `/Workspace/perso/marketplace` should get vault context for that project; a user working in `/workspace/clientA/repoB` should get clientA-specific context plus repoB-specific context, automatically.
2. **Cheap, scoped lookup.** The agent should not re-scan the vault. It should ask a small CLI tool what notes are known for "here", optionally filtered, and get a short answer.

The goal of this plugin is to make every directory aware of the vault notes that matter to it, with a structured config file at multiple levels and a CLI that the agent calls to read and curate that index.

## Scope

**In scope.**

- A new plugin `obsidian-vault-context` shipped at version `1.0.0`.
- A per-directory config file (`.obsidian-vault-context.json`) and a global config file (`~/.obsidian-vault-context.json`).
- A bash CLI tool `obsidian-context` (in the plugin's `bin/`, auto-added to the Bash tool's `PATH`) that reads, writes, and queries the configs.
- Skills that wrap the CLI for read context, add file/directory entries, and manage labels.
- Bats test suite covering the CLI.
- README documenting the schema, CLI, and example label conventions.

**Out of scope (for this cycle).**

- Any changes to `selrahcd-obsidian-bridge`. It continues reading `.claude/obsidian-bridge.json` exactly as today. A future cycle will refactor it onto the new shared file once the new plugin's CLI is validated in practice.
- Migration tooling for existing `.claude/obsidian-bridge.json` files.
- Reserved/standardized label vocabulary. Labels are user-defined; the README provides examples only.
- Wiring `/track` and `/til` to the new CLI for destination lookup.

## Architecture

```
.obsidian-vault-context.json (at any directory root)
~/.obsidian-vault-context.json (global)
        │
        └──── owned by ──── obsidian-vault-context (this plugin)
                              ├─ obsidian-context CLI  (in bin/)
                              ├─ skills wrapping the CLI
                              └─ bats test suite

.claude/obsidian-bridge.json (existing, unchanged)
        │
        └──── owned by ──── obsidian-bridge (untouched in this cycle)
```

The two config files coexist during this cycle. The new plugin owns the new file. The README explicitly explains both files and the eventual migration path.

## Plugin layout

```
selrahcd-obsidian-vault-context/
├── .claude-plugin/
│   └── plugin.json                   # name=obsidian-vault-context, version=1.0.0
├── bin/
│   └── obsidian-context              # main CLI dispatcher (only thing on PATH)
├── lib/
│   ├── traversal.sh                  # walk-up + global lookup
│   ├── merge.sh                      # concat lists, closest-wins labels
│   ├── schema.sh                     # JSON shape validation (jq filters)
│   └── output.sh                     # human/JSON formatters
├── skills/
│   ├── read-context/SKILL.md         # auto-invoked: surface relevant entries
│   ├── add-file/SKILL.md             # guided: add a file entry
│   ├── add-directory/SKILL.md        # guided: add a directory entry
│   └── labels/SKILL.md               # manage label vocabulary
├── tests/
│   ├── helpers.bash
│   ├── files.bats                    # add/remove/list files + their errors
│   ├── directories.bats              # add/remove/list directories + their errors
│   ├── labels.bats                   # label set/remove/list, closest-wins merge + errors
│   ├── traversal.bats                # walk-up correctness, global merge, source attribution
│   ├── scopes.bats                   # local / current-directory / global / <path> + errors
│   ├── output.bats                   # human format + --json shape
│   └── run.sh                        # `bats tests/`
└── README.md
```

## Config file schema

**Locations.**

- Per-directory: `<dir>/.obsidian-vault-context.json` at the directory root (not inside `.claude/`). Users may gitignore as they see fit.
- Global: `~/.obsidian-vault-context.json`. Same shape as per-directory.

**Top-level keys** (all optional, modular by namespace):

```json
{
  "files": [...],
  "directories": [...],
  "labels": { "<label-name>": "<description>" }
}
```

`files`, `directories`, and `labels` are owned by this plugin. Future plugins can add their own top-level keys (e.g. an `obsidian-bridge` namespaced object) without conflicting; the CLI emits a soft warning to stderr for unknown keys but does not error.

**Entry shape** (used in both `files[]` and `directories[]`):

```json
{
  "path": "🦺 Projects/Marketplace.md",
  "description": "Active marketplace project notes",
  "labels": ["marketplace", "project"]
}
```

| Field | Required | Notes |
|---|---|---|
| `path` | yes | Vault-relative path. Used as identity for write/remove subcommands. |
| `description` | yes | One-line explanation; the agent reads this to decide relevance. |
| `labels` | no | Array of label names for CLI filtering. Empty/omitted = uncategorized. |

`labels{}` map keys are label names (kebab-case recommended); values are descriptions. The CLI surfaces these via `obsidian-context labels`. Missing description for a label that an entry references is allowed (CLI prints `<no description>`).

**Validation.**

- Read path: malformed JSON → hard error naming the offending file. Unknown top-level keys → soft warn to stderr; parsing continues.
- Malformed entries (missing `path` or `description`, wrong types) → hard error, parse aborts.
- Validation lives in `lib/schema.sh` (sourced by `bin/obsidian-context` via a path resolved from the script's own location, so the CLI works regardless of where it is invoked from). The library is exercised by bats.

## Traversal and merge

**Traversal.** Given a CWD, the CLI builds an ordered list of config files, closest-first:

1. Walk from CWD up to `/`. At each directory, if `.obsidian-vault-context.json` exists, append.
2. Always append `~/.obsidian-vault-context.json` last (the global) if it exists.

The walk does not stop at git boundaries, `$HOME`, or sentinel files. The user can verify the resolved list with `obsidian-context where`.

**Merge — `files[]` and `directories[]`.** Concatenate entries from every loaded config in closest-first order. Each entry is augmented at output time with a virtual `source` field (the absolute path of the config it came from). The `source` field is not stored on disk. Duplicate `path` values across levels are kept as-is — two levels may intentionally describe the same vault path differently.

**Merge — `labels{}`.** For each label name, the description from the closest config wins. Deeper levels can refine a global label. `obsidian-context labels --show-source` displays where the winning description came from and which other levels also defined the label.

**Filtering and search** (applied after merge):

- `--label <name>` (repeatable, AND default; `--any` for OR) — entry must carry the label.
- `--kind files` / `--kind directories` — restrict to one collection.
- `--search <term>` — case-insensitive substring match against `path` and `description`.

**Output format.**

- Default: human-readable, one entry per line: `<path>  [labels]  <description>` followed by an indented `from: <source>` line.
- `--json`: structured JSON, including `source`, suitable for piping through `jq` in skills.

## CLI surface

Binary: `obsidian-context` (in `bin/`, auto-added to Bash tool's `PATH`).

**Global flags.**

- `--json` — structured output instead of human format.
- `--cwd <path>` — pretend CLI was invoked from `<path>` (testability and skill ergonomics; defaults to `$PWD`).

**Read subcommands.**

```
obsidian-context list       [--kind files|directories]
                            [--label <name>]…  [--any]
                            [--search <term>]
                            [--json]

obsidian-context labels     [--search <term>]
                            [--show-source]
                            [--json]

obsidian-context where      [--json]
```

**Write subcommands.**

```
obsidian-context add file <vault-path>
                          --description <text>
                          [--label <name>]…
                          [--scope <scope>]
                          [--force]

obsidian-context add directory <vault-path>
                               --description <text>
                               [--label <name>]…
                               [--scope <scope>]
                               [--force]

obsidian-context remove file <vault-path>      [--scope <scope>]
obsidian-context remove directory <vault-path> [--scope <scope>]

obsidian-context label set <name> <description> [--scope <scope>]
obsidian-context label remove <name>             [--scope <scope>]
```

**`--scope` values:**

- `local` — closest existing `.obsidian-vault-context.json` at or above CWD. **Default.** If none exists, the CLI exits non-zero with a message instructing the user to choose `current-directory` or pass an explicit directory.
- `current-directory` — `$PWD/.obsidian-vault-context.json`, creating it if absent.
- `global` — `~/.obsidian-vault-context.json`, creating it if absent.
- `<path>` — `<path>/.obsidian-vault-context.json`. The directory at `<path>` must exist; the file is created if absent.

**Disambiguation rule.** If the `--scope` value is exactly `local`, `current-directory`, or `global`, it is the keyword. Anything else is interpreted as a directory path. A directory literally named `local`, `current-directory`, or `global` must be addressed with a `/` (e.g. `./local` or `/abs/path/local`) to be parsed as a path.

Writes are atomic: read-modify-write via `<file>.tmp` + `mv`. Concurrent write detection: the CLI records the file's mtime at read time and compares before rename; on mismatch, it aborts with `obsidian-context: <subcommand>: file changed on disk; re-run` and exits non-zero. No file locking.

`--force` is required to overwrite an existing entry's `description` or `labels`. Without it, conflicting writes exit non-zero with a message describing the conflict.

**Help.** `obsidian-context --help` lists subcommands. `obsidian-context <subcommand> --help` shows that subcommand's flags. Errors go to stderr with the prefix `obsidian-context: <subcommand>: <message>`.

## Skills

The plugin ships four skills.

### `read-context` (auto-invoked)

- **When:** the user mentions vault tracking, asks where notes about something live, is about to write to the vault, or invokes anything that touches Obsidian.
- **What:** runs `obsidian-context list` (optionally with a `--label` or `--search` derived from the request), reports merged candidate notes/directories, advises the agent which seem most relevant.
- **Frontmatter:** model-invocable and user-invocable (defaults). No `paths` restriction (relevance comes from intent, not file globs).

### `add-file` (model-invocable + user-invocable)

- **When:** a relevant vault note is discovered or created during a session and is not yet indexed; or the user runs `/obsidian-vault-context:add-file`.
- **What:** prompts for or derives `path`, `description`, `labels[]`, `scope`. Calls `obsidian-context labels` first to suggest existing labels (encouraging reuse over inventing duplicates). Then runs `obsidian-context add file ...`.

### `add-directory`

Same pattern as `add-file`, for directory entries.

### `labels` (model-invocable and user-invocable)

Lets agent and user list, define, refine, or remove labels via `obsidian-context label set/remove`. The agent invokes it when it notices a missing label description ("you used `auth-refactor` but it's not defined; want to define it?"); the user invokes it via `/obsidian-vault-context:labels` to list or curate the vocabulary.

## Testing

**Bats organization** — one file per feature family, errors co-located with their feature:

```
tests/files.bats         # files: add/remove/list + their error cases
tests/directories.bats   # directories: add/remove/list + their error cases
tests/labels.bats        # labels: set/remove/list + closest-wins merge + their error cases
tests/traversal.bats     # walk-up + global merge + source attribution
tests/scopes.bats        # scope resolution (local/current-directory/global/<path>) + error cases
tests/output.bats        # human format + --json shape
```

**Fixture pattern.** Each test creates a tmpdir, lays out a synthetic directory tree with controlled `.obsidian-vault-context.json` files at chosen levels, sets `HOME=$tmpdir/home` to control the global, and invokes the CLI with `--cwd <tmpdir>/A/B/C`. No reliance on `$PWD` or the user's real `$HOME`. Helpers in `tests/helpers.bash` create trees concisely. JSON output tests pipe through `jq` to assert exact shape; human-format tests use line-anchored regex.

**CI.** `tests/run.sh` runs `bats tests/`. A GitHub Actions workflow at the marketplace repo root runs bats on push/PR for changes under `selrahcd-obsidian-vault-context/`.

## Error handling principles

- Read path: malformed JSON → hard error naming the offending file. Unknown top-level keys → soft warn to stderr.
- Write path: atomic via `<file>.tmp` + `mv`. mtime check before rename for best-effort concurrent-write detection. Conflicts without `--force` → exit non-zero with a clear message.
- Missing `jq` or `bash` ≥ 4 → CLI prints install instruction at startup and exits.

## Dependencies

- `bash` ≥ 4
- `jq`

Both are already required by the existing `obsidian-bridge` plugin, so no new install burden for users.

## Distribution

- Plugin directory: `selrahcd-obsidian-vault-context/` at the marketplace root.
- `.claude-plugin/plugin.json`: `name: "obsidian-vault-context"`, `version: "1.0.0"`.
- `marketplace.json`: new plugin entry pointing at `./selrahcd-obsidian-vault-context`, version `1.0.0`.
- README documents:
  - What the plugin does and when to use it.
  - Config file locations and schema with examples.
  - CLI subcommand reference.
  - Skill list.
  - A "labels in practice" section with non-prescriptive examples (`til-target`, `track-target`, `daily-note`, `project`, `read-only`).
  - The coexistence note: this plugin reads `.obsidian-vault-context.json`; the existing `obsidian-bridge` plugin still reads `.claude/obsidian-bridge.json` until a future cycle.

## Future work (explicitly deferred)

- Refactor `selrahcd-obsidian-bridge` to read its config from a namespaced key inside `.obsidian-vault-context.json`. Will be a breaking `2.0.0` of that plugin.
- Wire `/til` and `/track` to consult `obsidian-context list --label <name>` for destination candidates.
- Automated migration command to move `.claude/obsidian-bridge.json` content into `.obsidian-vault-context.json`.
- Drop `obsidian-bridge.tracking[]` in favor of `files[]` + `labels` once both plugins share the file.
