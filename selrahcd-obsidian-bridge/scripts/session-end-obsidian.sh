#!/bin/bash
# session-end-obsidian.sh — SessionEnd hook for Obsidian Bridge plugin
#
# Reads hook JSON from stdin, triages the session,
# and launches a detached doc-writer agent to log to Obsidian.
#
# REQUIRES: jq, OBSIDIAN_VAULT_PATH env var, claude CLI, npx + Node >= 18

set -euo pipefail

# ─── Anti-loop guard ──────────────────────────────────────────────────────────
if [ "${CLAUDE_HOOK_SPAWNED:-}" = "1" ]; then
  exit 0
fi

# ─── Vault path check ────────────────────────────────────────────────────────
if [ -z "${OBSIDIAN_VAULT_PATH:-}" ]; then
  exit 0
fi

# ─── Config ───────────────────────────────────────────────────────────────────
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$HOME/.claude/obsidian-bridge-logs"
MIN_MESSAGES=5
AGENT_TIMEOUT=300

if command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout"
else
  TIMEOUT_CMD="timeout"
fi

mkdir -p "$LOGDIR"

# ─── Parse stdin ──────────────────────────────────────────────────────────────
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
WORKING_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$SESSION_ID" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR no session_id" >> "$LOGDIR/hook.log"
  exit 0
fi

# ─── Triage: skip short sessions ──────────────────────────────────────────────
USER_MSG_COUNT=0
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  USER_MSG_COUNT=$(grep -c '"type":"user"' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
fi

if [ "$USER_MSG_COUNT" -lt "$MIN_MESSAGES" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP session=$SESSION_ID msgs=$USER_MSG_COUNT" >> "$LOGDIR/hook.log"
  exit 0
fi

# ─── Find .obsidian-bridge.json ───────────────────────────────────────────────
CONFIG_FILE=""
CONFIG_CONTENT=""

if [ -n "$WORKING_DIR" ]; then
  if [ -f "$WORKING_DIR/.obsidian-bridge.json" ]; then
    CONFIG_FILE="$WORKING_DIR/.obsidian-bridge.json"
  else
    GIT_ROOT=$(git -C "$WORKING_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")
    if [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/.obsidian-bridge.json" ]; then
      CONFIG_FILE="$GIT_ROOT/.obsidian-bridge.json"
    fi
  fi
fi

if [ -n "$CONFIG_FILE" ]; then
  CONFIG_CONTENT=$(cat "$CONFIG_FILE")
fi

# ─── Wait for transcript finalization ─────────────────────────────────────────
sleep 0.5

# ─── Build the prompt ─────────────────────────────────────────────────────────
PROMPT="You are the obsidian-doc-writer agent running autonomously as a background hook.

Session transcript path: $TRANSCRIPT_PATH
Working directory: $WORKING_DIR
Obsidian vault path: $OBSIDIAN_VAULT_PATH
Date: $(date '+%Y-%m-%d')
Time: $(date '+%H:%M')

Project config (.obsidian-bridge.json):
$CONFIG_CONTENT

Read $PLUGIN_ROOT/agents/obsidian-doc-writer.md and execute all phases immediately. Never ask for confirmation."

# ─── Spawn doc-writer agent ──────────────────────────────────────────────────
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAUNCH session=$SESSION_ID msgs=$USER_MSG_COUNT dir=$WORKING_DIR" >> "$LOGDIR/hook.log"

nohup $TIMEOUT_CMD $AGENT_TIMEOUT env \
  -u CLAUDECODE -u CLAUDE_CODE_SSE_PORT -u CLAUDE_CODE_ENTRYPOINT \
  CLAUDE_HOOK_SPAWNED=1 \
  claude --print \
  --model haiku \
  --dangerously-skip-permissions \
  -p "$PROMPT" \
  > "$LOGDIR/doc-writer-${TIMESTAMP}.log" 2>&1 &

echo "[$(date '+%Y-%m-%d %H:%M:%S')] DETACHED pid=$! session=$SESSION_ID" >> "$LOGDIR/hook.log"
