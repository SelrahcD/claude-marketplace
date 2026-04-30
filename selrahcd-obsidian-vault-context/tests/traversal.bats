#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "CLI prints help when run with --help" {
  run "$CLI_BIN" --help
  [ "$status" -eq 0 ]
  expected="obsidian-context — directory-aware index of Obsidian vault notes

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
  --help          Print this help"
  [ "$output" = "$expected" ]
}

@test "CLI prints help when run with no args" {
  run "$CLI_BIN"
  [ "$status" -eq 0 ]
  expected="obsidian-context — directory-aware index of Obsidian vault notes

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
  --help          Print this help"
  [ "$output" = "$expected" ]
}

@test "CLI exits 2 with a clear message when --cwd has no argument" {
  run "$CLI_BIN" --cwd
  [ "$status" -eq 2 ]
  [ "$output" = "obsidian-context: --cwd requires a path argument" ]
}

@test "where: lists CWD-only config when only CWD has one" {
  write_config "$TMP_ROOT/A/B/C" '{}'
  run_cli "$TMP_ROOT/A/B/C" where
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP_ROOT/A/B/C/.obsidian-vault-context.json" ]
}

@test "where: lists configs walking up from CWD to /, closest first" {
  write_config "$TMP_ROOT/A" '{}'
  write_config "$TMP_ROOT/A/B/C" '{}'
  run_cli "$TMP_ROOT/A/B/C" where

  [ "$status" -eq 0 ]
  expected="$TMP_ROOT/A/B/C/.obsidian-vault-context.json
$TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
}

@test "where: appends global config when present" {
  write_global_config '{}'
  write_config "$TMP_ROOT/A" '{}'
  run_cli "$TMP_ROOT/A" where
  [ "$status" -eq 0 ]
  expected="$TMP_ROOT/A/.obsidian-vault-context.json
$HOME/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
}

@test "where: returns nothing for non-existent CWD (silent on missing dir)" {
  # $TMP_ROOT/A/B/C does not exist as a directory; deviation from plan reference impl
  run_cli "$TMP_ROOT/A/B/C" where
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "where: returns nothing for an existing CWD with no configs anywhere" {
  mkdir -p "$TMP_ROOT/A/B/C"
  run_cli "$TMP_ROOT/A/B/C" where
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "where: deduplicates global config when HOME is an ancestor of CWD" {
  # Set HOME to a tmpdir, write a global config, then walk from a subdir of HOME.
  # The walk visits HOME and finds the global; the post-walk append must NOT re-emit it.
  mkdir -p "$HOME/sub/dir"
  write_global_config '{}'
  run_cli "$HOME/sub/dir" where
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.obsidian-vault-context.json" ]
}

@test "where: malformed JSON in a traversed file is a hard error" {
  write_config "$TMP_ROOT/A" 'not json {'
  run_cli "$TMP_ROOT/A" where
  [ "$status" -ne 0 ]
  [ "$output" = "obsidian-context: malformed JSON in $TMP_ROOT/A/.obsidian-vault-context.json" ]
}

@test "where: unknown top-level key emits a soft warning to stderr" {
  write_config "$TMP_ROOT/A" '{"obsidian-bridge": {"project": "X"}}'
  run_cli "$TMP_ROOT/A" where
  [ "$status" -eq 0 ]
  expected="obsidian-context: warning: unknown top-level key obsidian-bridge in $TMP_ROOT/A/.obsidian-vault-context.json
$TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
}

@test "where: malformed entry (missing path) is a hard error" {
  write_config "$TMP_ROOT/A" '{"files": [{"description": "x"}]}'
  run_cli "$TMP_ROOT/A" where
  [ "$status" -ne 0 ]
  [ "$output" = "obsidian-context: $TMP_ROOT/A/.obsidian-vault-context.json: an entry in files is missing required field \"path\"" ]
}
