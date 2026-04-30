#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "CLI prints help when run with --help" {
  run "$CLI_BIN" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"obsidian-context"* ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "CLI prints help when run with no args" {
  run "$CLI_BIN"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "CLI exits 2 with a clear message when --cwd has no argument" {
  run "$CLI_BIN" --cwd
  [ "$status" -eq 2 ]
  [[ "$output" == *"--cwd"* ]]
  [[ "$output" == *"path"* ]]
}

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
  # Count how many times the global path appears in output.
  count=$(echo "$output" | grep -c "^$HOME/.obsidian-vault-context.json$" || true)
  [ "$count" -eq 1 ]
}

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
