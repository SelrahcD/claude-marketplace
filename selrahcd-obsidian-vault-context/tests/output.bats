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
