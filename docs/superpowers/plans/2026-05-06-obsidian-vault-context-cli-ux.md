# obsidian-vault-context CLI & skill UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address six feedback items in the `obsidian-vault-context` plugin: subcommand `--help` routing, typo-aware `--scope` errors, empty-state messages, replacing the `obsidian-cli` skill dependency with the `obsidian` binary, and README guidance for permission prompts and first-run flow. Ships as `1.3.0`.

**Architecture:** All CLI changes are in `bin/obsidian-context` and `lib/scope.sh`; tests are bats files in `tests/`. Skills change in `skills/add-file/SKILL.md` and `skills/add-directory/SKILL.md` (Markdown only). README and version bumps round out the release. No new files in `lib/`. One new test file (`tests/help.bats`).

**Tech Stack:** bash 3.2+, jq, bats-core for tests. Markdown for skills/README. JSON for plugin manifests.

**Spec:** `docs/superpowers/specs/2026-05-03-obsidian-vault-context-cli-ux-design.md`.

**Working directory for all commands:** `/Users/charles/Workspace/perso/claude/selrahcd-marketplace/selrahcd-obsidian-vault-context` unless otherwise noted.

---

## File Structure

| File | Role | Modified or Created |
|------|------|---------------------|
| `bin/obsidian-context` | CLI dispatcher; gets early `--help` detection in `add`/`remove`/`label`; expanded usage blocks; empty-state messages for `labels`/`list`/`where`. | Modified (Tasks 1, 3) |
| `lib/scope.sh` | `--scope` resolver; gets typo blacklist and improved error in catch-all branch. | Modified (Task 2) |
| `skills/add-file/SKILL.md` | Replace `obsidian-cli` references with `obsidian` binary. | Modified (Task 4) |
| `skills/add-directory/SKILL.md` | Same. | Modified (Task 4) |
| `README.md` | "Reducing permission prompts" + "First run" sections. | Modified (Task 5) |
| `tests/help.bats` | New file — covers all subcommand `--help` flows. | Created (Task 1) |
| `tests/scopes.bats` | Extended for typo-aware errors. Existing "errors when directory does not exist" test updated. | Modified (Task 2) |
| `tests/labels.bats` | Existing "empty when no configs" test updated for new stderr message. | Modified (Task 3) |
| `tests/output.bats` | New `where` empty-state and `list` empty-state tests. | Modified (Task 3) |
| `tests/files.bats` | Existing "list: empty when no configs" test updated for new message. | Modified (Task 3) |
| `.claude-plugin/plugin.json` | Version bump to `1.3.0`. | Modified (Task 6) |
| `../.claude-plugin/marketplace.json` | Plugin entry version bump to `1.3.0`. | Modified (Task 6) |

---

## Conventions used in this plan

- **bats `run`**: in this codebase, `run` captures both stdout and stderr into `$output` (verified via `tests/scopes.bats` line 35–37 which asserts on a stderr message via `$output`). When a test needs to distinguish stdout from stderr, use `run --separate-stderr` and check `$stderr` separately. Keep new tests consistent with the dominant pattern unless splitting matters.
- **TDD**: Each task writes a failing test, runs it to confirm failure, implements the change, runs tests to confirm pass, then commits. The test file `tests/run.sh` runs the full suite.
- **Commit style**: conventional commits with the `obsidian-vault-context` scope (matches recent history: `feat(obsidian-vault-context): ...`, `chore(obsidian-vault-context): ...`).
- **Test helpers**: All tests use `tests/helpers.bash`. `setup_tmp_root` / `teardown_tmp_root` create an isolated `$TMP_ROOT` and `$HOME`. `run_cli <cwd> [args...]` invokes the CLI with `--cwd <cwd>`. `write_config <abs-dir> <json>` and `write_global_config <json>` create configs.
- **Run tests**: `bash tests/run.sh` from the plugin root, or `bats tests/<file>.bats` for a single file.

---

## Task 1: Subcommand `--help` routing

**Background:** The `add)`, `remove)`, and `label)` parsers in `bin/obsidian-context` extract a positional arg before checking for `--help`, so `obsidian-context add directory --help` errors with "missing description" instead of showing help. Fix: add an early scan over `"$@"` in each subcommand branch that exits 0 with the right usage block when `--help` is present anywhere in the args.

**Files:**
- Modify: `bin/obsidian-context` (add helper functions; insert early scans in `add)`, `remove)`, `label)` branches; expand existing one-line usage strings)
- Create: `tests/help.bats`

### Task 1.1: Write `tests/help.bats` covering all subcommand help variants

- [ ] **Step 1: Create the failing test file**

Create `tests/help.bats` with this content:

```bash
#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "add file --help: shows file-specific usage and exits 0" {
  run_cli "$TMP_ROOT" add file --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add file"* ]]
  [[ "$output" == *"--description"* ]]
  [[ "$output" == *"--label"* ]]
  [[ "$output" == *"--scope"* ]]
  [[ "$output" == *"--force"* ]]
}

@test "add directory --help: shows directory-specific usage and exits 0" {
  run_cli "$TMP_ROOT" add directory --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add directory"* ]]
  [[ "$output" == *"--description"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "add --help (no kind): shows combined usage" {
  run_cli "$TMP_ROOT" add --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add file"* ]]
  [[ "$output" == *"add directory"* ]]
  [[ "$output" == *"--description"* ]]
}

@test "add file --help: --help wins even after positional vault-path" {
  run_cli "$TMP_ROOT" add file foo.md --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add file"* ]]
  [[ "$output" == *"--description"* ]]
}

@test "remove file --help: shows usage and exits 0" {
  run_cli "$TMP_ROOT" remove file --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"remove file"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "remove directory --help: shows usage and exits 0" {
  run_cli "$TMP_ROOT" remove directory --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"remove directory"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "label set --help: shows usage and exits 0" {
  run_cli "$TMP_ROOT" label set --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"label set"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "label remove --help: shows usage and exits 0" {
  run_cli "$TMP_ROOT" label remove --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"label remove"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "list --help still works (regression check)" {
  run_cli "$TMP_ROOT" list --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"list"* ]]
  [[ "$output" == *"--label"* ]]
}

@test "labels --help still works (regression check)" {
  run_cli "$TMP_ROOT" labels --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"labels"* ]]
}
```

- [ ] **Step 2: Run the new test file to confirm failures**

Run: `bats tests/help.bats`

Expected: most `add`/`remove`/`label` tests FAIL because the current parser treats `--help` as a positional or errors out; `list --help` and `labels --help` PASS (they already work). Note exact failures so we can verify the implementation against them.

- [ ] **Step 3: Commit the failing tests**

```bash
git add tests/help.bats
git commit -m "test(obsidian-vault-context): add bats coverage for subcommand --help routing"
```

### Task 1.2: Implement help-detection helpers in `bin/obsidian-context`

- [ ] **Step 1: Add three usage-printer helper functions near the top of `bin/obsidian-context`**

Open `bin/obsidian-context`. After the `print_help()` function definition (which currently ends around line 45) and BEFORE the global flag parsing (`EFFECTIVE_CWD="$PWD"` block), insert these three new functions:

```bash
# Print usage for `add` subcommand. Optional first arg is "file" or "directory"
# to print only that variant; empty arg prints both.
print_add_help() {
  local kind="${1:-}"
  if [[ -z "$kind" || "$kind" == "file" ]]; then
    cat <<'EOF'
Usage: obsidian-context add file <vault-path>
                          --description <text>
                          [--label <name>]...
                          [--scope local|current-directory|global|<path>]
                          [--force]

Adds a file entry to the directory-aware index. Default scope is `local`
(closest existing config above CWD). Use `current-directory` to create a new
config in $PWD.
EOF
  fi
  if [[ -z "$kind" ]]; then
    printf '\n'
  fi
  if [[ -z "$kind" || "$kind" == "directory" ]]; then
    cat <<'EOF'
Usage: obsidian-context add directory <vault-path>
                          --description <text>
                          [--label <name>]...
                          [--scope local|current-directory|global|<path>]
                          [--force]

Adds a directory entry to the directory-aware index. Vault paths should end
with a trailing slash (e.g. "Projects/").
EOF
  fi
}

# Print usage for `remove` subcommand. Optional kind selects the variant.
print_remove_help() {
  local kind="${1:-}"
  if [[ -z "$kind" || "$kind" == "file" ]]; then
    cat <<'EOF'
Usage: obsidian-context remove file <vault-path>
                          [--scope local|current-directory|global|<path>]
EOF
  fi
  if [[ -z "$kind" ]]; then
    printf '\n'
  fi
  if [[ -z "$kind" || "$kind" == "directory" ]]; then
    cat <<'EOF'
Usage: obsidian-context remove directory <vault-path>
                          [--scope local|current-directory|global|<path>]
EOF
  fi
}

# Print usage for `label` subcommand. Optional action selects the variant.
print_label_help() {
  local action="${1:-}"
  if [[ -z "$action" || "$action" == "set" ]]; then
    cat <<'EOF'
Usage: obsidian-context label set <name> <description>
                          [--scope local|current-directory|global|<path>]

Defines or refines a label. Upserts (no --force needed) — the closest level's
description wins on read.
EOF
  fi
  if [[ -z "$action" ]]; then
    printf '\n'
  fi
  if [[ -z "$action" || "$action" == "remove" ]]; then
    cat <<'EOF'
Usage: obsidian-context label remove <name>
                          [--scope local|current-directory|global|<path>]
EOF
  fi
}

# Scan args for --help|-h. Echoes the matching kind/action context if a known
# positional appears in args (controlled by the second arg, which lists valid
# context tokens space-separated). Sets HELP_FOUND=1/0. Use as:
#   help_scan "$@" -- file directory
help_scan() {
  HELP_FOUND=0
  HELP_CTX=""
  local args_done=0
  local valid=()
  for arg in "$@"; do
    if (( args_done == 0 )); then
      if [[ "$arg" == "--" ]]; then
        args_done=1
        continue
      fi
      case "$arg" in
        --help|-h) HELP_FOUND=1 ;;
      esac
    else
      valid+=("$arg")
    fi
  done
  if (( HELP_FOUND == 0 )); then
    return 0
  fi
  # Find the first non-flag arg that matches a valid context token.
  for arg in "$@"; do
    [[ "$arg" == "--" ]] && break
    case "$arg" in
      --*|-*) continue ;;
    esac
    for v in "${valid[@]}"; do
      if [[ "$arg" == "$v" ]]; then
        HELP_CTX="$arg"
        return 0
      fi
    done
  done
  return 0
}
```

- [ ] **Step 2: Insert early `--help` detection at the top of the `add)` case branch**

Find the `add)` branch (around line 244 in the current `bin/obsidian-context`). Just AFTER the line `add)` and BEFORE the existing `[[ $# -gt 0 ]] || { ...` line, insert:

```bash
    help_scan "$@" -- file directory
    if (( HELP_FOUND == 1 )); then
      print_add_help "$HELP_CTX"
      exit 0
    fi
```

- [ ] **Step 3: Insert early `--help` detection at the top of the `remove)` case branch**

Find the `remove)` branch (around line 353). Just AFTER the line `remove)` and BEFORE the existing `[[ $# -gt 0 ]] || { ...` line, insert:

```bash
    help_scan "$@" -- file directory
    if (( HELP_FOUND == 1 )); then
      print_remove_help "$HELP_CTX"
      exit 0
    fi
```

- [ ] **Step 4: Insert early `--help` detection at the top of the `label)` case branch**

Find the `label)` branch (around line 400). Just AFTER the line `label)` and BEFORE the existing `[[ $# -gt 0 ]] || { ...` line, insert:

```bash
    help_scan "$@" -- set remove
    if (( HELP_FOUND == 1 )); then
      print_label_help "$HELP_CTX"
      exit 0
    fi
```

- [ ] **Step 5: Run the help test file to verify all pass**

Run: `bats tests/help.bats`

Expected: all 10 tests PASS.

- [ ] **Step 6: Run the full test suite to verify no regressions**

Run: `bash tests/run.sh`

Expected: all tests PASS, including the existing files/directories/labels/scopes/output tests.

- [ ] **Step 7: Commit**

```bash
git add bin/obsidian-context
git commit -m "feat(obsidian-vault-context): route --help to subcommand-specific usage"
```

---

## Task 2: Typo-aware `--scope` errors

**Background:** `lib/scope.sh`'s catch-all branch treats unknown `--scope` values as relative paths and reports the literal `cd` failure (`obsidian-context: --scope: directory does not exist: directory`). Add a typo blacklist that catches likely mistakes (`directory`, `current`, `cwd`, `here`, `project`) and points to `current-directory`. For genuine path failures, list the four accepted forms.

**Files:**
- Modify: `lib/scope.sh`
- Modify: `tests/scopes.bats` (extend with typo cases; update existing "directory does not exist" test for the new error format)

### Task 2.1: Write failing tests for typo-aware errors

- [ ] **Step 1: Append new tests to `tests/scopes.bats`**

Add these test blocks at the end of `tests/scopes.bats`:

```bash
@test "scope directory: typo error suggests current-directory" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope directory
  [ "$status" -ne 0 ]
  [[ "$output" == *'unknown value "directory"'* ]]
  [[ "$output" == *"Did you mean --scope current-directory"* ]]
  [[ "$output" == *"local | current-directory | global | <path>"* ]]
}

@test "scope cwd: typo error suggests current-directory" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope cwd
  [ "$status" -ne 0 ]
  [[ "$output" == *"Did you mean --scope current-directory"* ]]
}

@test "scope here: typo error suggests current-directory" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope here
  [ "$status" -ne 0 ]
  [[ "$output" == *"Did you mean --scope current-directory"* ]]
}

@test "scope current: typo error suggests current-directory" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope current
  [ "$status" -ne 0 ]
  [[ "$output" == *"Did you mean --scope current-directory"* ]]
}

@test "scope project: typo error suggests current-directory" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope project
  [ "$status" -ne 0 ]
  [[ "$output" == *"Did you mean --scope current-directory"* ]]
}
```

- [ ] **Step 2: Update the existing "directory does not exist" test**

In `tests/scopes.bats`, find this block (currently lines 61–66):

```bash
@test "scope <path>: errors when directory does not exist" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope "$TMP_ROOT/does/not/exist"
  [ "$status" -ne 0 ]
  [ "$output" = "obsidian-context: --scope: directory does not exist: $TMP_ROOT/does/not/exist" ]
}
```

Replace the assertion line with the new two-line expected output:

```bash
@test "scope <path>: errors when directory does not exist" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope "$TMP_ROOT/does/not/exist"
  [ "$status" -ne 0 ]
  expected="obsidian-context: --scope: directory does not exist: $TMP_ROOT/does/not/exist
Accepted values: local | current-directory | global | <path>"
  [ "$output" = "$expected" ]
}
```

- [ ] **Step 3: Run the test file to confirm failures**

Run: `bats tests/scopes.bats`

Expected: 5 new typo tests FAIL (current behavior treats them as paths and gives a different error). The updated "directory does not exist" test FAILs because the current error has only one line. The other existing tests (local, current-directory, global, abs-path, ./local) still PASS.

- [ ] **Step 4: Commit failing tests**

```bash
git add tests/scopes.bats
git commit -m "test(obsidian-vault-context): assert typo-aware --scope errors and four-form hint"
```

### Task 2.2: Implement typo-aware errors in `lib/scope.sh`

- [ ] **Step 1: Replace the catch-all branch in `lib/scope.sh`**

Open `lib/scope.sh`. Replace the `*)` branch (currently lines 50–58) — the entire block from `*)` down to and including `;;` — with:

```bash
    *)
      # Detect common typos before treating the value as a path.
      case "$scope" in
        directory|current|cwd|here|project)
          printf 'obsidian-context: --scope: unknown value "%s".\n' "$scope" >&2
          printf 'Did you mean --scope current-directory?\n' >&2
          printf 'Accepted values: local | current-directory | global | <path>\n' >&2
          return 1
          ;;
      esac
      local resolved
      # Resolve relative paths against $cwd, not the process $PWD.
      resolved="$(cd "$cwd" 2>/dev/null && cd "$scope" 2>/dev/null && pwd -P)" || {
        printf 'obsidian-context: --scope: directory does not exist: %s\n' "$scope" >&2
        printf 'Accepted values: local | current-directory | global | <path>\n' >&2
        return 1
      }
      printf '%s\n' "$resolved/.obsidian-vault-context.json"
      ;;
```

- [ ] **Step 2: Run the scopes test file to verify pass**

Run: `bats tests/scopes.bats`

Expected: all tests PASS, including the 5 new typo cases and the updated path-not-found case.

- [ ] **Step 3: Run the full test suite for regressions**

Run: `bash tests/run.sh`

Expected: all tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/scope.sh
git commit -m "feat(obsidian-vault-context): typo-aware --scope errors with accepted-values hint"
```

---

## Task 3: Empty-state messages

**Background:** `obsidian-context labels`, `obsidian-context where`, and `obsidian-context list` print nothing to stdout when the result is empty. Indistinguishable from silent failure. Add stderr messages that fire only when `--json` is OFF and exit 0. Existing tests that asserted empty `$output` for these cases need updating (since this codebase's `run` captures stderr in `$output`).

**Files:**
- Modify: `bin/obsidian-context` (`labels)`, `where)`, `list)` branches)
- Modify: `tests/labels.bats` (update the empty-state test)
- Modify: `tests/output.bats` (add `where` empty-state and `list` empty-state cases including `--json` checks)
- Modify: `tests/files.bats` (update the empty `list` test)

### Task 3.1: Write failing tests for empty-state messages

- [ ] **Step 1: Update `tests/labels.bats` empty-state test**

In `tests/labels.bats`, find this block (lines 8–12):

```bash
@test "labels: empty when no configs" {
  run_cli "$TMP_ROOT/A" labels
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
```

Replace with:

```bash
@test "labels: empty case prints stderr message and exits 0" {
  run_cli "$TMP_ROOT/A" labels
  [ "$status" -eq 0 ]
  [[ "$output" == *"no labels defined yet"* ]]
  [[ "$output" == *'obsidian-context label set'* ]]
}

@test "labels --json: empty case still emits {} and stays silent on stderr" {
  run --separate-stderr "$CLI_BIN" --cwd "$TMP_ROOT/A" --json labels
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
  [ -z "$stderr" ]
}
```

- [ ] **Step 2: Update `tests/files.bats` empty-state test**

In `tests/files.bats`, find this block (lines 8–12):

```bash
@test "list: empty when no configs exist" {
  run_cli "$TMP_ROOT/A" list
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
```

Replace with:

```bash
@test "list: empty case prints stderr message and exits 0" {
  run_cli "$TMP_ROOT/A" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"no entries indexed for this directory yet"* ]]
}
```

- [ ] **Step 3: Add `where` and `list --json` empty-state tests in `tests/output.bats`**

Append at the end of `tests/output.bats`:

```bash
@test "where: empty case prints stderr message and exits 0" {
  run_cli "$TMP_ROOT/A" where
  [ "$status" -eq 0 ]
  [[ "$output" == *"no .obsidian-vault-context.json found at or above"* ]]
  [[ "$output" == *"$TMP_ROOT/A"* ]]
}

@test "list --json: empty case emits valid JSON and stays silent on stderr" {
  run --separate-stderr "$CLI_BIN" --cwd "$TMP_ROOT/A" --json list
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.files == [] and .directories == [] and (.labels // {}) == {}' >/dev/null
  [ -z "$stderr" ]
}
```

- [ ] **Step 4: Run all three test files to confirm failures**

Run: `bats tests/labels.bats tests/files.bats tests/output.bats`

Expected: the three new/updated empty-state tests FAIL (current code outputs nothing). The two `--json` checks may either FAIL (because labels output isn't `{}` exactly — verify what it currently emits) or already PASS. If the JSON check fails, examine current output and adjust the test assertion to match the existing JSON shape; the goal is to lock in that `--json` behavior is unchanged. Other tests still PASS.

- [ ] **Step 5: Commit failing tests**

```bash
git add tests/labels.bats tests/files.bats tests/output.bats
git commit -m "test(obsidian-vault-context): assert empty-state stderr messages on labels/list/where"
```

### Task 3.2: Implement empty-state messages in `bin/obsidian-context`

- [ ] **Step 1: Add empty-state message to the `labels)` branch**

In `bin/obsidian-context`, find the `labels)` branch. Currently after parsing args, it computes `merged` then `filtered`, then chooses JSON vs human output (around lines 222–243). Replace the closing block (the `if [[ "$JSON_OUTPUT" == "1" ]]; then ... fi`) with:

```bash
    if [[ "$JSON_OUTPUT" == "1" ]]; then
      output_labels_json "$filtered"
    else
      if [[ "$(jq -r '.labels | length' <<<"$filtered")" == "0" ]]; then
        printf 'obsidian-context: no labels defined yet (define one with: obsidian-context label set <name> "<description>")\n' >&2
      else
        output_labels_human "$filtered" "$show_source"
      fi
    fi
```

- [ ] **Step 2: Add empty-state message to the `where)` branch**

In `bin/obsidian-context`, find the `where)` branch (around lines 98–103). Replace it with:

```bash
  where)
    any=0
    while IFS= read -r path; do
      schema_validate_file "$path" || exit 1
      printf '%s\n' "$path"
      any=1
    done < <(traversal_collect "$EFFECTIVE_CWD")
    if (( any == 0 )) && [[ "$JSON_OUTPUT" != "1" ]]; then
      printf 'obsidian-context: no .obsidian-vault-context.json found at or above %s, and no global config at ~/.obsidian-vault-context.json\n' "$EFFECTIVE_CWD" >&2
    fi
    ;;
```

- [ ] **Step 3: Add empty-state message to the `list)` branch**

In `bin/obsidian-context`, find the `list)` branch. After the `filtered=$(jq ... <<<"$merged")` block but before the JSON-vs-human output dispatch (around lines 195–199), replace the closing block with:

```bash
    if [[ "$JSON_OUTPUT" == "1" ]]; then
      output_entries_json "$filtered"
    else
      total=$(jq -r '(.files | length) + (.directories | length)' <<<"$filtered")
      if [[ "$total" == "0" ]]; then
        printf 'obsidian-context: no entries indexed for this directory yet\n' >&2
      else
        output_entries_human "$filtered" "$show_source"
      fi
    fi
```

- [ ] **Step 4: Run the affected test files to verify pass**

Run: `bats tests/labels.bats tests/files.bats tests/output.bats`

Expected: all tests PASS, including the new empty-state cases.

- [ ] **Step 5: Run the full test suite for regressions**

Run: `bash tests/run.sh`

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add bin/obsidian-context
git commit -m "feat(obsidian-vault-context): print empty-state messages for labels/list/where"
```

---

## Task 4: Replace `obsidian-cli` with `obsidian` in skills

**Background:** Both `add-file` and `add-directory` skills tell the agent to verify vault paths via `obsidian-cli`, which is not the actual CLI name. The Obsidian.app binary `obsidian` is what's on PATH on macOS systems with Obsidian installed. Verified working subcommands:
- `obsidian file path="<path>"` — exits 0 if file exists, non-zero with `Error: File "<path>" not found.` otherwise.
- `obsidian folder path="<path>"` — same contract for folders.
- `obsidian search query="<text>"` — for finding candidates.

**Files:**
- Modify: `skills/add-file/SKILL.md`
- Modify: `skills/add-directory/SKILL.md`

No tests — these are documentation-only Markdown changes.

### Task 4.1: Update `skills/add-file/SKILL.md` step 2

- [ ] **Step 1: Replace the verification step in `skills/add-file/SKILL.md`**

Open `skills/add-file/SKILL.md`. Find the section `### 2. Verify the file exists in the vault` (currently lines 25–35). Replace the entire section (from the heading down to and including the line about confirming explicitly before proceeding) with:

```markdown
### 2. Verify the file exists in the vault

**Do not register a path that doesn't exist.** Use the `obsidian` CLI (ships
with Obsidian.app, on PATH automatically when the app is installed):

```bash
obsidian file path="<vault-path>"
```

Exit 0 means the file exists in the active vault. Non-zero with stderr
`Error: File "<vault-path>" not found.` means it doesn't.

If the file is found, proceed.

If the file is NOT found:
- Search for similar names: `obsidian search query="<basename without extension>"`.
- Present the closest matches to the user as candidates ("I didn't find `<original path>`. Did you mean `<candidate-1>`, `<candidate-2>`, or `<candidate-3>`?").
- Wait for the user to pick one or correct the path. **Never silently substitute a different path** — confirm first.
- If the user wants to register a path that genuinely doesn't exist yet (e.g. they plan to create the note shortly), let them confirm explicitly before proceeding.

If `obsidian` is not on PATH (Obsidian.app not installed, or non-macOS), skip
verification and ask the user to confirm the path is correct before adding.
Do not silently register an unverified entry.
```

- [ ] **Step 2: Verify Markdown renders cleanly**

Run a quick visual scan: open the file and confirm the section heading, command fences, and bullets are intact.

```bash
sed -n '25,55p' skills/add-file/SKILL.md
```

Expected: a clean section starting at `### 2. Verify the file exists in the vault` with the new content and ending before `### 3.`.

- [ ] **Step 3: Commit**

```bash
git add skills/add-file/SKILL.md
git commit -m "docs(obsidian-vault-context): use obsidian CLI for file path verification in add-file skill"
```

### Task 4.2: Update `skills/add-directory/SKILL.md` step 2

- [ ] **Step 1: Replace the verification step in `skills/add-directory/SKILL.md`**

Open `skills/add-directory/SKILL.md`. Find the section `### 2. Verify the directory exists in the vault` (currently lines 24–34). Replace the entire section with:

```markdown
### 2. Verify the directory exists in the vault

**Do not register a directory that doesn't exist.** Use the `obsidian` CLI
(ships with Obsidian.app, on PATH automatically when the app is installed):

```bash
obsidian folder path="<vault-path>"
```

Exit 0 means the folder exists in the active vault. Non-zero with stderr
`Error: Folder "<vault-path>" not found.` means it doesn't.

If the directory is found, proceed.

If the directory is NOT found:
- Search for similar names: `obsidian search query="<basename of vault-path>"`.
- Present the closest matches to the user ("I didn't find `<original path>/`. Did you mean `<candidate-1>/`, `<candidate-2>/`, or `<candidate-3>/`?").
- Wait for the user to pick one or correct the path. **Never silently substitute a different path** — confirm first.
- If the user wants to register a directory they plan to create shortly, let them confirm explicitly before proceeding.

If `obsidian` is not on PATH (Obsidian.app not installed, or non-macOS), skip
verification and ask the user to confirm the path is correct before adding.
Do not silently register an unverified entry.
```

- [ ] **Step 2: Verify Markdown renders cleanly**

Run:

```bash
sed -n '24,55p' skills/add-directory/SKILL.md
```

Expected: the new section content with proper formatting; subsequent sections (`### 3. Check existing labels`, etc.) follow.

- [ ] **Step 3: Commit**

```bash
git add skills/add-directory/SKILL.md
git commit -m "docs(obsidian-vault-context): use obsidian CLI for folder path verification in add-directory skill"
```

---

## Task 5: README updates — permission prompts and first-run flow

**Background:** Each `obsidian-context` invocation triggers a Claude Code permission prompt unless the user has `Bash(obsidian-context:*)` on their allowlist. The README doesn't document this. Also, the first-run UX (no config exists yet) needs a one-paragraph explanation.

**Files:**
- Modify: `README.md` (insert two new sections under or near Installation)

### Task 5.1: Add "Reducing permission prompts" section

- [ ] **Step 1: Insert the section in `README.md`**

Open `README.md`. Find the existing `## Installation` section (lines 18–26). Just AFTER the closing of that section (after the line `The CLI obsidian-context is automatically available on PATH while the plugin is enabled.`) and BEFORE the `## Config file schema` heading (line 28), insert:

````markdown
## Reducing permission prompts

Each `obsidian-context` invocation triggers a Claude Code permission prompt
unless the binary is on your allowlist. Add the following to either
`~/.claude/settings.json` (global) or `.claude/settings.json` (project):

```json
{
  "permissions": {
    "allow": ["Bash(obsidian-context:*)"]
  }
}
```

## First run

If the CLI errors with `no existing .obsidian-vault-context.json found at or
above <cwd>`, you have no index here yet. Use `--scope current-directory` to
create one in `$PWD`, or `--scope global` to write to
`~/.obsidian-vault-context.json`.

````

- [ ] **Step 2: Verify ordering and formatting**

Run:

```bash
sed -n '18,55p' README.md
```

Expected: `## Installation`, then `## Reducing permission prompts`, then `## First run`, then `## Config file schema`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(obsidian-vault-context): document permission allowlist and first-run flow"
```

---

## Task 6: Version bump to 1.3.0

**Background:** The plugin version and the marketplace entry must move together. Per the project's CLAUDE.md, this is a minor bump (new CLI behavior, skill behavior change, no breaking changes).

**Files:**
- Modify: `.claude-plugin/plugin.json` (plugin root)
- Modify: `../.claude-plugin/marketplace.json` (repo root)

### Task 6.1: Bump plugin.json

- [ ] **Step 1: Update `.claude-plugin/plugin.json`**

Open `.claude-plugin/plugin.json`. Change the `"version"` field from `"1.2.0"` to `"1.3.0"`.

After change:

```json
{
  "name": "obsidian-vault-context",
  "version": "1.3.0",
  ...
}
```

### Task 6.2: Bump the marketplace entry

- [ ] **Step 1: Update the marketplace.json plugin entry**

Open `/Users/charles/Workspace/perso/claude/selrahcd-marketplace/.claude-plugin/marketplace.json`. Find the `obsidian-vault-context` entry under `plugins` (around lines 29–34). Change its `"version"` field from `"1.2.0"` to `"1.3.0"`.

After change:

```json
    {
      "name": "obsidian-vault-context",
      "source": "./selrahcd-obsidian-vault-context",
      "description": "Directory-aware index of Obsidian vault notes and directories, queryable via the obsidian-context CLI",
      "version": "1.3.0"
    }
```

### Task 6.3: Final verification + commit

- [ ] **Step 1: Run the full test suite one final time**

Run (from `selrahcd-obsidian-vault-context/`): `bash tests/run.sh`

Expected: all tests PASS.

- [ ] **Step 2: Sanity-check `obsidian-context --help`**

Run from any directory:

```bash
bin/obsidian-context add directory --help
bin/obsidian-context add --help
bin/obsidian-context add file --description "X" --scope directory
bin/obsidian-context labels --cwd /tmp/empty-test-dir-$$
```

Expected:
- `add directory --help` prints directory-specific usage with `--description`, `--label`, `--scope`, `--force`.
- `add --help` prints both file and directory usage.
- `add file ... --scope directory` exits non-zero with the typo-aware error.
- `labels` against an empty dir prints `obsidian-context: no labels defined yet ...` to stderr.

- [ ] **Step 3: Commit version bump**

```bash
git add .claude-plugin/plugin.json
git -C .. add .claude-plugin/marketplace.json
git commit -m "chore(obsidian-vault-context): bump to 1.3.0 for CLI & skill UX improvements"
```

(Note: the second `git add` uses `-C ..` because `marketplace.json` lives one directory up from the plugin. Both files end up in the same commit.)

- [ ] **Step 4: Verify git log**

Run: `git log --oneline -10`

Expected: a clean sequence of feature/test/docs/chore commits leading up to the version bump, all on `main`.

---

## Self-Review

Spec coverage check (cross-referencing `docs/superpowers/specs/2026-05-03-obsidian-vault-context-cli-ux-design.md`):

- Spec section 1 "Subcommand `--help`" → Task 1 ✓
- Spec section 2 "Better `--scope` error" → Task 2 ✓
- Spec section 3 "Empty-state messages" → Task 3 ✓
- Spec section 4 "Skill verification via `obsidian`" → Task 4 ✓
- Spec section 5 "First-run UX" → Task 5 ("First run" README subsection) ✓
- Spec section 6 "Permission-prompt setup" → Task 5 ("Reducing permission prompts") ✓
- Spec "Testing" — `tests/help.bats` (Task 1.1), extended `tests/scopes.bats` (Task 2.1), extended `tests/labels.bats` (Task 3.1), extended `tests/output.bats` (Task 3.1), updated `tests/files.bats` (Task 3.1) ✓
- Spec "Files changed" — all listed files have a corresponding modify or create step ✓
- Spec "Out of scope" — `lib/merge.sh`, `lib/traversal.sh`, `lib/write.sh`, `lib/schema.sh`, `lib/output.sh`, `read-context`/`labels` skills are not touched ✓ (no task references them)

Type/identifier consistency check:
- `print_add_help` / `print_remove_help` / `print_label_help` / `help_scan` introduced in Task 1.2 step 1, used in Task 1.2 steps 2–4 ✓
- `HELP_FOUND` / `HELP_CTX` set by `help_scan`, read in the early-detect blocks ✓
- Function signature of `help_scan` matches usage: `help_scan "$@" -- file directory` (or `-- set remove`) ✓
- Variable names in Task 3.2 (`any`, `total`, `filtered`) don't collide with existing names in `bin/obsidian-context` (`merged`, `kind`, `labels`, `search`, `show_source` exist but are scoped to their own subcommand branches) ✓

No placeholders found. No "TBD", no "Add appropriate ...", every code step contains the actual code, every test has explicit assertions and expected output.
