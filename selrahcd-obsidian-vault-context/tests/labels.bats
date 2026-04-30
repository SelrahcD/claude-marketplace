#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "labels: empty when no configs" {
  run_cli "$TMP_ROOT/A" labels
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "labels: lists single config's labels" {
  write_config "$TMP_ROOT/A" '{
    "labels": {
      "marketplace": "Marketplace plugin work",
      "project": "Active project notes"
    }
  }'
  run_cli "$TMP_ROOT/A" labels
  [ "$status" -eq 0 ]
  expected="marketplace: Marketplace plugin work
project: Active project notes"
  [ "$output" = "$expected" ]
}

@test "labels: closest description wins on conflict" {
  write_global_config '{"labels": {"project": "Generic project"}}'
  write_config "$TMP_ROOT/A" '{"labels": {"project": "This specific project"}}'
  run_cli "$TMP_ROOT/A" labels
  [ "$status" -eq 0 ]
  [ "$output" = "project: This specific project" ]
}

@test "labels --show-source: includes source path" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "X desc"}}'
  run_cli "$TMP_ROOT/A" labels --show-source
  [ "$status" -eq 0 ]
  expected="x: X desc
  from: $TMP_ROOT/A/.obsidian-vault-context.json"
  [ "$output" = "$expected" ]
}

@test "labels --search: substring filter on label name and description" {
  write_config "$TMP_ROOT/A" '{
    "labels": {
      "marketplace": "Plugin marketplace work",
      "auth": "Authentication module"
    }
  }'
  run_cli "$TMP_ROOT/A" labels --search auth
  [ "$status" -eq 0 ]
  [ "$output" = "auth: Authentication module" ]
}

@test "labels --search: errors with clear message when no value follows" {
  run_cli "$TMP_ROOT/A" labels --search
  [ "$status" -eq 2 ]
  [ "$output" = "obsidian-context: labels: --search requires a value" ]
}

@test "label set: defines a new label" {
  mkdir -p "$TMP_ROOT/A"
  run_cli "$TMP_ROOT/A" label set marketplace "Marketplace plugin work" --scope current-directory
  [ "$status" -eq 0 ]
  expected='{
  "files": [],
  "directories": [],
  "labels": {
    "marketplace": "Marketplace plugin work"
  }
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "label set: refines an existing label (no --force needed)" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "old"}}'
  run_cli "$TMP_ROOT/A" label set x "new desc" --scope current-directory
  [ "$status" -eq 0 ]
  expected='{
  "labels": {
    "x": "new desc"
  }
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "label remove: removes the named label" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "X", "y": "Y"}}'
  run_cli "$TMP_ROOT/A" label remove x --scope current-directory
  [ "$status" -eq 0 ]
  expected='{
  "labels": {
    "y": "Y"
  }
}'
  [ "$(jq . "$TMP_ROOT/A/.obsidian-vault-context.json")" = "$expected" ]
}

@test "label remove: errors when label not found" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "X"}}'
  run_cli "$TMP_ROOT/A" label remove missing --scope current-directory
  [ "$status" -ne 0 ]
  [ "$output" = "obsidian-context: label remove: label missing not found in $TMP_ROOT/A/.obsidian-vault-context.json" ]
}
