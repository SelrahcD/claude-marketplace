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

@test "list --kind: errors with clear message when no value follows" {
  run_cli "$TMP_ROOT/A" list --kind
  [ "$status" -eq 2 ]
  [[ "$output" == *"--kind requires a value"* ]]
}

@test "list --label: errors with clear message when no value follows" {
  run_cli "$TMP_ROOT/A" list --label
  [ "$status" -eq 2 ]
  [[ "$output" == *"--label requires a value"* ]]
}

@test "list --search: errors with clear message when no value follows" {
  run_cli "$TMP_ROOT/A" list --search
  [ "$status" -eq 2 ]
  [[ "$output" == *"--search requires a value"* ]]
}

@test "add file: creates file with single entry when none exists" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file "Notes/X.md" --description "X note" --label foo --scope current-directory
  [ "$status" -eq 0 ]
  [ -f "$TMP_ROOT/A/.obsidian-vault-context.json" ]
  jq -e '.files | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].path == "Notes/X.md"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].description == "X note"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].labels == ["foo"]' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file: appends to existing files[]" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "old.md", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add file "new.md" --description "New" --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.files | length == 2' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file: duplicate path with same fields is a no-op (idempotent)" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "x.md", "description": "X", "labels": ["a"]}]}'
  run_cli "$TMP_ROOT/A" add file "x.md" --description "X" --label a --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.files | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file: duplicate path with different description fails without --force" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "x.md", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add file "x.md" --description "New" --scope current-directory
  [ "$status" -ne 0 ]
  [[ "$output" == *"--force"* ]] || [[ "$output" == *"already exists"* ]]
  jq -e '.files[0].description == "Old"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file --force: overwrites existing entry" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "x.md", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add file "x.md" --description "New" --label fresh --scope current-directory --force
  [ "$status" -eq 0 ]
  jq -e '.files | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].description == "New"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].labels == ["fresh"]' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "add file: errors without --description" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file "x.md" --scope current-directory
  [ "$status" -ne 0 ]
  [[ "$output" == *"--description"* ]]
}

@test "add file: works correctly when target file is 0 bytes" {
  mkdir -p "$TMP_ROOT/A"
  : > "$TMP_ROOT/A/.obsidian-vault-context.json"
  run_cli "$TMP_ROOT/A" add file "x.md" --description "X" --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.files | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].path == "x.md"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "remove file: removes the matching entry, leaves others" {
  write_config "$TMP_ROOT/A" '{"files": [
    {"path": "keep.md", "description": "K", "labels": []},
    {"path": "drop.md", "description": "D", "labels": []}
  ]}'
  run_cli "$TMP_ROOT/A" remove file "drop.md" --scope current-directory
  [ "$status" -eq 0 ]
  jq -e '.files | length == 1' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
  jq -e '.files[0].path == "keep.md"' "$TMP_ROOT/A/.obsidian-vault-context.json" >/dev/null
}

@test "remove file: errors when target file does not exist" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" remove file "x.md" --scope current-directory
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"does not exist"* ]]
}

@test "remove file: errors when entry not found in existing config" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "other.md", "description": "O", "labels": []}]}'
  run_cli "$TMP_ROOT/A" remove file "missing.md" --scope current-directory
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing.md"* ]]
}
