# Scope resolution: convert a --scope value into a target file path.
#
# Functions:
#   scope_resolve <scope-value> <effective-cwd>
#     Prints the target file path on stdout.
#     Exits non-zero with a stderr message on errors.
#
# Scope values:
#   local              -> closest existing .obsidian-vault-context.json at or above cwd
#   current-directory  -> <cwd>/.obsidian-vault-context.json (created on demand by caller)
#   global             -> $HOME/.obsidian-vault-context.json (created on demand by caller)
#   <path>             -> <path>/.obsidian-vault-context.json. <path> must be an existing directory.

scope_resolve() {
  local scope="$1"
  local cwd="$2"

  case "$scope" in
    local)
      local dir
      dir="$(cd "$cwd" 2>/dev/null && pwd -P)" || {
        printf 'obsidian-context: --scope local: --cwd directory does not exist\n' >&2
        return 1
      }
      while :; do
        if [[ -f "$dir/.obsidian-vault-context.json" ]]; then
          printf '%s\n' "$dir/.obsidian-vault-context.json"
          return 0
        fi
        if [[ "$dir" == "/" ]]; then
          break
        fi
        dir="$(dirname "$dir")"
      done
      printf 'obsidian-context: no existing .obsidian-vault-context.json found at or above %s\n' "$cwd" >&2
      printf 'use --scope current-directory to create one here, or --scope <dir>\n' >&2
      return 1
      ;;
    current-directory)
      local dir
      dir="$(cd "$cwd" 2>/dev/null && pwd -P)" || {
        printf 'obsidian-context: --scope current-directory: --cwd directory does not exist\n' >&2
        return 1
      }
      printf '%s\n' "$dir/.obsidian-vault-context.json"
      ;;
    global)
      printf '%s\n' "$HOME/.obsidian-vault-context.json"
      ;;
    *)
      local resolved
      # Resolve relative paths against $cwd, not the process $PWD.
      resolved="$(cd "$cwd" 2>/dev/null && cd "$scope" 2>/dev/null && pwd -P)" || {
        printf 'obsidian-context: --scope: directory does not exist: %s\n' "$scope" >&2
        return 1
      }
      printf '%s\n' "$resolved/.obsidian-vault-context.json"
      ;;
  esac
}
