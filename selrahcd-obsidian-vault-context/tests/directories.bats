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
