# Atomic file writes for .obsidian-vault-context.json with mtime conflict detection.
#
# Functions:
#   write_atomic_json <target-file> <jq-program> [<jq-args>...]
#     Reads <target-file> if it exists (else uses null), pipes through jq with the
#     given program, writes to a tmp file, checks mtime didn't change, then renames.
#     Conflict (mtime changed) -> exit 1 with stderr message.

write_atomic_json() {
  local target="$1"; shift
  local jq_program="$1"; shift

  local input mtime_before mtime_after
  if [[ -f "$target" ]]; then
    mtime_before=$(stat -f '%m' "$target" 2>/dev/null || stat -c '%Y' "$target")
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
    mtime_after=$(stat -f '%m' "$target" 2>/dev/null || stat -c '%Y' "$target")
    if [[ "$mtime_before" != "$mtime_after" ]]; then
      rm -f "$tmp"
      printf 'obsidian-context: %s: file changed on disk; re-run\n' "$target" >&2
      return 1
    fi
  fi

  mv "$tmp" "$target"
}
