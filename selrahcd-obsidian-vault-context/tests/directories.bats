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

@test "list --kind directories: shows only directory entries" {
  write_config "$TMP_ROOT/A" '{
    "files": [{"path": "f.md", "description": "F", "labels": []}],
    "directories": [{"path": "d/", "description": "D", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A" list --kind directories
  [[ "$output" != *"f.md"* ]]
  [[ "$output" == *"d/"* ]]
}

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

@test "remove directory: removes the matching entry" {
  write_config "$TMP_ROOT/A" '{"directories": [
    {"path": "keep/", "description": "K", "labels": []},
    {"path": "drop/", "description": "D", "labels": []}
  ]}'
  run_cli "$TMP_ROOT/A" remove directory "drop/" --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.directories | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}
