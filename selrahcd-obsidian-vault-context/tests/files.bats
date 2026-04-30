#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "list: empty when no configs exist" {
  run_cli "$TMP_ROOT/A" list
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "list: shows file entries from CWD config" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "Notes/X.md", "description": "X note", "labels": ["foo"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Notes/X.md"* ]]
  [[ "$output" == *"X note"* ]]
  [[ "$output" == *"foo"* ]]
  [[ "$output" == *"from:"*"A/.obsidian-vault-context.json"* ]]
}

@test "list: merges closest-first across levels with source attribution" {
  write_config "$TMP_ROOT/A" '{
    "files": [{"path": "far.md", "description": "Far", "labels": []}]
  }'
  write_config "$TMP_ROOT/A/B" '{
    "files": [{"path": "close.md", "description": "Close", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A/B" list

  [ "$status" -eq 0 ]
  close_line=$(echo "$output" | grep -n "close.md" | head -1 | cut -d: -f1)
  far_line=$(echo "$output" | grep -n "far.md" | head -1 | cut -d: -f1)
  [ -n "$close_line" ]
  [ -n "$far_line" ]
  [ "$close_line" -lt "$far_line" ]
}
