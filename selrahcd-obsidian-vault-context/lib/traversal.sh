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

  # Canonicalize $HOME so we can detect it on the walk path even when symlinks
  # (e.g., /var -> /private/var on macOS) make a literal string compare miss.
  local canonical_home=""
  if [[ -d "$HOME" ]]; then
    canonical_home="$(cd "$HOME" 2>/dev/null && pwd -P)" || canonical_home=""
  fi

  # Track whether we already emitted the global config during the walk so we
  # don't double-list it.
  local emitted_global=0

  while :; do
    local candidate="$dir/.obsidian-vault-context.json"
    if [[ -f "$candidate" ]]; then
      if [[ -n "$canonical_home" && "$dir" == "$canonical_home" ]]; then
        # Walk hit $HOME — emit the global config in its $HOME-prefixed form
        # for consistency with the post-walk append branch.
        printf '%s\n' "$HOME/.obsidian-vault-context.json"
        emitted_global=1
      else
        printf '%s\n' "$candidate"
      fi
    fi
    if [[ "$dir" == "/" ]]; then
      break
    fi
    dir="$(dirname "$dir")"
  done

  if (( emitted_global == 0 )); then
    local global="$HOME/.obsidian-vault-context.json"
    if [[ -f "$global" ]]; then
      printf '%s\n' "$global"
    fi
  fi
}
