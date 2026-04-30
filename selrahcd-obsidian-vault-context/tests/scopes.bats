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
