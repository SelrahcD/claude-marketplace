# Traversal: find all .obsidian-vault-context.json files closest-first.
#
# Functions:
#   traversal_collect <cwd> -> prints absolute paths, one per line, closest-first.
#                              Walks <cwd> up to /, then appends $HOME/.obsidian-vault-context.json
#                              if it exists.

traversal_collect() {
  local cwd="$1"
  local dir
  dir="$(cd "$cwd" 2>/dev/null && pwd -P)" || {
    # Directory does not exist — no configs to find; treat as empty result.
    return 0
  }

  while :; do
    local candidate="$dir/.obsidian-vault-context.json"
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
    fi
    if [[ "$dir" == "/" ]]; then
      break
    fi
    dir="$(dirname "$dir")"
  done

  local global="$HOME/.obsidian-vault-context.json"
  if [[ -f "$global" ]]; then
    printf '%s\n' "$global"
  fi
}
