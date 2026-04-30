# Output formatters for entries and labels.
#
# Functions:
#   output_entries_human <merged-json> <show-source>
#     Reads the merged JSON, prints one line per entry:
#       <path>  [<labels>]  <description>
#     When show-source = "1", also prints:
#       from: <source>
#     Both files and directories are printed.
#
#   output_entries_json <merged-json>
#     Re-emits files+directories with source preserved.
#
#   output_labels_human <merged-json> <show-source>
#     show-source = "0" or "1".
#
#   output_labels_json <merged-json>

output_entries_human() {
  local merged="$1"
  local show_source="$2"
  if [[ "$show_source" == "1" ]]; then
    jq -r '
      ((.files // []) + (.directories // []))
      | .[]
      | "\(.path)  [\((.labels // []) | join(", "))]  \(.description)\n  from: \(.source)"
    ' <<<"$merged"
  else
    jq -r '
      ((.files // []) + (.directories // []))
      | .[]
      | "\(.path)  [\((.labels // []) | join(", "))]  \(.description)"
    ' <<<"$merged"
  fi
}

output_entries_json() {
  local merged="$1"
  jq '{files: (.files // []), directories: (.directories // [])}' <<<"$merged"
}

output_labels_human() {
  local merged="$1"
  local show_source="$2"
  if [[ "$show_source" == "1" ]]; then
    jq -r '
      .labels // {}
      | to_entries
      | .[]
      | "\(.key): \(.value.description)\n  from: \(.value.source)"
    ' <<<"$merged"
  else
    jq -r '
      .labels // {}
      | to_entries
      | .[]
      | "\(.key): \(.value.description)"
    ' <<<"$merged"
  fi
}

output_labels_json() {
  local merged="$1"
  jq '.labels // {}' <<<"$merged"
}
