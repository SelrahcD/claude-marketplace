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
