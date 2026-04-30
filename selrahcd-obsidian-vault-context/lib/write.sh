# Atomic file writes for .obsidian-vault-context.json with mtime conflict detection.
#
# Functions:
#   write_atomic_json <target-file> <jq-program> [<jq-args>...]
#     Reads <target-file> if it exists (else uses null), pipes through jq with the
#     given program, writes to a tmp file, checks mtime didn't change, then renames.
#     Conflict (mtime changed) -> exit 1 with stderr message.

# Print the mtime of <file> as a Unix timestamp.
# stat(1) syntax differs between BSD (macOS) and GNU (Linux); detect once per call.
_write_mtime() {
  local file="$1"
  if [[ "$(uname)" == "Darwin" ]]; then
    stat -f '%m' "$file"
  else
    stat -c '%Y' "$file"
  fi
}

write_atomic_json() {
  local target="$1"; shift
  local jq_program="$1"; shift

  local input mtime_before mtime_after
  if [[ -f "$target" ]]; then
    mtime_before=$(_write_mtime "$target")
    input=$(cat "$target")
    if [[ -z "$input" ]]; then
      # 0-byte existing file: treat as null, like missing file.
      input="null"
    fi
  else
    mtime_before=""
    input="null"
  fi

  local tmp="$target.tmp.$$"
  if ! printf '%s' "$input" | jq "$@" "$jq_program" > "$tmp"; then
    rm -f "$tmp"
    printf 'obsidian-context: write: jq transform failed\n' >&2
    return 1
  fi

  if [[ -f "$target" ]]; then
    mtime_after=$(_write_mtime "$target")
    if [[ "$mtime_before" != "$mtime_after" ]]; then
      rm -f "$tmp"
      printf 'obsidian-context: %s: file changed on disk; re-run\n' "$target" >&2
      return 1
    fi
  fi

  mv "$tmp" "$target"
}
