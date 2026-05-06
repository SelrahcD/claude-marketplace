#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "add file --help: shows file-specific usage and exits 0" {
  run_cli "$TMP_ROOT" add file --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add file"* ]]
  [[ "$output" == *"--description"* ]]
  [[ "$output" == *"--label"* ]]
  [[ "$output" == *"--scope"* ]]
  [[ "$output" == *"--force"* ]]
}

@test "add directory --help: shows directory-specific usage and exits 0" {
  run_cli "$TMP_ROOT" add directory --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add directory"* ]]
  [[ "$output" == *"--description"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "add --help (no kind): shows combined usage" {
  run_cli "$TMP_ROOT" add --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add file"* ]]
  [[ "$output" == *"add directory"* ]]
  [[ "$output" == *"--description"* ]]
}

@test "add file --help: --help wins even after positional vault-path" {
  run_cli "$TMP_ROOT" add file foo.md --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add file"* ]]
  [[ "$output" == *"--description"* ]]
}

@test "remove file --help: shows usage and exits 0" {
  run_cli "$TMP_ROOT" remove file --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"remove file"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "remove directory --help: shows usage and exits 0" {
  run_cli "$TMP_ROOT" remove directory --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"remove directory"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "remove --help (no kind): shows combined usage" {
  run_cli "$TMP_ROOT" remove --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"remove file"* ]]
  [[ "$output" == *"remove directory"* ]]
}

@test "label set --help: shows usage and exits 0" {
  run_cli "$TMP_ROOT" label set --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"label set"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "label remove --help: shows usage and exits 0" {
  run_cli "$TMP_ROOT" label remove --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"label remove"* ]]
  [[ "$output" == *"--scope"* ]]
}

@test "label --help (no action): shows combined usage" {
  run_cli "$TMP_ROOT" label --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"label set"* ]]
  [[ "$output" == *"label remove"* ]]
}

@test "list --help still works (regression check)" {
  run_cli "$TMP_ROOT" list --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"list"* ]]
  [[ "$output" == *"--label"* ]]
}

@test "labels --help still works (regression check)" {
  run_cli "$TMP_ROOT" labels --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"labels"* ]]
}
