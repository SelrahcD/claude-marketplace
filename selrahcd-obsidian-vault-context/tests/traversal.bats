#!/usr/bin/env bats

load helpers

setup() { setup_tmp_root; }
teardown() { teardown_tmp_root; }

@test "CLI prints help when run with no args" {
  run "$CLI_BIN" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"obsidian-context"* ]]
  [[ "$output" == *"Usage:"* ]]
}
