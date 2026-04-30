# Helpers for bats tests of obsidian-context.

# Resolve once: absolute path to the CLI under test.
CLI_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/obsidian-context"

# setup_tmp_root creates an isolated tmpdir for a test, with a fake $HOME inside.
# Sets globals: TMP_ROOT, FAKE_HOME.
setup_tmp_root() {
  TMP_ROOT="$(mktemp -d)"
  TMP_ROOT="$(cd "$TMP_ROOT" && pwd -P)"
  FAKE_HOME="$TMP_ROOT/home"
  mkdir -p "$FAKE_HOME"
  export HOME="$FAKE_HOME"
}

teardown_tmp_root() {
  if [[ -n "${TMP_ROOT:-}" && -d "$TMP_ROOT" ]]; then
    rm -rf "$TMP_ROOT"
  fi
}

# write_config <abs-dir> <json-content>
# Creates the directory and writes .obsidian-vault-context.json into it.
write_config() {
  local dir="$1"
  local content="$2"
  mkdir -p "$dir"
  printf '%s\n' "$content" > "$dir/.obsidian-vault-context.json"
}

# write_global_config <json-content>
# Writes ~/.obsidian-vault-context.json (using the fake $HOME).
write_global_config() {
  local content="$1"
  printf '%s\n' "$content" > "$HOME/.obsidian-vault-context.json"
}

# run_cli <cwd> [args...]
# Invokes the CLI with --cwd <cwd>, appending args.
# Captures stdout in $output, exit code in $status (bats convention via `run`).
run_cli() {
  local cwd="$1"
  shift
  run "$CLI_BIN" --cwd "$cwd" "$@"
}
