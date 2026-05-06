# obsidian-vault-context — CLI & skill UX improvements

**Status:** Design  
**Date:** 2026-05-03  
**Plugin:** `selrahcd-obsidian-vault-context`  
**Target version:** `1.3.0` (minor)

## Background

User feedback after using the `obsidian-context` CLI (via the `add-directory` skill) surfaced six points of friction. Three are CLI bugs/UX gaps, one is a skill dependency, one is a documentation gap, and one self-resolves once the others are in place. None are breaking changes; this is a polish release.

### Feedback summary

| # | Issue | Root cause |
|---|-------|------------|
| 1 | `--scope directory` rejected with cryptic error `--scope: directory does not exist: directory` | `lib/scope.sh` catch-all treats unknown values as relative dirs and reports the literal `cd` failure. |
| 2 | `obsidian-context add directory --help` prints global help, not subcommand help | `add` / `remove` / `label` parsers consume the first positional arg before scanning for `--help`. |
| 3 | `obsidian-context labels` and `obsidian-context where` print nothing on empty result | Human-output paths emit no text when the result set is empty. Indistinguishable from success-with-empty vs. silent failure. |
| 4 | Skills depend on `obsidian-cli`, which is not the actual CLI name and may not be installed | Skills reference `obsidian-cli`. The real binary shipped with Obsidian.app is `obsidian` (e.g. `/Applications/Obsidian.app/Contents/MacOS/obsidian`). |
| 5 | First-run UX: when no config exists, two failed runs to land on the right invocation | Compounded effect of #1 and #2; the underlying error messages are correct. |
| 6 | Each invocation triggers a Claude Code permission prompt | `Bash(obsidian-context:*)` is not on the user's allowlist by default; plugin doesn't document the fix. |

## Goals

- A user who runs `obsidian-context <subcommand> --help` always sees that subcommand's flags.
- An invalid `--scope` value produces an error that names the accepted alternatives and suggests the closest typo correction.
- Empty results from `labels` / `where` / `list` produce a one-line stderr message; `--json` output stays unchanged.
- Skills verify vault paths using the actual `obsidian` binary, with no reference to the absent `obsidian-cli`.
- README documents how to suppress the permission prompt.

## Non-goals

- No changes to the JSON config schema, scope semantics, merge order, or `--json` output shape.
- No new subcommands, flags, or vault-path configuration in `obsidian-context` itself.
- No automated permission-prompt setup (CLI flag, hook, or one-time setup skill). Documentation only.

## Design

### 1. Subcommand `--help` (Issue #2)

In `bin/obsidian-context`, the `add`, `remove`, and `label` parsers extract a positional arg (`kind` / `vault_path` / `name` / `desc`) before entering the flag-parsing `while` loop. Move `--help` detection earlier:

- At the top of the `add)` case branch, scan `"$@"` for `--help|-h`. If present, print the `add` usage block (covering both `add file` and `add directory`) and exit 0.
- Same pattern for `remove)` and `label)`.

Then keep the existing per-flag `--help|-h)` cases in the inner `while` loops as a no-op fallback (they remain reachable only after positional args have been consumed, which is fine).

For `add file --help` vs. `add directory --help`, the existing inline help (lines 287–296 of `bin/obsidian-context`) is what we want — but it currently runs only after positional parsing succeeds. The early-scan should detect the `kind` (`file` / `directory`) and select the variant when shown. If no kind is given (`add --help`), print a combined block.

Also flesh out the single-line usage in `remove` and `label set` / `label remove` to list all flags and the `--scope` value vocabulary.

### 2. Better `--scope` error (Issue #1)

In `lib/scope.sh`, the `*)` catch-all currently does:

```sh
resolved="$(cd "$cwd" 2>/dev/null && cd "$scope" 2>/dev/null && pwd -P)" || {
  printf 'obsidian-context: --scope: directory does not exist: %s\n' "$scope" >&2
  return 1
}
```

Before the `cd` attempt, check the value against a small typo list — `directory`, `current`, `cwd`, `here`, `project` — and on hit print:

```
obsidian-context: --scope: unknown value "directory".
Did you mean --scope current-directory?
Accepted values: local | current-directory | global | <path>
```

For other unknown values (probably real paths the user mistyped), keep the `cd` attempt but improve the failure message to also list the four accepted forms:

```
obsidian-context: --scope: directory does not exist: <value>
Accepted values: local | current-directory | global | <path>
```

### 3. Empty-state messages (Issue #3)

Three commands need a one-line stderr message when human-output mode produces nothing:

- **`labels`** — when the merged label map is empty:
  ```
  obsidian-context: no labels defined yet (define one with: obsidian-context label set <name> "<description>")
  ```
- **`where`** — when no configs are loaded:
  ```
  obsidian-context: no .obsidian-vault-context.json found at or above <cwd>, and no global config at ~/.obsidian-vault-context.json
  ```
- **`list`** — when files and directories are both empty:
  ```
  obsidian-context: no entries indexed for this directory yet
  ```

All three exit 0 (empty is not an error), print to stderr (so piping to other tools is unaffected), and only fire when `--json` is *off*. With `--json`, the CLI still emits `{}` / `{"labels":{}}` / `{"files":[],"directories":[],"labels":{}}` respectively.

### 4. Skill verification via `obsidian` (Issue #4)

The `obsidian` binary ships with Obsidian.app on macOS (`/Applications/Obsidian.app/Contents/MacOS/obsidian`, on PATH automatically when Obsidian is running). It exposes:

- `obsidian file path="<vault-path>"` — exits 0 if the file exists in the active vault, exits non-zero with stderr `Error: File "<path>" not found.` otherwise.
- `obsidian folder path="<vault-path>"` — same contract for folders.
- `obsidian search query="<text>"` — for finding candidates.

In `skills/add-file/SKILL.md` step 2, replace the `obsidian-cli` reference with:

```bash
obsidian file path="<vault-path>"
```

If exit 0, proceed. If exit non-zero, run `obsidian search query="<basename without extension>"` and present the closest matches (existing flow). Drop the `obsidian:obsidian-cli` skill reference.

In `skills/add-directory/SKILL.md` step 2, same pattern with:

```bash
obsidian folder path="<vault-path>"
```

For candidates, use `obsidian search query="<basename of vault-path>"` — same as `add-file`. (Verified: `obsidian folder ... info=folders` returns just a count, not a name list, so it's not useful for candidate suggestions.)

Add a one-line note to both skills:

> If `obsidian` is not on PATH (Obsidian.app not installed, or non-macOS), skip verification and ask the user to confirm the path is correct before adding. Do not silently register an unverified entry.

### 5. First-run UX (Issue #5)

No code change beyond what sections 1, 2, and 3 already deliver. After those, the failure path becomes:

1. Agent runs `obsidian-context add directory ... --scope directory` (typo).
2. CLI prints the typo-aware error from section 2 → agent re-runs with `--scope current-directory`.
3. Done.

Add a "First run" subsection to `README.md` (its own heading, separate from "Reducing permission prompts"):

> If the CLI errors with `no existing .obsidian-vault-context.json found at or above <cwd>`, you have no index here yet. Use `--scope current-directory` to create one in `$PWD`, or `--scope global` for a `~/.obsidian-vault-context.json`.

### 6. Permission-prompt setup (Issue #6)

Add a "Reducing permission prompts" subsection to `README.md` under Installation:

```markdown
## Reducing permission prompts

Each `obsidian-context` invocation will trigger a Claude Code permission prompt
unless the binary is on your allowlist. Add the following to either
`~/.claude/settings.json` (global) or `.claude/settings.json` (project):

{
  "permissions": {
    "allow": ["Bash(obsidian-context:*)"]
  }
}
```

No cross-plugin skill references. No automation in the plugin itself.

## Testing

bats suite, `tests/`:

- **`tests/help.bats`** *(new file)* — for each of `add file --help`, `add directory --help`, `add --help`, `remove file --help`, `remove directory --help`, `label set --help`, `label remove --help`: assert exit 0 and that stdout contains the relevant flag names (`--description`, `--scope`, `--label`, etc.).
- **`tests/scopes.bats`** *(extend)* — assert `--scope directory`, `--scope cwd`, `--scope here`, `--scope current` all produce the typo-aware error containing `Did you mean --scope current-directory?`. Assert `--scope nonexistent-relative-path` produces the improved error listing the four accepted forms.
- **`tests/labels.bats`** *(extend)* — empty vault context: `obsidian-context labels` exits 0, prints the empty-state message to stderr, prints nothing to stdout. With `--json`: stdout is `{"labels":{}}`, stderr is empty.
- **`tests/output.bats`** *(extend)* — `where` with no configs: exit 0, stderr message, empty stdout. `list` with empty configs: same. `--json` variants: existing JSON shape, stderr empty.
- **`tests/files.bats` / `tests/directories.bats`** — no changes (skill-level verification is not exercised here; CLI write behavior is unchanged).

Tests must pass before commit. The full suite runs via `tests/run.sh`.

## Files changed

- `bin/obsidian-context` — early `--help` detection in `add`/`remove`/`label`; expanded usage blocks; empty-state messages for `labels`/`list`/`where`.
- `lib/scope.sh` — typo blacklist and improved error in catch-all branch.
- `skills/add-file/SKILL.md` — replace `obsidian-cli` with `obsidian`; concrete commands; PATH-fallback note.
- `skills/add-directory/SKILL.md` — same.
- `README.md` — "Reducing permission prompts" section and "First run" section.
- `.claude-plugin/plugin.json` — bump to `1.3.0`.
- `.claude-plugin/marketplace.json` (repo root) — bump matching plugin entry to `1.3.0`.
- `tests/help.bats` — new file.
- `tests/scopes.bats`, `tests/labels.bats`, `tests/output.bats` — extended.

## Out of scope

- `lib/merge.sh`, `lib/traversal.sh`, `lib/write.sh`, `lib/schema.sh`, `lib/output.sh` formatters (the empty-state messages live in `bin/obsidian-context`, not the formatters, so they don't bleed into JSON output).
- `read-context` and `labels` skills — no behavior change needed; they already use the right CLI.
- Any vault-path configuration inside `obsidian-context` itself.
- Automated permission-prompt setup (settings file shipping, hooks, init command).
