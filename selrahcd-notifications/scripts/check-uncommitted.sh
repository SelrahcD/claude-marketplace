#!/bin/bash

#==============================================================================
# Check for uncommitted changes at session end
# Sends a desktop notification if uncommitted changes are detected
#==============================================================================

set -euo pipefail

# Read SessionEnd JSON input from stdin
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // ""')

# Exit if no working directory or jq failed
if [ -z "$cwd" ] || [ "$cwd" = "null" ]; then
  exit 0
fi

cd "$cwd" 2>/dev/null || exit 0

# Exit if not a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# Check for uncommitted changes (staged, unstaged, or untracked)
has_changes=false
details=""

if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  has_changes=true
  details="modified files"
fi

untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
if [ -n "$untracked" ]; then
  has_changes=true
  if [ -n "$details" ]; then
    details="$details + untracked files"
  else
    details="untracked files"
  fi
fi

if [ "$has_changes" = false ]; then
  exit 0
fi

# Get repo name for the notification
repo_name=$(basename "$(git rev-parse --show-toplevel)")
message="Uncommitted changes in $repo_name ($details)"

# Send notification (macOS only for now, matching the notifier pattern)
case "$(uname -s)" in
  Darwin*)
    if command -v terminal-notifier >/dev/null 2>&1; then
      terminal-notifier -title "Claude Code" -message "$message" -sender claudecode.notifications -sound default
    fi
    ;;
  Linux*)
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "Claude Code" "$message" -i dialog-warning
    fi
    ;;
esac

# Also write to stderr so it appears in the terminal
echo "⚠️  $message" >&2
