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
  [[ "$output" == *"marketplace"* ]]
  [[ "$output" == *"Marketplace plugin work"* ]]
  [[ "$output" == *"project"* ]]
}

@test "labels: closest description wins on conflict" {
  write_global_config '{"labels": {"project": "Generic project"}}'
  write_config "$TMP_ROOT/A" '{"labels": {"project": "This specific project"}}'
  run_cli "$TMP_ROOT/A" labels
  [ "$status" -eq 0 ]
  [[ "$output" == *"This specific project"* ]]
  [[ "$output" != *"Generic project"* ]]
}

@test "labels --show-source: includes source path" {
  write_config "$TMP_ROOT/A" '{"labels": {"x": "X desc"}}'
  run_cli "$TMP_ROOT/A" labels --show-source
  [ "$status" -eq 0 ]
  [[ "$output" == *"x: X desc"* ]]
  [[ "$output" == *"from:"*"A/.obsidian-vault-context.json"* ]]
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
  [[ "$output" == *"auth"* ]]
  [[ "$output" != *"marketplace"* ]]
}

@test "labels --search: errors with clear message when no value follows" {
  run_cli "$TMP_ROOT/A" labels --search
  [ "$status" -eq 2 ]
  [[ "$output" == *"--search requires a value"* ]]
}
