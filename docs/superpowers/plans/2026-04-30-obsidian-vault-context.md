# Obsidian Vault Context Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a new `obsidian-vault-context` plugin that exposes a directory-aware config (`.obsidian-vault-context.json`) plus a bash CLI (`obsidian-context`) for reading and curating per-directory vault references; ship four skills wrapping the CLI; cover the CLI with bats tests; add CI.

**Architecture:** New plugin `selrahcd-obsidian-vault-context/` at the marketplace root. CLI is a single bash dispatcher (`bin/obsidian-context`) that sources pure-bash libs from `lib/`. All read/write goes through `jq`. Tests use bats with tmpdir-based fixtures, controlling `HOME` and passing `--cwd`. The existing `obsidian-bridge` plugin is **not touched**.

**Tech Stack:** bash (≥4 — uses associative arrays), `jq`, bats. Plugin layout follows Claude Code's standard (`bin/` is auto-PATH'd).

**Reference spec:** `docs/superpowers/specs/2026-04-30-obsidian-vault-context-design.md`

---

## File Structure

| File | Action | Responsibility |
| --- | --- | --- |
| `selrahcd-obsidian-vault-context/.claude-plugin/plugin.json` | Create | Plugin manifest (`name=obsidian-vault-context`, `version=1.0.0`) |
| `selrahcd-obsidian-vault-context/bin/obsidian-context` | Create | CLI dispatcher; subcommand parsing; sources libs |
| `selrahcd-obsidian-vault-context/lib/traversal.sh` | Create | Walk CWD up to `/`, append global; pure functions |
| `selrahcd-obsidian-vault-context/lib/schema.sh` | Create | jq filters validating top-level keys + entry shape |
| `selrahcd-obsidian-vault-context/lib/merge.sh` | Create | Concat lists with source attribution; closest-wins for labels |
| `selrahcd-obsidian-vault-context/lib/scope.sh` | Create | Resolve `--scope` keyword/path → file path |
| `selrahcd-obsidian-vault-context/lib/write.sh` | Create | Atomic read-modify-write with mtime check |
| `selrahcd-obsidian-vault-context/lib/output.sh` | Create | Human and `--json` formatters |
| `selrahcd-obsidian-vault-context/skills/read-context/SKILL.md` | Create | Auto-invoked skill: surface vault entries on relevant intent |
| `selrahcd-obsidian-vault-context/skills/add-file/SKILL.md` | Create | Guided skill: add a file entry |
| `selrahcd-obsidian-vault-context/skills/add-directory/SKILL.md` | Create | Guided skill: add a directory entry |
| `selrahcd-obsidian-vault-context/skills/labels/SKILL.md` | Create | Manage label vocabulary |
| `selrahcd-obsidian-vault-context/tests/helpers.bash` | Create | Shared bats helpers (tmpdir, tree builder, CLI invoker) |
| `selrahcd-obsidian-vault-context/tests/run.sh` | Create | `bats tests/` runner |
| `selrahcd-obsidian-vault-context/tests/traversal.bats` | Create | Walk-up correctness, global merge, source attribution |
| `selrahcd-obsidian-vault-context/tests/files.bats` | Create | Files: list, add, remove, errors |
| `selrahcd-obsidian-vault-context/tests/directories.bats` | Create | Directories: list, add, remove, errors |
| `selrahcd-obsidian-vault-context/tests/labels.bats` | Create | Labels: list, set, remove, closest-wins, errors |
| `selrahcd-obsidian-vault-context/tests/scopes.bats` | Create | Scope resolution: local/current-directory/global/<path>, errors |
| `selrahcd-obsidian-vault-context/tests/output.bats` | Create | Human + `--json` shape |
| `selrahcd-obsidian-vault-context/README.md` | Create | Plugin docs (overview, schema, CLI, skills, label examples) |
| `.claude-plugin/marketplace.json` | Modify | Add new plugin entry, version 1.0.0 |
| `.github/workflows/test-vault-context.yml` | Create | Run bats on push/PR for plugin changes |

The CLI is intentionally split into small libs: each lib has one responsibility, and each can be sourced and tested independently. The dispatcher is the only thing on PATH.

---

## Task 1: Plugin scaffolding

**Files:**
- Create: `selrahcd-obsidian-vault-context/.claude-plugin/plugin.json`
- Create: `selrahcd-obsidian-vault-context/bin/obsidian-context`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create the plugin manifest**

Create `selrahcd-obsidian-vault-context/.claude-plugin/plugin.json`:

```json
{
  "name": "obsidian-vault-context",
  "version": "1.0.0",
  "description": "Directory-aware index of Obsidian vault notes and directories, queryable via the obsidian-context CLI",
  "author": {
    "name": "Selrahcd",
    "url": "https://github.com/SelrahcD"
  },
  "repository": "https://github.com/SelrahcD/claude-marketplace",
  "license": "MIT",
  "keywords": ["obsidian", "vault", "context", "cli"],
  "skills": "./skills/"
}
```

- [ ] **Step 2: Create a stub CLI that prints help**

Create `selrahcd-obsidian-vault-context/bin/obsidian-context` and `chmod +x` it:

```bash
#!/usr/bin/env bash
set -euo pipefail

print_help() {
  cat <<'EOF'
obsidian-context — directory-aware index of Obsidian vault notes

Usage: obsidian-context [global flags] <subcommand> [args]

Read subcommands:
  list      List file/directory entries (filterable)
  labels    List known labels with descriptions
  where     Show which config files were loaded

Write subcommands:
  add file <path>          Add a file entry
  add directory <path>     Add a directory entry
  remove file <path>       Remove a file entry
  remove directory <path>  Remove a directory entry
  label set <name> <desc>  Define or refine a label
  label remove <name>      Remove a label

Global flags:
  --json          Structured output instead of human format
  --cwd <path>    Pretend CLI was invoked from <path>
  --help          Print this help

Run 'obsidian-context <subcommand> --help' for subcommand details.
EOF
}

if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
  print_help
  exit 0
fi

echo "obsidian-context: subcommand '$1' not implemented yet" >&2
exit 2
```

- [ ] **Step 3: Make it executable**

Run: `chmod +x selrahcd-obsidian-vault-context/bin/obsidian-context`

- [ ] **Step 4: Add the plugin to the marketplace**

Modify `.claude-plugin/marketplace.json` to add a new plugin entry inside the `plugins` array (after the existing entries):

```json
{
  "name": "obsidian-vault-context",
  "source": "./selrahcd-obsidian-vault-context",
  "description": "Directory-aware index of Obsidian vault notes and directories, queryable via the obsidian-context CLI",
  "version": "1.0.0"
}
```

- [ ] **Step 5: Smoke test the binary**

Run: `selrahcd-obsidian-vault-context/bin/obsidian-context --help`
Expected: prints the usage block, exit 0.

Run: `selrahcd-obsidian-vault-context/bin/obsidian-context foo`
Expected: stderr `obsidian-context: subcommand 'foo' not implemented yet`, exit 2.

- [ ] **Step 6: Commit**

```bash
git add selrahcd-obsidian-vault-context/.claude-plugin/plugin.json \
        selrahcd-obsidian-vault-context/bin/obsidian-context \
        .claude-plugin/marketplace.json
git commit -m "feat(obsidian-vault-context): scaffold plugin and CLI dispatcher stub"
```

---

## Task 2: Bats fixture infrastructure

**Files:**
- Create: `selrahcd-obsidian-vault-context/tests/helpers.bash`
- Create: `selrahcd-obsidian-vault-context/tests/run.sh`
- Create: `selrahcd-obsidian-vault-context/tests/traversal.bats` (with one smoke test)

- [ ] **Step 1: Write the helpers**

Create `selrahcd-obsidian-vault-context/tests/helpers.bash`:

```bash
# Helpers for bats tests of obsidian-context.

# Resolve once: absolute path to the CLI under test.
CLI_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/obsidian-context"

# setup_tmp_root creates an isolated tmpdir for a test, with a fake $HOME inside.
# Sets globals: TMP_ROOT, FAKE_HOME.
setup_tmp_root() {
  TMP_ROOT="$(mktemp -d)"
  FAKE_HOME="$TMP_ROOT/home"
  mkdir -p "$FAKE_HOME"
  export HOME="$FAKE_HOME"
}

teardown_tmp_root() {
  if [[ -n "${TMP_ROOT:-}" && -d "$TMP_ROOT" ]]; then
    rm -rf "$TMP_ROOT"
  fi
}

# write_config <abs-dir> <json-content>
# Creates the directory and writes .obsidian-vault-context.json into it.
write_config() {
  local dir="$1"
  local content="$2"
  mkdir -p "$dir"
  printf '%s\n' "$content" > "$dir/.obsidian-vault-context.json"
}

# write_global_config <json-content>
# Writes ~/.obsidian-vault-context.json (using the fake $HOME).
write_global_config() {
  local content="$1"
  printf '%s\n' "$content" > "$HOME/.obsidian-vault-context.json"
}

# run_cli <cwd> [args...]
# Invokes the CLI with --cwd <cwd>, appending args.
# Captures stdout in $output, exit code in $status (bats convention via `run`).
run_cli() {
  local cwd="$1"
  shift
  run "$CLI_BIN" --cwd "$cwd" "$@"
}
```

- [ ] **Step 2: Write the runner**

Create `selrahcd-obsidian-vault-context/tests/run.sh` and `chmod +x`:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
exec bats .
```

Run: `chmod +x selrahcd-obsidian-vault-context/tests/run.sh`

- [ ] **Step 3: Write a smoke test**

Create `selrahcd-obsidian-vault-context/tests/traversal.bats` with one passing test that verifies the CLI is reachable:

```bash
#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "CLI prints help when run with no args" {
  run "$CLI_BIN" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"obsidian-context"* ]]
  [[ "$output" == *"Usage:"* ]]
}
```

- [ ] **Step 4: Run the smoke test**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 1 test, all passing.

If `bats` is not installed: `brew install bats-core` (macOS) or follow https://github.com/bats-core/bats-core for Linux.

- [ ] **Step 5: Commit**

```bash
git add selrahcd-obsidian-vault-context/tests/
git commit -m "test(obsidian-vault-context): add bats helpers, runner, smoke test"
```

---

## Task 3: Traversal lib + `where` subcommand

**Files:**
- Create: `selrahcd-obsidian-vault-context/lib/traversal.sh`
- Modify: `selrahcd-obsidian-vault-context/bin/obsidian-context`
- Modify: `selrahcd-obsidian-vault-context/tests/traversal.bats`

- [ ] **Step 1: Write failing tests for `where`**

Append to `selrahcd-obsidian-vault-context/tests/traversal.bats`:

```bash
@test "where: lists CWD-only config when only CWD has one" {
  write_config "$TMP_ROOT/A/B/C" '{}'
  run_cli "$TMP_ROOT/A/B/C" where
  [ "$status" -eq 0 ]
  [[ "$output" == *"$TMP_ROOT/A/B/C/.obsidian-vault-context.json"* ]]
}

@test "where: lists configs walking up from CWD to /, closest first" {
  write_config "$TMP_ROOT/A" '{}'
  write_config "$TMP_ROOT/A/B/C" '{}'
  run_cli "$TMP_ROOT/A/B/C" where

  [ "$status" -eq 0 ]
  # Closest first: C, then A
  c_line=$(echo "$output" | grep -n "A/B/C/.obsidian-vault-context.json" | cut -d: -f1)
  a_line=$(echo "$output" | grep -n "A/.obsidian-vault-context.json" | cut -d: -f1)
  [ -n "$c_line" ]
  [ -n "$a_line" ]
  [ "$c_line" -lt "$a_line" ]
}

@test "where: appends global config when present" {
  write_global_config '{}'
  write_config "$TMP_ROOT/A" '{}'
  run_cli "$TMP_ROOT/A" where
  [ "$status" -eq 0 ]
  [[ "$output" == *"$HOME/.obsidian-vault-context.json"* ]]
  # Global is last
  global_line=$(echo "$output" | grep -n "$HOME/.obsidian-vault-context.json" | cut -d: -f1)
  local_line=$(echo "$output" | grep -n "A/.obsidian-vault-context.json" | cut -d: -f1)
  [ "$local_line" -lt "$global_line" ]
}

@test "where: prints nothing and exits 0 when no configs exist anywhere" {
  run_cli "$TMP_ROOT/A/B/C" where
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 4 new tests fail (CLI says `where' not implemented yet`).

- [ ] **Step 3: Write the traversal library**

Create `selrahcd-obsidian-vault-context/lib/traversal.sh`:

```bash
# Traversal: find all .obsidian-vault-context.json files closest-first.
#
# Functions:
#   traversal_collect <cwd> -> prints absolute paths, one per line, closest-first.
#                              Walks <cwd> up to /, then appends $HOME/.obsidian-vault-context.json
#                              if it exists.

traversal_collect() {
  local cwd="$1"
  local dir
  dir="$(cd "$cwd" 2>/dev/null && pwd -P)" || {
    printf 'obsidian-context: --cwd: directory does not exist: %s\n' "$cwd" >&2
    return 1
  }

  while :; do
    local candidate="$dir/.obsidian-vault-context.json"
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
    fi
    if [[ "$dir" == "/" ]]; then
      break
    fi
    dir="$(dirname "$dir")"
  done

  local global="$HOME/.obsidian-vault-context.json"
  if [[ -f "$global" ]]; then
    printf '%s\n' "$global"
  fi
}
```

- [ ] **Step 4: Wire `where` into the dispatcher**

Replace the contents of `selrahcd-obsidian-vault-context/bin/obsidian-context` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Resolve the script's own directory so we can source siblings.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/traversal.sh"

print_help() {
  cat <<'EOF'
obsidian-context — directory-aware index of Obsidian vault notes

Usage: obsidian-context [global flags] <subcommand> [args]

Read subcommands:
  list      List file/directory entries (filterable)
  labels    List known labels with descriptions
  where     Show which config files were loaded

Write subcommands:
  add file <path>          Add a file entry
  add directory <path>     Add a directory entry
  remove file <path>       Remove a file entry
  remove directory <path>  Remove a directory entry
  label set <name> <desc>  Define or refine a label
  label remove <name>      Remove a label

Global flags:
  --json          Structured output instead of human format
  --cwd <path>    Pretend CLI was invoked from <path>
  --help          Print this help
EOF
}

# Parse global flags. Sets EFFECTIVE_CWD, JSON_OUTPUT, leaves remaining args in REST.
EFFECTIVE_CWD="$PWD"
JSON_OUTPUT=0
REST=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd) EFFECTIVE_CWD="$2"; shift 2 ;;
    --json) JSON_OUTPUT=1; shift ;;
    --help|-h) print_help; exit 0 ;;
    --) shift; REST+=("$@"); break ;;
    *) REST+=("$1"); shift ;;
  esac
done

set -- "${REST[@]:-}"

if [[ $# -eq 0 ]]; then
  print_help
  exit 0
fi

cmd="$1"; shift
case "$cmd" in
  where)
    traversal_collect "$EFFECTIVE_CWD"
    ;;
  *)
    printf 'obsidian-context: subcommand %q not implemented yet\n' "$cmd" >&2
    exit 2
    ;;
esac
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all 5 tests pass.

- [ ] **Step 6: Commit**

```bash
git add selrahcd-obsidian-vault-context/lib/traversal.sh \
        selrahcd-obsidian-vault-context/bin/obsidian-context \
        selrahcd-obsidian-vault-context/tests/traversal.bats
git commit -m "feat(obsidian-vault-context): implement traversal + where subcommand"
```

---

## Task 4: Schema validation lib

**Files:**
- Create: `selrahcd-obsidian-vault-context/lib/schema.sh`
- Modify: `selrahcd-obsidian-vault-context/tests/traversal.bats`

The schema lib provides one-shot validation: given a config file path, exit 0 if the JSON parses and matches the expected shape; print a clear error and exit non-zero otherwise.

- [ ] **Step 1: Write failing tests**

Append to `selrahcd-obsidian-vault-context/tests/traversal.bats`:

```bash
@test "where: malformed JSON in a traversed file is a hard error" {
  write_config "$TMP_ROOT/A" 'not json {'
  run_cli "$TMP_ROOT/A" where
  [ "$status" -ne 0 ]
  [[ "$output" == *"A/.obsidian-vault-context.json"* ]]
  [[ "$output" == *"malformed JSON"* ]] || [[ "$stderr" == *"malformed JSON"* ]]
}

@test "where: unknown top-level key emits a soft warning to stderr" {
  write_config "$TMP_ROOT/A" '{"obsidian-bridge": {"project": "X"}}'
  run_cli "$TMP_ROOT/A" where
  [ "$status" -eq 0 ]
  [[ "$output" == *"A/.obsidian-vault-context.json"* ]]
  # Stderr captured into $output by bats `run` only with --separate-stderr,
  # so we just verify the soft path: exit 0 and the path is listed.
}

@test "where: malformed entry (missing path) is a hard error" {
  write_config "$TMP_ROOT/A" '{"files": [{"description": "x"}]}'
  run_cli "$TMP_ROOT/A" where
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing required field"* ]] || [[ "$output" == *"path"* ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 3 new failures (no validation in `where`).

- [ ] **Step 3: Write the schema library**

Create `selrahcd-obsidian-vault-context/lib/schema.sh`:

```bash
# Schema validation for .obsidian-vault-context.json files.
#
# Functions:
#   schema_validate_file <abs-path>
#     Exit 0 on valid; exit 1 + stderr message on malformed JSON or malformed entries.
#     Emits soft warnings to stderr for unknown top-level keys.

# Recognized top-level keys owned by this plugin.
SCHEMA_KNOWN_TOP_LEVEL=(files directories labels)

schema_validate_file() {
  local file="$1"

  # First: is it valid JSON at all?
  if ! jq empty "$file" 2>/dev/null; then
    printf 'obsidian-context: malformed JSON in %s\n' "$file" >&2
    return 1
  fi

  # Soft warn for unknown top-level keys.
  local known_array known_filter
  known_filter='["files","directories","labels"]'
  local unknown
  unknown=$(jq -r --argjson known "$known_filter" \
    '(keys // []) - $known | .[]' "$file")
  if [[ -n "$unknown" ]]; then
    while IFS= read -r key; do
      printf 'obsidian-context: warning: unknown top-level key %q in %s\n' "$key" "$file" >&2
    done <<<"$unknown"
  fi

  # Validate files[] and directories[] entry shapes.
  local kind
  for kind in files directories; do
    local missing_path
    missing_path=$(jq -r --arg k "$kind" \
      '.[$k] // [] | map(select(.path == null or .path == "")) | length' "$file")
    if [[ "$missing_path" -gt 0 ]]; then
      printf 'obsidian-context: %s: an entry in %s is missing required field "path"\n' "$file" "$kind" >&2
      return 1
    fi

    local missing_desc
    missing_desc=$(jq -r --arg k "$kind" \
      '.[$k] // [] | map(select(.description == null or .description == "")) | length' "$file")
    if [[ "$missing_desc" -gt 0 ]]; then
      printf 'obsidian-context: %s: an entry in %s is missing required field "description"\n' "$file" "$kind" >&2
      return 1
    fi

    local bad_labels
    bad_labels=$(jq -r --arg k "$kind" \
      '.[$k] // [] | map(select(.labels != null and (.labels | type) != "array")) | length' "$file")
    if [[ "$bad_labels" -gt 0 ]]; then
      printf 'obsidian-context: %s: an entry in %s has non-array "labels"\n' "$file" "$kind" >&2
      return 1
    fi
  done

  # Validate labels{} is an object of name->string when present.
  if jq -e '.labels // empty | type != "object"' "$file" >/dev/null 2>&1; then
    printf 'obsidian-context: %s: top-level "labels" must be an object\n' "$file" >&2
    return 1
  fi

  return 0
}
```

- [ ] **Step 4: Wire validation into the dispatcher**

Edit `selrahcd-obsidian-vault-context/bin/obsidian-context`. Just below the `source "$LIB_DIR/traversal.sh"` line, add:

```bash
source "$LIB_DIR/schema.sh"
```

Then change the `where` case to validate every collected file:

```bash
  where)
    while IFS= read -r path; do
      schema_validate_file "$path" || exit 1
      printf '%s\n' "$path"
    done < <(traversal_collect "$EFFECTIVE_CWD")
    ;;
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add selrahcd-obsidian-vault-context/lib/schema.sh \
        selrahcd-obsidian-vault-context/bin/obsidian-context \
        selrahcd-obsidian-vault-context/tests/traversal.bats
git commit -m "feat(obsidian-vault-context): validate config schema on read"
```

---

## Task 5: Merge lib for files and directories (with source attribution)

**Files:**
- Create: `selrahcd-obsidian-vault-context/lib/merge.sh`

The merge lib reads a list of config file paths (closest-first) and emits a single JSON document with merged `files[]` and `directories[]` arrays where each entry carries an injected `source` field.

- [ ] **Step 1: Write the merge library (no separate test file yet — covered by `list` tests in Task 6)**

Create `selrahcd-obsidian-vault-context/lib/merge.sh`:

```bash
# Merge: collect entries from multiple config files, inject source attribution.
#
# Functions:
#   merge_collections <file1> [file2 ...]
#     Reads each file (assumed already schema-validated), emits a single JSON
#     object: { "files": [...], "directories": [...], "labels": {...} }.
#     Each entry in files[] and directories[] gets a "source" field set to the
#     absolute path of the config it came from.
#     Concatenation is in argument order (callers pass closest-first).
#     For labels, closest-wins (first definition seen wins).

merge_collections() {
  local files=("$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    printf '{"files":[],"directories":[],"labels":{}}\n'
    return 0
  fi

  # jq slurps each file's content with its source path attached.
  # We use --slurpfile per file to preserve filename association via a parallel array.
  local jq_args=()
  local i=0
  for f in "${files[@]}"; do
    jq_args+=(--arg "src$i" "$f")
    jq_args+=(--slurpfile "data$i" "$f")
    i=$((i + 1))
  done

  # Build a jq program that processes each file in order.
  local jq_program='
    def attach_source($src):
      map(. + {"source": $src});

    # Start with empty.
    {files: [], directories: [], labels: {}}
  '

  i=0
  for f in "${files[@]}"; do
    jq_program+="
    | (.files += ((\$data$i[0].files // []) | attach_source(\$src$i)))
    | (.directories += ((\$data$i[0].directories // []) | attach_source(\$src$i)))
    | (.labels = (((\$data$i[0].labels // {}) | with_entries(.value = {description: .value, source: \$src$i})) + .labels))
    "
    i=$((i + 1))
  done

  jq -n "${jq_args[@]}" "$jq_program"
}
```

> **Why closest-first works for labels:** the jq program seeds `.labels` empty, then for each file (closest first) does `(file_labels) + .labels`. The right-hand side of `+` wins on key collision in jq, so once a label exists in `.labels`, later (further-up) files don't overwrite it.

- [ ] **Step 2: Quick manual sanity check**

Run:

```bash
TMP=$(mktemp -d)
echo '{"files":[{"path":"a.md","description":"A","labels":["x"]}], "labels":{"x":"close x"}}' > "$TMP/closest.json"
echo '{"files":[{"path":"b.md","description":"B"}], "labels":{"x":"far x","y":"y desc"}}' > "$TMP/far.json"
( source selrahcd-obsidian-vault-context/lib/merge.sh
  merge_collections "$TMP/closest.json" "$TMP/far.json" ) | jq .
rm -rf "$TMP"
```

Expected output:

```json
{
  "files": [
    {"path": "a.md", "description": "A", "labels": ["x"], "source": "/tmp/.../closest.json"},
    {"path": "b.md", "description": "B", "source": "/tmp/.../far.json"}
  ],
  "directories": [],
  "labels": {
    "x": {"description": "close x", "source": "/tmp/.../closest.json"},
    "y": {"description": "y desc", "source": "/tmp/.../far.json"}
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add selrahcd-obsidian-vault-context/lib/merge.sh
git commit -m "feat(obsidian-vault-context): add merge lib (concat + closest-wins labels)"
```

---

## Task 6: Output lib + `list` subcommand (basic, no filters)

**Files:**
- Create: `selrahcd-obsidian-vault-context/lib/output.sh`
- Create: `selrahcd-obsidian-vault-context/tests/files.bats`
- Create: `selrahcd-obsidian-vault-context/tests/directories.bats`
- Modify: `selrahcd-obsidian-vault-context/bin/obsidian-context`

- [ ] **Step 1: Write failing tests for `list`**

Create `selrahcd-obsidian-vault-context/tests/files.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "list: empty when no configs exist" {
  run_cli "$TMP_ROOT/A" list
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "list: shows file entries from CWD config" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "Notes/X.md", "description": "X note", "labels": ["foo"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Notes/X.md"* ]]
  [[ "$output" == *"X note"* ]]
  [[ "$output" == *"foo"* ]]
  [[ "$output" == *"from:"*"A/.obsidian-vault-context.json"* ]]
}

@test "list: merges closest-first across levels with source attribution" {
  write_config "$TMP_ROOT/A" '{
    "files": [{"path": "far.md", "description": "Far", "labels": []}]
  }'
  write_config "$TMP_ROOT/A/B" '{
    "files": [{"path": "close.md", "description": "Close", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A/B" list

  [ "$status" -eq 0 ]
  close_line=$(echo "$output" | grep -n "close.md" | head -1 | cut -d: -f1)
  far_line=$(echo "$output" | grep -n "far.md" | head -1 | cut -d: -f1)
  [ -n "$close_line" ]
  [ -n "$far_line" ]
  [ "$close_line" -lt "$far_line" ]
}
```

Create `selrahcd-obsidian-vault-context/tests/directories.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "list: shows directory entries" {
  write_config "$TMP_ROOT/A" '{
    "directories": [
      {"path": "Projects/", "description": "All projects", "labels": ["root"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Projects/"* ]]
  [[ "$output" == *"All projects"* ]]
  [[ "$output" == *"root"* ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 4 failures (CLI says `list` not implemented).

- [ ] **Step 3: Write the output library**

Create `selrahcd-obsidian-vault-context/lib/output.sh`:

```bash
# Output formatters for entries and labels.
#
# Functions:
#   output_entries_human <merged-json>
#     Reads the merged JSON on stdin (or as arg), prints one line per entry:
#       <path>  [<labels>]  <description>
#       from: <source>
#     Both files and directories are printed; if you only want one kind, filter beforehand.
#
#   output_entries_json <merged-json>
#     Re-emits the merged JSON's files+directories with source preserved.

output_entries_human() {
  local merged="$1"
  jq -r '
    ((.files // []) + (.directories // []))
    | .[]
    | "\(.path)  [\((.labels // []) | join(", "))]  \(.description)\n  from: \(.source)"
  ' <<<"$merged"
}

output_entries_json() {
  local merged="$1"
  jq '{files: (.files // []), directories: (.directories // [])}' <<<"$merged"
}

# Labels formatters.
output_labels_human() {
  local merged="$1"
  local show_source="$2"  # 0 or 1
  if [[ "$show_source" == "1" ]]; then
    jq -r '
      .labels // {}
      | to_entries
      | .[]
      | "\(.key): \(.value.description)\n  from: \(.value.source)"
    ' <<<"$merged"
  else
    jq -r '
      .labels // {}
      | to_entries
      | .[]
      | "\(.key): \(.value.description)"
    ' <<<"$merged"
  fi
}

output_labels_json() {
  local merged="$1"
  jq '.labels // {}' <<<"$merged"
}
```

- [ ] **Step 4: Wire `list` into the dispatcher**

Edit `selrahcd-obsidian-vault-context/bin/obsidian-context`. Add the new lib sources after `schema.sh`:

```bash
source "$LIB_DIR/merge.sh"
source "$LIB_DIR/output.sh"
```

Add a helper function that builds the merged JSON for the current CWD (validates each file along the way):

```bash
build_merged() {
  local cwd="$1"
  local files=()
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    schema_validate_file "$path" || exit 1
    files+=("$path")
  done < <(traversal_collect "$cwd")

  if [[ ${#files[@]} -eq 0 ]]; then
    printf '{"files":[],"directories":[],"labels":{}}\n'
  else
    merge_collections "${files[@]}"
  fi
}
```

Add a `list` case to the dispatcher (replace the `*)` fallthrough placement so `list` is matched first):

```bash
  list)
    merged=$(build_merged "$EFFECTIVE_CWD")
    if [[ "$JSON_OUTPUT" == "1" ]]; then
      output_entries_json "$merged"
    else
      output_entries_human "$merged"
    fi
    ;;
```

- [ ] **Step 5: Run tests**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add selrahcd-obsidian-vault-context/lib/output.sh \
        selrahcd-obsidian-vault-context/bin/obsidian-context \
        selrahcd-obsidian-vault-context/tests/files.bats \
        selrahcd-obsidian-vault-context/tests/directories.bats
git commit -m "feat(obsidian-vault-context): list subcommand with merge and human output"
```

---

## Task 7: `list` filters: `--kind`, `--label` (AND/OR), `--search`

**Files:**
- Modify: `selrahcd-obsidian-vault-context/bin/obsidian-context`
- Modify: `selrahcd-obsidian-vault-context/tests/files.bats`
- Modify: `selrahcd-obsidian-vault-context/tests/directories.bats`

- [ ] **Step 1: Write failing tests for filters**

Append to `selrahcd-obsidian-vault-context/tests/files.bats`:

```bash
@test "list --kind files: shows only file entries" {
  write_config "$TMP_ROOT/A" '{
    "files": [{"path": "f.md", "description": "F", "labels": []}],
    "directories": [{"path": "d/", "description": "D", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A" list --kind files
  [[ "$output" == *"f.md"* ]]
  [[ "$output" != *"d/"* ]]
}

@test "list --label foo: shows only entries with that label" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "x.md", "description": "X", "labels": ["foo"]},
      {"path": "y.md", "description": "Y", "labels": ["bar"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --label foo
  [[ "$output" == *"x.md"* ]]
  [[ "$output" != *"y.md"* ]]
}

@test "list --label foo --label bar: AND semantics by default" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "both.md", "description": "B", "labels": ["foo", "bar"]},
      {"path": "foo.md", "description": "F", "labels": ["foo"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --label foo --label bar
  [[ "$output" == *"both.md"* ]]
  [[ "$output" != *"foo.md"* ]]
}

@test "list --label foo --label bar --any: OR semantics with --any" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "foo.md", "description": "F", "labels": ["foo"]},
      {"path": "bar.md", "description": "B", "labels": ["bar"]},
      {"path": "neither.md", "description": "N", "labels": []}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --label foo --label bar --any
  [[ "$output" == *"foo.md"* ]]
  [[ "$output" == *"bar.md"* ]]
  [[ "$output" != *"neither.md"* ]]
}

@test "list --search auth: substring match on path or description, case-insensitive" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "Auth/refactor.md", "description": "Stuff", "labels": []},
      {"path": "Other/x.md", "description": "About authentication", "labels": []},
      {"path": "Other/y.md", "description": "Unrelated", "labels": []}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --search auth
  [[ "$output" == *"Auth/refactor.md"* ]]
  [[ "$output" == *"Other/x.md"* ]]
  [[ "$output" != *"Other/y.md"* ]]
}
```

Append to `selrahcd-obsidian-vault-context/tests/directories.bats`:

```bash
@test "list --kind directories: shows only directory entries" {
  write_config "$TMP_ROOT/A" '{
    "files": [{"path": "f.md", "description": "F", "labels": []}],
    "directories": [{"path": "d/", "description": "D", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A" list --kind directories
  [[ "$output" != *"f.md"* ]]
  [[ "$output" == *"d/"* ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 6 failures (filters not implemented; flags ignored).

- [ ] **Step 3: Implement filters in the dispatcher**

In `selrahcd-obsidian-vault-context/bin/obsidian-context`, replace the `list)` case with:

```bash
  list)
    kind=""
    labels=()
    any=0
    search=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --kind) kind="$2"; shift 2 ;;
        --label) labels+=("$2"); shift 2 ;;
        --any) any=1; shift ;;
        --search) search="$2"; shift 2 ;;
        --help|-h)
          cat <<'EOF'
Usage: obsidian-context list [--kind files|directories]
                             [--label <name>]... [--any]
                             [--search <term>]
                             [--json]
EOF
          exit 0
          ;;
        *) printf 'obsidian-context: list: unexpected arg %q\n' "$1" >&2; exit 2 ;;
      esac
    done

    if [[ -n "$kind" && "$kind" != "files" && "$kind" != "directories" ]]; then
      printf 'obsidian-context: list: --kind must be "files" or "directories"\n' >&2
      exit 2
    fi

    merged=$(build_merged "$EFFECTIVE_CWD")

    # Apply filters via jq, producing a filtered merged-shape JSON.
    labels_json="[]"
    if [[ ${#labels[@]} -gt 0 ]]; then
      labels_json=$(printf '%s\n' "${labels[@]}" | jq -R . | jq -s .)
    fi

    filtered=$(jq \
      --arg kind "$kind" \
      --argjson labels "$labels_json" \
      --argjson any "$any" \
      --arg search "$search" \
      '
      def matches_labels($entry):
        if ($labels | length) == 0 then true
        elif $any == 1 then
          ($entry.labels // []) as $L | any($labels[]; . as $l | $L | index($l))
        else
          ($entry.labels // []) as $L | all($labels[]; . as $l | $L | index($l))
        end;

      def matches_search($entry):
        if $search == "" then true
        else
          ($entry.path | ascii_downcase | contains($search | ascii_downcase))
          or ($entry.description | ascii_downcase | contains($search | ascii_downcase))
        end;

      {
        files: (
          if $kind == "directories" then []
          else (.files // []) | map(select(matches_labels(.) and matches_search(.)))
          end
        ),
        directories: (
          if $kind == "files" then []
          else (.directories // []) | map(select(matches_labels(.) and matches_search(.)))
          end
        ),
        labels: (.labels // {})
      }
      ' <<<"$merged")

    if [[ "$JSON_OUTPUT" == "1" ]]; then
      output_entries_json "$filtered"
    else
      output_entries_human "$filtered"
    fi
    ;;
```

- [ ] **Step 4: Run tests**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add selrahcd-obsidian-vault-context/bin/obsidian-context \
        selrahcd-obsidian-vault-context/tests/files.bats \
        selrahcd-obsidian-vault-context/tests/directories.bats
git commit -m "feat(obsidian-vault-context): list filters --kind --label --any --search"
```

---

## Task 8: `labels` subcommand (read)

**Files:**
- Create: `selrahcd-obsidian-vault-context/tests/labels.bats`
- Modify: `selrahcd-obsidian-vault-context/bin/obsidian-context`

- [ ] **Step 1: Write failing tests**

Create `selrahcd-obsidian-vault-context/tests/labels.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "labels: empty when no configs" {
  run_cli "$TMP_ROOT/A" labels
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "labels: lists single config's labels" {
  write_config "$TMP_ROOT/A" '{
    "labels": {
      "marketplace": "Marketplace plugin work",
      "project": "Active project notes"
    }
  }'
  run_cli "$TMP_ROOT/A" labels
  [ "$status" -eq 0 ]
  [[ "$output" == *"marketplace"* ]]
  [[ "$output" == *"Marketplace plugin work"* ]]
  [[ "$output" == *"project"* ]]
}

@test "labels: closest description wins on conflict" {
  write_global_config '{"labels": {"project": "Generic project"}}'
  write_config "$TMP_ROOT/A" '{"labels": {"project": "This specific project"}}'
  run_cli "$TMP_ROOT/A" labels
  [ "$status" -eq 0 ]
  [[ "$output" == *"This specific project"* ]]
  [[ "$output" != *"Generic project"* ]]
}

@test "labels --show-source: includes source path" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "X desc"}}'
  run_cli "$TMP_ROOT/A" labels --show-source
  [ "$status" -eq 0 ]
  [[ "$output" == *"x: X desc"* ]]
  [[ "$output" == *"from:"*"A/.obsidian-vault-context.json"* ]]
}

@test "labels --search: substring filter on label name and description" {
  write_config "$TMP_ROOT/A" '{
    "labels": {
      "marketplace": "Plugin marketplace work",
      "auth": "Authentication module"
    }
  }'
  run_cli "$TMP_ROOT/A" labels --search auth
  [ "$status" -eq 0 ]
  [[ "$output" == *"auth"* ]]
  [[ "$output" != *"marketplace"* ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 5 failures (`labels` not implemented).

- [ ] **Step 3: Implement `labels` in the dispatcher**

In `selrahcd-obsidian-vault-context/bin/obsidian-context`, add a `labels)` case before the `*)` fallthrough:

```bash
  labels)
    search=""
    show_source=0
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --search) search="$2"; shift 2 ;;
        --show-source) show_source=1; shift ;;
        --help|-h)
          cat <<'EOF'
Usage: obsidian-context labels [--search <term>] [--show-source] [--json]
EOF
          exit 0
          ;;
        *) printf 'obsidian-context: labels: unexpected arg %q\n' "$1" >&2; exit 2 ;;
      esac
    done

    merged=$(build_merged "$EFFECTIVE_CWD")

    filtered=$(jq --arg search "$search" '
      .labels // {}
      | if $search == "" then .
        else with_entries(
          select(
            (.key | ascii_downcase | contains($search | ascii_downcase))
            or (.value.description | ascii_downcase | contains($search | ascii_downcase))
          )
        )
        end
      | { labels: . }
    ' <<<"$merged")

    if [[ "$JSON_OUTPUT" == "1" ]]; then
      output_labels_json "$filtered"
    else
      output_labels_human "$filtered" "$show_source"
    fi
    ;;
```

- [ ] **Step 4: Run tests**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add selrahcd-obsidian-vault-context/bin/obsidian-context \
        selrahcd-obsidian-vault-context/tests/labels.bats
git commit -m "feat(obsidian-vault-context): labels subcommand with closest-wins merge"
```

---

## Task 9: `--json` output coverage

**Files:**
- Create: `selrahcd-obsidian-vault-context/tests/output.bats`

- [ ] **Step 1: Write failing tests**

Create `selrahcd-obsidian-vault-context/tests/output.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "list --json: emits valid JSON with files+directories arrays" {
  write_config "$TMP_ROOT/A" '{
    "files": [{"path": "f.md", "description": "F", "labels": ["x"]}],
    "directories": [{"path": "d/", "description": "D", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A" --json list
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.files | length == 1' >/dev/null
  echo "$output" | jq -e '.directories | length == 1' >/dev/null
  echo "$output" | jq -e '.files[0].source | endswith("A/.obsidian-vault-context.json")' >/dev/null
}

@test "labels --json: emits valid JSON object of name -> {description, source}" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "X desc"}}'
  run_cli "$TMP_ROOT/A" --json labels
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.x.description == "X desc"' >/dev/null
  echo "$output" | jq -e '.x.source | endswith("A/.obsidian-vault-context.json")' >/dev/null
}

@test "list --json applies filters" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "a.md", "description": "A", "labels": ["x"]},
      {"path": "b.md", "description": "B", "labels": ["y"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" --json list --label x
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.files | length == 1' >/dev/null
  echo "$output" | jq -e '.files[0].path == "a.md"' >/dev/null
}
```

- [ ] **Step 2: Run tests**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all 3 pass (the implementation already supports `--json` from Tasks 6–8).

If a test fails because of structural mismatch, fix `output_entries_json` / `output_labels_json` accordingly and re-run.

- [ ] **Step 3: Commit**

```bash
git add selrahcd-obsidian-vault-context/tests/output.bats
git commit -m "test(obsidian-vault-context): cover --json output shape"
```

---

## Task 10: Scope resolution lib

**Files:**
- Create: `selrahcd-obsidian-vault-context/lib/scope.sh`
- Create: `selrahcd-obsidian-vault-context/tests/scopes.bats`
- Modify: `selrahcd-obsidian-vault-context/bin/obsidian-context`

- [ ] **Step 1: Write failing tests**

Create `selrahcd-obsidian-vault-context/tests/scopes.bats`:

```bash
#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

# We exercise scope resolution via `add file`, since it's the simplest write.
# The CLI adds the entry to the file resolved from --scope. Tests assert which
# file got written.

@test "scope local: writes to closest existing config above CWD" {
  write_config "$TMP_ROOT/A" '{}'
  mkdir -p "$TMP_ROOT/A/B/C"
  run_cli "$TMP_ROOT/A/B/C" add file foo.md --description "X"
  [ "$status" -eq 0 ]
  [ -f "$TMP_ROOT/A/.obsidian-vault-context.json" ]
  [ ! -f "$TMP_ROOT/A/B/C/.obsidian-vault-context.json" ]
  jq -e '.files[0].path == "foo.md"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "scope local: errors when no config exists at or above CWD" {
  mkdir -p "$TMP_ROOT/A/B/C"
  run_cli "$TMP_ROOT/A/B/C" add file foo.md --description "X"
  [ "$status" -ne 0 ]
  [[ "$output" == *"no existing"* ]] || [[ "$output" == *"current-directory"* ]]
}

@test "scope current-directory: creates config at CWD" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope current-directory
  [ "$status" -eq 0 ]
  [ -f "$TMP_ROOT/A/.obsidian-vault-context.json" ]
}

@test "scope global: creates ~/.obsidian-vault-context.json" {
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope global
  [ "$status" -eq 0 ]
  [ -f "$HOME/.obsidian-vault-context.json" ]
}

@test "scope <abs-path>: writes to that directory's config" {
  mkdir -p "$TMP_ROOT/clientA"
  mkdir -p "$TMP_ROOT/clientA/repoB"
  run_cli "$TMP_ROOT/clientA/repoB" add file foo.md --description "X" --scope "$TMP_ROOT/clientA"
  [ "$status" -eq 0 ]
  [ -f "$TMP_ROOT/clientA/.obsidian-vault-context.json" ]
}

@test "scope <path>: errors when directory does not exist" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope "$TMP_ROOT/does/not/exist"
  [ "$status" -ne 0 ]
  [[ "$output" == *"directory does not exist"* ]] || [[ "$output" == *"$TMP_ROOT/does/not/exist"* ]]
}

@test "scope ./local: directory literally named 'local' is treated as path when prefixed" {
  mkdir -p "$TMP_ROOT/A/local"
  run_cli "$TMP_ROOT/A" add file foo.md --description "X" --scope "./local"
  [ "$status" -eq 0 ]
  [ -f "$TMP_ROOT/A/local/.obsidian-vault-context.json" ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 7 new failures (`add file` not implemented yet).

- [ ] **Step 3: Write the scope library**

Create `selrahcd-obsidian-vault-context/lib/scope.sh`:

```bash
# Scope resolution: convert a --scope value into a target file path.
#
# Functions:
#   scope_resolve <scope-value> <effective-cwd>
#     Prints the target file path on stdout.
#     Exits non-zero with a stderr message on errors (no existing config for
#     'local', missing dir for path scope, etc).
#
# Scope values:
#   local              -> closest existing .obsidian-vault-context.json at or above cwd
#   current-directory  -> <cwd>/.obsidian-vault-context.json (created on demand by caller)
#   global             -> $HOME/.obsidian-vault-context.json (created on demand by caller)
#   <path>             -> <path>/.obsidian-vault-context.json. <path> must be an existing directory.

scope_resolve() {
  local scope="$1"
  local cwd="$2"

  case "$scope" in
    local)
      # Walk up looking for an existing config.
      local dir
      dir="$(cd "$cwd" 2>/dev/null && pwd -P)" || {
        printf 'obsidian-context: --scope local: --cwd directory does not exist\n' >&2
        return 1
      }
      while :; do
        if [[ -f "$dir/.obsidian-vault-context.json" ]]; then
          printf '%s\n' "$dir/.obsidian-vault-context.json"
          return 0
        fi
        if [[ "$dir" == "/" ]]; then
          break
        fi
        dir="$(dirname "$dir")"
      done
      printf 'obsidian-context: no existing .obsidian-vault-context.json found at or above %s\n' "$cwd" >&2
      printf 'use --scope current-directory to create one here, or --scope <dir>\n' >&2
      return 1
      ;;
    current-directory)
      local dir
      dir="$(cd "$cwd" 2>/dev/null && pwd -P)" || {
        printf 'obsidian-context: --scope current-directory: --cwd directory does not exist\n' >&2
        return 1
      }
      printf '%s\n' "$dir/.obsidian-vault-context.json"
      ;;
    global)
      printf '%s\n' "$HOME/.obsidian-vault-context.json"
      ;;
    *)
      # Treat as a path.
      local resolved
      resolved="$(cd "$scope" 2>/dev/null && pwd -P)" || {
        printf 'obsidian-context: --scope: directory does not exist: %s\n' "$scope" >&2
        return 1
      }
      printf '%s\n' "$resolved/.obsidian-vault-context.json"
      ;;
  esac
}
```

- [ ] **Step 4: Wire into the dispatcher**

In `selrahcd-obsidian-vault-context/bin/obsidian-context`, add `source "$LIB_DIR/scope.sh"` near the top with the other sources. (The actual `add file` implementation comes in Task 11; the scope tests fail until then.)

- [ ] **Step 5: Commit (tests still failing — that's fine, Task 11 makes them pass)**

```bash
git add selrahcd-obsidian-vault-context/lib/scope.sh \
        selrahcd-obsidian-vault-context/bin/obsidian-context \
        selrahcd-obsidian-vault-context/tests/scopes.bats
git commit -m "feat(obsidian-vault-context): scope resolution lib + scope tests (failing until add file)"
```

---

## Task 11: Atomic write helper + `add file` subcommand

**Files:**
- Create: `selrahcd-obsidian-vault-context/lib/write.sh`
- Modify: `selrahcd-obsidian-vault-context/bin/obsidian-context`
- Modify: `selrahcd-obsidian-vault-context/tests/files.bats`

- [ ] **Step 1: Write failing tests for `add file`**

Append to `selrahcd-obsidian-vault-context/tests/files.bats`:

```bash
@test "add file: creates file with single entry when none exists" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file "Notes/X.md" --description "X note" --label foo --scope current-directory
  [ "$status" -eq 0 ]
  [ -f "$TMP_ROOT/A/.obsidian-vault-context.json" ]
  jq -e '.files | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].path == "Notes/X.md"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].description == "X note"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].labels == ["foo"]' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file: appends to existing files[]" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "old.md", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add file "new.md" --description "New" --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.files | length == 2' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file: duplicate path with same fields is a no-op (idempotent)" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "x.md", "description": "X", "labels": ["a"]}]}'
  run_cli "$TMP_ROOT/A" add file "x.md" --description "X" --label a --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.files | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file: duplicate path with different description fails without --force" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "x.md", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add file "x.md" --description "New" --scope current-directory
  [ "$status" -ne 0 ]
  [[ "$output" == *"--force"* ]] || [[ "$output" == *"already exists"* ]]
  # Original unchanged
  jq -e '.files[0].description == "Old"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file --force: overwrites existing entry" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "x.md", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add file "x.md" --description "New" --label fresh --scope current-directory --force
  [ "$status" -eq 0 ]
  jq -e '.files | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].description == "New"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].labels == ["fresh"]' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file: errors without --description" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file "x.md" --scope current-directory
  [ "$status" -ne 0 ]
  [[ "$output" == *"--description"* ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 6 new failures + the 7 from scopes.bats still failing.

- [ ] **Step 3: Write the atomic write helper**

Create `selrahcd-obsidian-vault-context/lib/write.sh`:

```bash
# Atomic file writes for .obsidian-vault-context.json, with mtime conflict detection.
#
# Functions:
#   write_atomic_json <target-file> <jq-program> [<jq-args>...]
#     If <target-file> exists, captures its mtime, runs the jq program over its
#     contents, writes to <target>.tmp, re-checks mtime, then mv's into place.
#     If <target-file> does not exist, runs the jq program over `null` and writes.
#     Conflict (mtime changed) -> exit 1 with stderr message.

write_atomic_json() {
  local target="$1"; shift
  local jq_program="$1"; shift

  local input mtime_before mtime_after
  if [[ -f "$target" ]]; then
    mtime_before=$(stat -f '%m' "$target" 2>/dev/null || stat -c '%Y' "$target")
    input=$(cat "$target")
  else
    mtime_before=""
    input="null"
  fi

  local tmp="$target.tmp.$$"
  if ! printf '%s' "$input" | jq "$@" "$jq_program" > "$tmp"; then
    rm -f "$tmp"
    printf 'obsidian-context: write: jq transform failed\n' >&2
    return 1
  fi

  if [[ -f "$target" ]]; then
    mtime_after=$(stat -f '%m' "$target" 2>/dev/null || stat -c '%Y' "$target")
    if [[ "$mtime_before" != "$mtime_after" ]]; then
      rm -f "$tmp"
      printf 'obsidian-context: %s: file changed on disk; re-run\n' "$target" >&2
      return 1
    fi
  fi

  mv "$tmp" "$target"
}
```

- [ ] **Step 4: Implement `add file` in the dispatcher**

In `selrahcd-obsidian-vault-context/bin/obsidian-context`, source the new lib near the top:

```bash
source "$LIB_DIR/write.sh"
```

Add an `add)` case before the `*)` fallthrough:

```bash
  add)
    [[ $# -gt 0 ]] || { printf 'obsidian-context: add: missing kind (file|directory)\n' >&2; exit 2; }
    kind="$1"; shift
    case "$kind" in
      file|directory)
        # Map to plural collection name in the JSON.
        if [[ "$kind" == "file" ]]; then collection="files"; else collection="directories"; fi
        ;;
      *)
        printf 'obsidian-context: add: unknown kind %q (expected file or directory)\n' "$kind" >&2
        exit 2
        ;;
    esac

    [[ $# -gt 0 ]] || { printf 'obsidian-context: add %s: missing <vault-path>\n' "$kind" >&2; exit 2; }
    vault_path="$1"; shift

    description=""
    labels=()
    scope="local"
    force=0

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --description) description="$2"; shift 2 ;;
        --label) labels+=("$2"); shift 2 ;;
        --scope) scope="$2"; shift 2 ;;
        --force) force=1; shift ;;
        --help|-h)
          cat <<EOF
Usage: obsidian-context add $kind <vault-path>
                          --description <text>
                          [--label <name>]...
                          [--scope local|current-directory|global|<path>]
                          [--force]
EOF
          exit 0
          ;;
        *) printf 'obsidian-context: add %s: unexpected arg %q\n' "$kind" "$1" >&2; exit 2 ;;
      esac
    done

    if [[ -z "$description" ]]; then
      printf 'obsidian-context: add %s: --description is required\n' "$kind" >&2
      exit 2
    fi

    target=$(scope_resolve "$scope" "$EFFECTIVE_CWD") || exit 1

    # Validate target before write (if it exists and has content).
    if [[ -f "$target" && -s "$target" ]]; then
      schema_validate_file "$target" || exit 1
    fi

    # Build the labels JSON array.
    labels_json="[]"
    if [[ ${#labels[@]} -gt 0 ]]; then
      labels_json=$(printf '%s\n' "${labels[@]}" | jq -R . | jq -s .)
    fi

    # Conflict check + apply via jq.
    # Note: must use `if !` (not `cmd; rc=$?`) because `set -e` would otherwise
    # exit before we can inspect the failure mode.
    if ! write_atomic_json "$target" '
      def empty_doc: {files: [], directories: [], labels: {}};
      (if . == null then empty_doc else . end) as $doc
      | ($doc[$collection] // []) as $arr
      | ($arr | map(.path == $vp) | any) as $exists
      | ($arr | map(select(.path == $vp))[0]) as $existing
      | if $exists then
          if $force == 1 then
            $doc | .[$collection] = (
              ($arr | map(select(.path != $vp)))
              + [{ path: $vp, description: $desc, labels: $labels }]
            )
          elif ($existing.description == $desc and (($existing.labels // []) == $labels)) then
            # idempotent no-op
            $doc
          else
            # signal conflict via error()
            error("CONFLICT")
          end
        else
          $doc | .[$collection] = $arr + [{ path: $vp, description: $desc, labels: $labels }]
        end
      ' \
      --arg collection "$collection" \
      --arg vp "$vault_path" \
      --arg desc "$description" \
      --argjson labels "$labels_json" \
      --argjson force "$force" ; then
      # Distinguish CONFLICT from other failures by re-checking the file.
      if [[ -f "$target" ]] && jq -e --arg c "$collection" --arg vp "$vault_path" \
          '.[$c] // [] | map(.path == $vp) | any' "$target" >/dev/null; then
        printf 'obsidian-context: add %s: entry %q already exists with different fields; use --force to overwrite\n' \
          "$kind" "$vault_path" >&2
      fi
      exit 1
    fi
    ;;
```

> **Note on conflict signaling:** the jq program calls `error("CONFLICT")` which makes `jq` exit non-zero. The dispatcher catches that and prints a clear message. The dual-check via re-reading the file is defensive — if the target ended up missing for an unrelated reason, we don't print a misleading conflict message.

- [ ] **Step 5: Run tests**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all `files.bats` tests pass; `scopes.bats` tests now pass too (since `add file` exercises scope resolution).

- [ ] **Step 6: Commit**

```bash
git add selrahcd-obsidian-vault-context/lib/write.sh \
        selrahcd-obsidian-vault-context/bin/obsidian-context \
        selrahcd-obsidian-vault-context/tests/files.bats
git commit -m "feat(obsidian-vault-context): add file subcommand with --force and conflict detection"
```

---

## Task 12: `add directory` subcommand

**Files:**
- Modify: `selrahcd-obsidian-vault-context/tests/directories.bats`

The `add)` dispatcher case from Task 11 already handles `directory` — confirm via tests.

- [ ] **Step 1: Write tests**

Append to `selrahcd-obsidian-vault-context/tests/directories.bats`:

```bash
@test "add directory: creates entry in directories[]" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add directory "Projects/" --description "All projects" --label root --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.directories | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.directories[0].path == "Projects/"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.directories[0].labels == ["root"]' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add directory: --force overwrites existing entry" {
  write_config "$TMP_ROOT/A" '{"directories": [{"path": "P/", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add directory "P/" --description "New" --scope current-directory --force
  [ "$status" -eq 0 ]
  jq -e '.directories[0].description == "New"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}
```

- [ ] **Step 2: Run tests**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: both new tests pass (no implementation work needed; the Task 11 dispatcher already handles `directory`).

- [ ] **Step 3: Commit**

```bash
git add selrahcd-obsidian-vault-context/tests/directories.bats
git commit -m "test(obsidian-vault-context): cover add directory"
```

---

## Task 13: `remove file` and `remove directory`

**Files:**
- Modify: `selrahcd-obsidian-vault-context/bin/obsidian-context`
- Modify: `selrahcd-obsidian-vault-context/tests/files.bats`
- Modify: `selrahcd-obsidian-vault-context/tests/directories.bats`

- [ ] **Step 1: Write failing tests**

Append to `selrahcd-obsidian-vault-context/tests/files.bats`:

```bash
@test "remove file: removes the matching entry, leaves others" {
  write_config "$TMP_ROOT/A" '{"files": [
    {"path": "keep.md", "description": "K", "labels": []},
    {"path": "drop.md", "description": "D", "labels": []}
  ]}'
  run_cli "$TMP_ROOT/A" remove file "drop.md" --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.files | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].path == "keep.md"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "remove file: errors when target file does not exist" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" remove file "x.md" --scope current-directory
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"does not exist"* ]]
}

@test "remove file: errors when entry not found in existing config" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "other.md", "description": "O", "labels": []}]}'
  run_cli "$TMP_ROOT/A" remove file "missing.md" --scope current-directory
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing.md"* ]]
}
```

Append to `selrahcd-obsidian-vault-context/tests/directories.bats`:

```bash
@test "remove directory: removes the matching entry" {
  write_config "$TMP_ROOT/A" '{"directories": [
    {"path": "keep/", "description": "K", "labels": []},
    {"path": "drop/", "description": "D", "labels": []}
  ]}'
  run_cli "$TMP_ROOT/A" remove directory "drop/" --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.directories | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 4 failures.

- [ ] **Step 3: Implement `remove)` in the dispatcher**

In `selrahcd-obsidian-vault-context/bin/obsidian-context`, add a `remove)` case:

```bash
  remove)
    [[ $# -gt 0 ]] || { printf 'obsidian-context: remove: missing kind\n' >&2; exit 2; }
    kind="$1"; shift
    case "$kind" in
      file) collection="files" ;;
      directory) collection="directories" ;;
      *) printf 'obsidian-context: remove: unknown kind %q\n' "$kind" >&2; exit 2 ;;
    esac

    [[ $# -gt 0 ]] || { printf 'obsidian-context: remove %s: missing <vault-path>\n' "$kind" >&2; exit 2; }
    vault_path="$1"; shift

    scope="local"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --scope) scope="$2"; shift 2 ;;
        --help|-h) printf 'Usage: obsidian-context remove %s <vault-path> [--scope ...]\n' "$kind"; exit 0 ;;
        *) printf 'obsidian-context: remove %s: unexpected arg %q\n' "$kind" "$1" >&2; exit 2 ;;
      esac
    done

    target=$(scope_resolve "$scope" "$EFFECTIVE_CWD") || exit 1

    if [[ ! -f "$target" ]]; then
      printf 'obsidian-context: remove %s: target file does not exist: %s\n' "$kind" "$target" >&2
      exit 1
    fi

    schema_validate_file "$target" || exit 1

    # Verify the entry exists before write.
    if ! jq -e --arg c "$collection" --arg vp "$vault_path" \
        '.[$c] // [] | map(.path == $vp) | any' "$target" >/dev/null; then
      printf 'obsidian-context: remove %s: entry %q not found in %s\n' "$kind" "$vault_path" "$target" >&2
      exit 1
    fi

    write_atomic_json "$target" '
      .[$c] = ((.[$c] // []) | map(select(.path != $vp)))
    ' \
      --arg c "$collection" \
      --arg vp "$vault_path"
    ;;
```

- [ ] **Step 4: Run tests**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add selrahcd-obsidian-vault-context/bin/obsidian-context \
        selrahcd-obsidian-vault-context/tests/files.bats \
        selrahcd-obsidian-vault-context/tests/directories.bats
git commit -m "feat(obsidian-vault-context): remove file/directory subcommands"
```

---

## Task 14: `label set` and `label remove`

**Files:**
- Modify: `selrahcd-obsidian-vault-context/bin/obsidian-context`
- Modify: `selrahcd-obsidian-vault-context/tests/labels.bats`

- [ ] **Step 1: Write failing tests**

Append to `selrahcd-obsidian-vault-context/tests/labels.bats`:

```bash
@test "label set: defines a new label" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" label set marketplace "Marketplace plugin work" --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.labels.marketplace == "Marketplace plugin work"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "label set: refines an existing label (no --force needed)" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "old"}}'
  run_cli "$TMP_ROOT/A" label set x "new desc" --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.labels.x == "new desc"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "label remove: removes the named label" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "X", "y": "Y"}}'
  run_cli "$TMP_ROOT/A" label remove x --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.labels | has("x") == false' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.labels.y == "Y"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "label remove: errors when label not found" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "X"}}'
  run_cli "$TMP_ROOT/A" label remove missing --scope current-directory
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing"* ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: 4 failures.

- [ ] **Step 3: Implement `label)` (singular, mutating) case**

> **Naming note:** `obsidian-context labels` (plural) lists; `obsidian-context label set/remove` (singular) mutates. This mirrors patterns like `git branch` (list) vs `git branch -d` (mutate). Document this in the help.

In `selrahcd-obsidian-vault-context/bin/obsidian-context`, add a `label)` case:

```bash
  label)
    [[ $# -gt 0 ]] || { printf 'obsidian-context: label: missing action (set|remove)\n' >&2; exit 2; }
    action="$1"; shift

    case "$action" in
      set)
        [[ $# -ge 2 ]] || { printf 'obsidian-context: label set: requires <name> <description>\n' >&2; exit 2; }
        name="$1"; shift
        desc="$1"; shift
        scope="local"
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --scope) scope="$2"; shift 2 ;;
            --help|-h) printf 'Usage: obsidian-context label set <name> <description> [--scope ...]\n'; exit 0 ;;
            *) printf 'obsidian-context: label set: unexpected arg %q\n' "$1" >&2; exit 2 ;;
          esac
        done

        target=$(scope_resolve "$scope" "$EFFECTIVE_CWD") || exit 1

        if [[ -f "$target" && -s "$target" ]]; then
          schema_validate_file "$target" || exit 1
        fi

        write_atomic_json "$target" '
          (if . == null then {files: [], directories: [], labels: {}} else . end)
          | .labels = ((.labels // {}) | .[$name] = $desc)
        ' \
          --arg name "$name" \
          --arg desc "$desc"
        ;;

      remove)
        [[ $# -ge 1 ]] || { printf 'obsidian-context: label remove: requires <name>\n' >&2; exit 2; }
        name="$1"; shift
        scope="local"
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --scope) scope="$2"; shift 2 ;;
            --help|-h) printf 'Usage: obsidian-context label remove <name> [--scope ...]\n'; exit 0 ;;
            *) printf 'obsidian-context: label remove: unexpected arg %q\n' "$1" >&2; exit 2 ;;
          esac
        done

        target=$(scope_resolve "$scope" "$EFFECTIVE_CWD") || exit 1

        if [[ ! -f "$target" ]]; then
          printf 'obsidian-context: label remove: target file does not exist: %s\n' "$target" >&2
          exit 1
        fi

        schema_validate_file "$target" || exit 1

        if ! jq -e --arg n "$name" '(.labels // {}) | has($n)' "$target" >/dev/null; then
          printf 'obsidian-context: label remove: label %q not found in %s\n' "$name" "$target" >&2
          exit 1
        fi

        write_atomic_json "$target" '
          .labels = ((.labels // {}) | del(.[$name]))
        ' \
          --arg name "$name"
        ;;

      *)
        printf 'obsidian-context: label: unknown action %q (expected set or remove)\n' "$action" >&2
        exit 2
        ;;
    esac
    ;;
```

- [ ] **Step 4: Run tests**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add selrahcd-obsidian-vault-context/bin/obsidian-context \
        selrahcd-obsidian-vault-context/tests/labels.bats
git commit -m "feat(obsidian-vault-context): label set and label remove subcommands"
```

---

## Task 15: Dependency check (jq, bash ≥ 4) on startup

**Files:**
- Modify: `selrahcd-obsidian-vault-context/bin/obsidian-context`

- [ ] **Step 1: Add a dependency check at the very top of the dispatcher**

In `selrahcd-obsidian-vault-context/bin/obsidian-context`, immediately after the `set -euo pipefail` line, insert:

```bash
# Dependency check.
if ! command -v jq >/dev/null 2>&1; then
  printf 'obsidian-context: jq is required but not found on PATH (install with `brew install jq` or your distro package manager)\n' >&2
  exit 127
fi

if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
  printf 'obsidian-context: bash >= 4 is required (current: %s). On macOS install via `brew install bash`, then ensure brew bash is first on PATH.\n' "${BASH_VERSION:-unknown}" >&2
  exit 127
fi
```

- [ ] **Step 2: Smoke test**

Run: `selrahcd-obsidian-vault-context/bin/obsidian-context --help`
Expected: still prints help, exit 0 (since `jq` and bash 4+ are installed locally).

- [ ] **Step 3: Run full test suite**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all tests still pass.

- [ ] **Step 4: Commit**

```bash
git add selrahcd-obsidian-vault-context/bin/obsidian-context
git commit -m "feat(obsidian-vault-context): check jq and bash >= 4 at startup"
```

---

## Task 16: Skill `read-context`

**Files:**
- Create: `selrahcd-obsidian-vault-context/skills/read-context/SKILL.md`

- [ ] **Step 1: Write the skill**

Create `selrahcd-obsidian-vault-context/skills/read-context/SKILL.md`:

````markdown
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
````

- [ ] **Step 2: Verify the skill loads**

Run Claude Code with the plugin enabled (or use `--plugin-dir`):

```bash
claude --plugin-dir ./selrahcd-obsidian-vault-context
```

Inside, type `/obsidian-vault-context:read-context` and confirm the skill content is rendered.

- [ ] **Step 3: Commit**

```bash
git add selrahcd-obsidian-vault-context/skills/read-context/SKILL.md
git commit -m "feat(obsidian-vault-context): add read-context skill"
```

---

## Task 17: Skill `add-file`

**Files:**
- Create: `selrahcd-obsidian-vault-context/skills/add-file/SKILL.md`

- [ ] **Step 1: Write the skill**

Create `selrahcd-obsidian-vault-context/skills/add-file/SKILL.md`:

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add selrahcd-obsidian-vault-context/skills/add-file/SKILL.md
git commit -m "feat(obsidian-vault-context): add add-file skill"
```

---

## Task 18: Skill `add-directory`

**Files:**
- Create: `selrahcd-obsidian-vault-context/skills/add-directory/SKILL.md`

- [ ] **Step 1: Write the skill**

Create `selrahcd-obsidian-vault-context/skills/add-directory/SKILL.md`:

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add selrahcd-obsidian-vault-context/skills/add-directory/SKILL.md
git commit -m "feat(obsidian-vault-context): add add-directory skill"
```

---

## Task 19: Skill `labels`

**Files:**
- Create: `selrahcd-obsidian-vault-context/skills/labels/SKILL.md`

- [ ] **Step 1: Write the skill**

Create `selrahcd-obsidian-vault-context/skills/labels/SKILL.md`:

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add selrahcd-obsidian-vault-context/skills/labels/SKILL.md
git commit -m "feat(obsidian-vault-context): add labels management skill"
```

---

## Task 20: README

**Files:**
- Create: `selrahcd-obsidian-vault-context/README.md`

- [ ] **Step 1: Write the README**

Create `selrahcd-obsidian-vault-context/README.md`:

````markdown
# obsidian-vault-context

A directory-aware index of Obsidian vault notes and directories, queryable from any working directory via the `obsidian-context` CLI.

## What it does

When you work in a code project that lives outside your vault, this plugin lets you tell the agent "these vault notes/directories are relevant when working here". The index lives in `.obsidian-vault-context.json` files at any directory level, plus a global `~/.obsidian-vault-context.json`. The CLI walks up the directory tree, merges all discovered configs (closest-first), and answers filtered queries — so the agent doesn't need to scan the vault.

## How it relates to `obsidian-bridge`

This plugin is a sibling to `obsidian-bridge`. It does **not** replace it. `obsidian-bridge` continues to read its own `.claude/obsidian-bridge.json` for project name, tags, tracking entries, and the SessionEnd auto-doc. This plugin uses a different file (`.obsidian-vault-context.json`, at the directory root) for the directory-aware index. A future release of `obsidian-bridge` may merge into this file, but for now they coexist.

## Prerequisites

- `bash` ≥ 4 (on macOS: `brew install bash` and ensure brew bash is first on PATH)
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
                      [--json]

obsidian-context labels [--search <term>]
                        [--show-source]
                        [--json]

obsidian-context where [--json]
```

`list` returns merged file and directory entries from every config encountered walking up from CWD plus the global config. Each entry shows its `source` (which config it came from). `--label` repeats are AND by default; `--any` switches to OR.

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
````

- [ ] **Step 2: Commit**

```bash
git add selrahcd-obsidian-vault-context/README.md
git commit -m "docs(obsidian-vault-context): add README"
```

---

## Task 21: GitHub Actions workflow

**Files:**
- Create: `.github/workflows/test-vault-context.yml`

- [ ] **Step 1: Check whether `.github/workflows/` exists**

Run: `ls .github/workflows/ 2>/dev/null || echo "missing"`

Create the directory if missing: `mkdir -p .github/workflows`

- [ ] **Step 2: Write the workflow**

Create `.github/workflows/test-vault-context.yml`:

```yaml
name: obsidian-vault-context tests

on:
  push:
    paths:
      - "selrahcd-obsidian-vault-context/**"
      - ".github/workflows/test-vault-context.yml"
  pull_request:
    paths:
      - "selrahcd-obsidian-vault-context/**"
      - ".github/workflows/test-vault-context.yml"

jobs:
  bats:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install bats
        run: sudo apt-get update && sudo apt-get install -y bats jq

      - name: Verify bash version
        run: bash --version

      - name: Run tests
        run: ./selrahcd-obsidian-vault-context/tests/run.sh
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/test-vault-context.yml
git commit -m "ci(obsidian-vault-context): run bats on push/PR for plugin changes"
```

---

## Task 22: Final verification

- [ ] **Step 1: Run the full test suite locally**

Run: `selrahcd-obsidian-vault-context/tests/run.sh`
Expected: all tests pass.

- [ ] **Step 2: Smoke test against a real directory**

```bash
mkdir -p /tmp/ovc-smoke/inner
cd /tmp/ovc-smoke
obsidian-context add file "Notes/Smoke.md" --description "Smoke test" --label demo --scope current-directory
obsidian-context label set demo "Demo label for smoke test" --scope current-directory
obsidian-context list
obsidian-context labels
obsidian-context where
cd inner
obsidian-context list  # should still see Notes/Smoke.md (walks up to /tmp/ovc-smoke)
cd /
rm -rf /tmp/ovc-smoke
```

Expected: each command runs cleanly and shows the smoke entry.

- [ ] **Step 3: Verify plugin manifest and marketplace entry**

Run: `cat selrahcd-obsidian-vault-context/.claude-plugin/plugin.json`
Expected: `"version": "1.0.0"`, `"name": "obsidian-vault-context"`.

Run: `jq '.plugins[] | select(.name == "obsidian-vault-context")' .claude-plugin/marketplace.json`
Expected: matching entry with `"version": "1.0.0"` and `"source": "./selrahcd-obsidian-vault-context"`.

- [ ] **Step 4: Verify skills load**

Start Claude Code with the plugin enabled. Type `/obsidian-vault-context:` and confirm the four skills appear (`read-context`, `add-file`, `add-directory`, `labels`).

- [ ] **Step 5: Commit any final fixes (if needed)**

If smoke testing surfaced issues, fix them, re-run tests, commit:

```bash
git add -A
git commit -m "fix(obsidian-vault-context): <specific issue>"
```

---

## Done

The new plugin is complete:

- CLI `obsidian-context` with read/write subcommands, scope resolution, `--force`, atomic writes with mtime conflict detection.
- Schema validation, soft warnings for unknown keys, hard errors for malformed entries.
- Four skills wrapping the CLI for read context, add file/directory, manage labels.
- bats coverage organized by feature family (errors co-located).
- GitHub Actions runs the tests on changes.
- README documents schema, CLI, skills, label patterns.
- `obsidian-bridge` is untouched; the two plugins coexist.
