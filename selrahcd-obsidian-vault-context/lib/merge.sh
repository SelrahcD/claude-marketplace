# Merge: collect entries from multiple config files, inject source attribution.
#
# Functions:
#   merge_collections <file1> [file2 ...]
#     Reads each file (assumed already schema-validated), emits a single JSON
#     object: { "files": [...], "directories": [...], "labels": {...} }.
#     Each entry in files[] and directories[] gets a "source" field set to the
#     absolute path of the config it came from.
#     Concatenation is in argument order (callers pass closest-first).
#     For labels, closest-wins (first definition seen wins).

merge_collections() {
  local files=("$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    printf '{"files":[],"directories":[],"labels":{}}\n'
    return 0
  fi

  # jq slurps each file's content with its source path attached.
  # We use --slurpfile per file to preserve filename association via a parallel array.
  local jq_args=()
  local i=0
  for f in "${files[@]}"; do
    jq_args+=(--arg "src$i" "$f")
    jq_args+=(--slurpfile "data$i" "$f")
    i=$((i + 1))
  done

  # Build a jq program that processes each file in order.
  local jq_program='
    def attach_source($src):
      map(. + {"source": $src});

    # Start with empty.
    {files: [], directories: [], labels: {}}
  '

  i=0
  for f in "${files[@]}"; do
    jq_program+="
    | (.files += ((\$data${i}[0].files // []) | attach_source(\$src${i})))
    | (.directories += ((\$data${i}[0].directories // []) | attach_source(\$src${i})))
    | (.labels = (((\$data${i}[0].labels // {}) | with_entries(.value = {description: .value, source: \$src${i}})) + .labels))
    "
    i=$((i + 1))
  done

  jq -n "${jq_args[@]}" "$jq_program"
}
