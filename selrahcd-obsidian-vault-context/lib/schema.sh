# Schema validation for .obsidian-vault-context.json files.
#
# Functions:
#   schema_validate_file <abs-path>
#     Exit 0 on valid; exit 1 + stderr message on malformed JSON or malformed entries.
#     Emits soft warnings to stderr for unknown top-level keys.

# Recognized top-level keys owned by this plugin (single source of truth —
# extend this list when new top-level keys are introduced).
SCHEMA_KNOWN_TOP_LEVEL=(files directories labels)

schema_validate_file() {
  local file="$1"

  # First: is it valid JSON at all?
  if ! jq empty "$file" 2>/dev/null; then
    printf 'obsidian-context: malformed JSON in %s\n' "$file" >&2
    return 1
  fi

  # Soft warn for unknown top-level keys.
  local known_filter
  known_filter=$(printf '%s\n' "${SCHEMA_KNOWN_TOP_LEVEL[@]}" | jq -R . | jq -sc .)
  local unknown
  unknown=$(jq -r --argjson known "$known_filter" \
    '(keys // []) - $known | .[]' "$file")
  if [[ -n "$unknown" ]]; then
    while IFS= read -r key; do
      printf 'obsidian-context: warning: unknown top-level key %q in %s\n' "$key" "$file" >&2
    done <<<"$unknown"
  fi

  # Validate files[] and directories[] entry shapes.
  local kind
  for kind in files directories; do
    local missing_path
    missing_path=$(jq -r --arg k "$kind" \
      '.[$k] // [] | map(select(.path == null or .path == "")) | length' "$file")
    if [[ "$missing_path" -gt 0 ]]; then
      printf 'obsidian-context: %s: an entry in %s is missing required field "path"\n' "$file" "$kind" >&2
      return 1
    fi

    local missing_desc
    missing_desc=$(jq -r --arg k "$kind" \
      '.[$k] // [] | map(select(.description == null or .description == "")) | length' "$file")
    if [[ "$missing_desc" -gt 0 ]]; then
      printf 'obsidian-context: %s: an entry in %s is missing required field "description"\n' "$file" "$kind" >&2
      return 1
    fi

    local bad_labels
    bad_labels=$(jq -r --arg k "$kind" \
      '.[$k] // [] | map(select(.labels != null and (.labels | type) != "array")) | length' "$file")
    if [[ "$bad_labels" -gt 0 ]]; then
      printf 'obsidian-context: %s: an entry in %s has non-array "labels"\n' "$file" "$kind" >&2
      return 1
    fi
  done

  # Validate labels{} is an object of name->string when present.
  if jq -e '.labels // empty | type != "object"' "$file" >/dev/null 2>&1; then
    printf 'obsidian-context: %s: top-level "labels" must be an object\n' "$file" >&2
    return 1
  fi

  return 0
}
