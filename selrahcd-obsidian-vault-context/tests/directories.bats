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
  expected="Projects/  [root]  All projects"
  [ "$output" = "$expected" ]
}

@test "list --kind directories: shows only directory entries" {
  write_config "$TMP_ROOT/A" '{
    "files": [{"path": "f.md", "description": "F", "labels": []}],
    "directories": [{"path": "d/", "description": "D", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A" list --kind directories
  expected="d/  []  D"
  [ "$output" = "$expected" ]
}

@test "add directory: creates entry in directories[]" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add directory "Projects/" --description "All projects" --label root --scope current-directory
  [ "$status" -eq 0 ]
  expected='{
  "files": [],
  "directories": [
    {
      "path": "Projects/",
      "description": "All projects",
      "labels": [
        "root"
      ]
    }
  ],
  "labels": {}
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "add directory: --force overwrites existing entry" {
  write_config "$TMP_ROOT/A" '{"directories": [{"path": "P/", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add directory "P/" --description "New" --scope current-directory --force
  [ "$status" -eq 0 ]
  expected='{
  "directories": [
    {
      "path": "P/",
      "description": "New",
      "labels": []
    }
  ]
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "list --show-source: includes source line under each directory entry" {
  write_config "$TMP_ROOT/A" '{
    "directories": [{"path": "Projects/", "description": "All projects", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A" list --show-source
  [ "$status" -eq 0 ]
  expected="Projects/  []  All projects
  from: $TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
}

@test "remove directory: removes the matching entry" {
  write_config "$TMP_ROOT/A" '{"directories": [
    {"path": "keep/", "description": "K", "labels": []},
    {"path": "drop/", "description": "D", "labels": []}
  ]}'
  run_cli "$TMP_ROOT/A" remove directory "drop/" --scope current-directory
  [ "$status" -eq 0 ]
  expected='{
  "directories": [
    {
      "path": "keep/",
      "description": "K",
      "labels": []
    }
  ]
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}
