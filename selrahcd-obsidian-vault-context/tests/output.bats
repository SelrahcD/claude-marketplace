#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

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

@test "global --json after subcommand: still works (regression)" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "f.md", "description": "F", "labels": []}]}'
  run "$CLI_BIN" --cwd "$TMP_ROOT/A" list --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.files | length == 1' >/dev/null
}

@test "where: empty case prints stderr message and exits 0" {
  run_cli "$TMP_ROOT/A" where
  [ "$status" -eq 0 ]
  [[ "$output" == *"no .obsidian-vault-context.json found at or above"* ]]
  [[ "$output" == *"$TMP_ROOT/A"* ]]
}

@test "where: empty case routes message to stderr, leaves stdout empty" {
  run --separate-stderr "$CLI_BIN" --cwd "$TMP_ROOT/A" where
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [[ "$stderr" == *"no .obsidian-vault-context.json found at or above"* ]]
  [[ "$stderr" == *"$TMP_ROOT/A"* ]]
}

@test "list --json: empty case emits valid JSON and stays silent on stderr" {
  run --separate-stderr "$CLI_BIN" --cwd "$TMP_ROOT/A" --json list
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.files == [] and .directories == [] and (.labels // {}) == {}' >/dev/null
  [ -z "$stderr" ]
}
