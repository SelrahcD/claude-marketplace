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

@test "list --kind files: shows only file entries" {
  write_config "$TMP_ROOT/A" '{
    "files": [{"path": "f.md", "description": "F", "labels": []}],
    "directories": [{"path": "d/", "description": "D", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A" list --kind files
  [[ "$output" == *"f.md"* ]]
  [[ "$output" != *"d/"* ]]
}

@test "list --label foo: shows only entries with that label" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "x.md", "description": "X", "labels": ["foo"]},
      {"path": "y.md", "description": "Y", "labels": ["bar"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --label foo
  [[ "$output" == *"x.md"* ]]
  [[ "$output" != *"y.md"* ]]
}

@test "list --label foo --label bar: AND semantics by default" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "both.md", "description": "B", "labels": ["foo", "bar"]},
      {"path": "foo.md", "description": "F", "labels": ["foo"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --label foo --label bar
  [[ "$output" == *"both.md"* ]]
  [[ "$output" != *"foo.md"* ]]
}

@test "list --label foo --label bar --any: OR semantics with --any" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "foo.md", "description": "F", "labels": ["foo"]},
      {"path": "bar.md", "description": "B", "labels": ["bar"]},
      {"path": "neither.md", "description": "N", "labels": []}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --label foo --label bar --any
  [[ "$output" == *"foo.md"* ]]
  [[ "$output" == *"bar.md"* ]]
  [[ "$output" != *"neither.md"* ]]
}

@test "list --search auth: substring match on path or description, case-insensitive" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "Auth/refactor.md", "description": "Stuff", "labels": []},
      {"path": "Other/x.md", "description": "About authentication", "labels": []},
      {"path": "Other/y.md", "description": "Unrelated", "labels": []}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --search auth
  [[ "$output" == *"Auth/refactor.md"* ]]
  [[ "$output" == *"Other/x.md"* ]]
  [[ "$output" != *"Other/y.md"* ]]
}
