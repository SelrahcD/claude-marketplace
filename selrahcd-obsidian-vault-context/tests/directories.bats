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
