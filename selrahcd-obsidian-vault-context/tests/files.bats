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
  expected="Notes/X.md  [foo]  X note
  from: $TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
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
  expected="close.md  []  Close
  from: $TMP_ROOT/A/B/.obsidian-vault-context.json
far.md  []  Far
  from: $TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
}

@test "list --kind files: shows only file entries" {
  write_config "$TMP_ROOT/A" '{
    "files": [{"path": "f.md", "description": "F", "labels": []}],
    "directories": [{"path": "d/", "description": "D", "labels": []}]
  }'
  run_cli "$TMP_ROOT/A" list --kind files
  expected="f.md  []  F
  from: $TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
}

@test "list --label foo: shows only entries with that label" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "x.md", "description": "X", "labels": ["foo"]},
      {"path": "y.md", "description": "Y", "labels": ["bar"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --label foo
  expected="x.md  [foo]  X
  from: $TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
}

@test "list --label foo --label bar: AND semantics by default" {
  write_config "$TMP_ROOT/A" '{
    "files": [
      {"path": "both.md", "description": "B", "labels": ["foo", "bar"]},
      {"path": "foo.md", "description": "F", "labels": ["foo"]}
    ]
  }'
  run_cli "$TMP_ROOT/A" list --label foo --label bar
  expected="both.md  [foo, bar]  B
  from: $TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
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
  expected="foo.md  [foo]  F
  from: $TMP_ROOT/A/.obsidian-vault-context.json
bar.md  [bar]  B
  from: $TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
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
  expected="Auth/refactor.md  []  Stuff
  from: $TMP_ROOT/A/.obsidian-vault-context.json
Other/x.md  []  About authentication
  from: $TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
}

@test "list --kind: errors with clear message when no value follows" {
  run_cli "$TMP_ROOT/A" list --kind
  [ "$status" -eq 2 ]
  [ "$output" = "obsidian-context: list: --kind requires a value" ]
}

@test "list --label: errors with clear message when no value follows" {
  run_cli "$TMP_ROOT/A" list --label
  [ "$status" -eq 2 ]
  [ "$output" = "obsidian-context: list: --label requires a value" ]
}

@test "list --search: errors with clear message when no value follows" {
  run_cli "$TMP_ROOT/A" list --search
  [ "$status" -eq 2 ]
  [ "$output" = "obsidian-context: list: --search requires a value" ]
}

@test "add file: creates file with single entry when none exists" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file "Notes/X.md" --description "X note" --label foo --scope current-directory
  [ "$status" -eq 0 ]
  [ -f "$TMP_ROOT/A/.obsidian-vault-context.json" ]
  expected='{
  "files": [
    {
      "path": "Notes/X.md",
      "description": "X note",
      "labels": [
        "foo"
      ]
    }
  ],
  "directories": [],
  "labels": {}
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "add file: appends to existing files[]" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "old.md", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add file "new.md" --description "New" --scope current-directory
  [ "$status" -eq 0 ]
  expected='{
  "files": [
    {
      "path": "old.md",
      "description": "Old",
      "labels": []
    },
    {
      "path": "new.md",
      "description": "New",
      "labels": []
    }
  ]
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "add file: duplicate path with same fields is a no-op (idempotent)" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "x.md", "description": "X", "labels": ["a"]}]}'
  run_cli "$TMP_ROOT/A" add file "x.md" --description "X" --label a --scope current-directory
  [ "$status" -eq 0 ]
  expected='{
  "files": [
    {
      "path": "x.md",
      "description": "X",
      "labels": [
        "a"
      ]
    }
  ]
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "add file: duplicate path with different description fails without --force" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "x.md", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add file "x.md" --description "New" --scope current-directory
  [ "$status" -ne 0 ]
  expected="jq: error (at <stdin>:0): CONFLICT
obsidian-context: write: jq transform failed
obsidian-context: add file: entry x.md already exists with different fields; use --force to overwrite"
  [ "$output" = "$expected" ]
  [ "$(jq -r '.files[0].description' "$TMP_ROOT/A/.obsidian-vault-context.json")" = "Old" ]
}

@test "add file --force: overwrites existing entry" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "x.md", "description": "Old", "labels": []}]}'
  run_cli "$TMP_ROOT/A" add file "x.md" --description "New" --label fresh --scope current-directory --force
  [ "$status" -eq 0 ]
  expected='{
  "files": [
    {
      "path": "x.md",
      "description": "New",
      "labels": [
        "fresh"
      ]
    }
  ]
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "add file: errors without --description" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" add file "x.md" --scope current-directory
  [ "$status" -ne 0 ]
  [ "$output" = "obsidian-context: add file: --description is required" ]
}

@test "add file: works correctly when target file is 0 bytes" {
  mkdir -p "$TMP_ROOT/A"
  : > "$TMP_ROOT/A/.obsidian-vault-context.json"
  run_cli "$TMP_ROOT/A" add file "x.md" --description "X" --scope current-directory
  [ "$status" -eq 0 ]
  expected='{
  "files": [
    {
      "path": "x.md",
      "description": "X",
      "labels": []
    }
  ],
  "directories": [],
  "labels": {}
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "remove file: removes the matching entry, leaves others" {
  write_config "$TMP_ROOT/A" '{"files": [
    {"path": "keep.md", "description": "K", "labels": []},
    {"path": "drop.md", "description": "D", "labels": []}
  ]}'
  run_cli "$TMP_ROOT/A" remove file "drop.md" --scope current-directory
  [ "$status" -eq 0 ]
  expected='{
  "files": [
    {
      "path": "keep.md",
      "description": "K",
      "labels": []
    }
  ]
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "remove file: errors when target file does not exist" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" remove file "x.md" --scope current-directory
  [ "$status" -ne 0 ]
  [ "$output" = "obsidian-context: remove file: target file does not exist: $TMP_ROOT/A/.obsidian-vault-context.json" ]
}

@test "remove file: errors when entry not found in existing config" {
  write_config "$TMP_ROOT/A" '{"files": [{"path": "other.md", "description": "O", "labels": []}]}'
  run_cli "$TMP_ROOT/A" remove file "missing.md" --scope current-directory
  [ "$status" -ne 0 ]
  [ "$output" = "obsidian-context: remove file: entry missing.md not found in $TMP_ROOT/A/.obsidian-vault-context.json" ]
}
