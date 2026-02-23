#!/bin/bash
# session-end-obsidian.sh — SessionEnd hook for Obsidian Bridge plugin
#
# Reads hook JSON from stdin, triages the session,
# and launches a detached doc-writer agent to log to Obsidian.
#
# REQUIRES: jq, OBSIDIAN_VAULT_PATH env var, claude CLI, npx + Node >= 18

set -euo pipefail

# ─── Early logging setup ────────────────────────────────────────────────────
LOGDIR="$HOME/.claude/obsidian-bridge-logs"
mkdir -p "$LOGDIR"
HOOKLOG="$LOGDIR/hook.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$HOOKLOG"
}

log "──── HOOK TRIGGERED ────"
log "DEBUG script=$0"
log "DEBUG PID=$$"
log "DEBUG CLAUDE_HOOK_SPAWNED=${CLAUDE_HOOK_SPAWNED:-<unset>}"
log "DEBUG OBSIDIAN_VAULT_PATH=${OBSIDIAN_VAULT_PATH:-<unset>}"

# ─── Anti-loop guard ──────────────────────────────────────────────────────────
if [ "${CLAUDE_HOOK_SPAWNED:-}" = "1" ]; then
  log "EXIT anti-loop guard: CLAUDE_HOOK_SPAWNED=1"
  exit 0
fi

# ─── Vault path check ────────────────────────────────────────────────────────
if [ -z "${OBSIDIAN_VAULT_PATH:-}" ]; then
  log "EXIT OBSIDIAN_VAULT_PATH is empty or unset"
  exit 0
fi

log "DEBUG vault path exists=$([ -d "$OBSIDIAN_VAULT_PATH" ] && echo yes || echo NO)"

# ─── Config ───────────────────────────────────────────────────────────────────
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MIN_MESSAGES=5
AGENT_TIMEOUT=300

log "DEBUG PLUGIN_ROOT=$PLUGIN_ROOT"
log "DEBUG agent file exists=$([ -f "$PLUGIN_ROOT/agents/obsidian-doc-writer.md" ] && echo yes || echo NO)"

if command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD="gtimeout"
  log "DEBUG using gtimeout"
elif command -v timeout &>/dev/null; then
  TIMEOUT_CMD="timeout"
  log "DEBUG using timeout"
else
  log "ERROR neither timeout nor gtimeout found in PATH"
  log "DEBUG PATH=$PATH"
fi

log "DEBUG claude CLI location=$(which claude 2>/dev/null || echo 'NOT FOUND')"
log "DEBUG jq location=$(which jq 2>/dev/null || echo 'NOT FOUND')"

# ─── Parse stdin ──────────────────────────────────────────────────────────────
INPUT=$(cat)
log "DEBUG raw stdin (first 500 chars): $(echo "$INPUT" | head -c 500)"
log "DEBUG stdin length: $(echo "$INPUT" | wc -c | tr -d ' ') bytes"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
WORKING_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')

log "DEBUG parsed session_id=$SESSION_ID"
log "DEBUG parsed transcript_path=$TRANSCRIPT_PATH"
log "DEBUG parsed cwd=$WORKING_DIR"

if [ -z "$SESSION_ID" ]; then
  log "EXIT no session_id in stdin payload"
  exit 0
fi

if [ -n "$TRANSCRIPT_PATH" ]; then
  log "DEBUG transcript file exists=$([ -f "$TRANSCRIPT_PATH" ] && echo yes || echo NO)"
  if [ -f "$TRANSCRIPT_PATH" ]; then
    log "DEBUG transcript file size=$(wc -c < "$TRANSCRIPT_PATH" | tr -d ' ') bytes"
  fi
else
  log "DEBUG transcript_path is empty"
fi

# ─── Triage: skip short sessions ──────────────────────────────────────────────
USER_MSG_COUNT=0
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  USER_MSG_COUNT=$(grep -c '"type":"user"' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
  log "DEBUG user message count=$USER_MSG_COUNT (min=$MIN_MESSAGES)"
else
  log "DEBUG cannot count messages: transcript_path empty or file missing"
fi

if [ "$USER_MSG_COUNT" -lt "$MIN_MESSAGES" ]; then
  log "SKIP session=$SESSION_ID msgs=$USER_MSG_COUNT (below threshold of $MIN_MESSAGES)"
  exit 0
fi

# ─── Find .claude/obsidian-bridge.json ────────────────────────────────────────
CONFIG_FILE=""
CONFIG_CONTENT=""

log "DEBUG searching for .claude/obsidian-bridge.json"
if [ -n "$WORKING_DIR" ]; then
  log "DEBUG checking $WORKING_DIR/.claude/obsidian-bridge.json"
  if [ -f "$WORKING_DIR/.claude/obsidian-bridge.json" ]; then
    CONFIG_FILE="$WORKING_DIR/.claude/obsidian-bridge.json"
    log "DEBUG found config at working dir"
  else
    log "DEBUG not found at working dir, checking git root"
    GIT_ROOT=$(git -C "$WORKING_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")
    log "DEBUG git root=$GIT_ROOT"
    if [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/.claude/obsidian-bridge.json" ]; then
      CONFIG_FILE="$GIT_ROOT/.claude/obsidian-bridge.json"
      log "DEBUG found config at git root"
    else
      log "DEBUG no config found at git root either"
    fi
  fi
else
  log "DEBUG WORKING_DIR is empty, skipping config search"
fi

if [ -n "$CONFIG_FILE" ]; then
  CONFIG_CONTENT=$(cat "$CONFIG_FILE")
  log "DEBUG config content: $CONFIG_CONTENT"
else
  log "DEBUG no .claude/obsidian-bridge.json found anywhere"
fi

# ─── Wait for transcript finalization ─────────────────────────────────────────
log "DEBUG waiting 0.5s for transcript finalization"
sleep 0.5

if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  log "DEBUG transcript size after wait=$(wc -c < "$TRANSCRIPT_PATH" | tr -d ' ') bytes"
fi

# ─── Build the prompt ─────────────────────────────────────────────────────────
PROMPT="You are the obsidian-doc-writer agent running autonomously as a background hook.

Session transcript path: $TRANSCRIPT_PATH
Working directory: $WORKING_DIR
Obsidian vault path: $OBSIDIAN_VAULT_PATH
Date: $(date '+%Y-%m-%d')
Time: $(date '+%H:%M')

Project config (.claude/obsidian-bridge.json):
$CONFIG_CONTENT

IMPORTANT DEBUG MODE: Before executing phases, log your progress by outputting lines prefixed with [DEBUG].
- [DEBUG] Starting Phase 1 - Triage
- [DEBUG] Transcript read: X bytes / Y user messages found
- [DEBUG] Triage decision: DOCUMENT or SKIP (with reason)
- [DEBUG] Starting Phase 2 - Daily Note
- [DEBUG] Daily note path: <path>
- [DEBUG] Daily note read result: success/not found/error
- [DEBUG] Daily note content length: X chars
- [DEBUG] Found 'What did I do?' section: yes/no (at line N)
- [DEBUG] Found tasks block closing backticks: yes/no (at line N)
- [DEBUG] Insertion point determined: line N
- [DEBUG] Entry to insert: <the entry text>
- [DEBUG] Daily note write result: success/error
- [DEBUG] Starting Phase 3 - Project Notes
- [DEBUG] Project notes to update: <list>
- [DEBUG] For each note: read result, insertion point, write result
- [DEBUG] All phases complete

Read $PLUGIN_ROOT/agents/obsidian-doc-writer.md and execute all phases immediately. Never ask for confirmation."

log "DEBUG prompt length=$(echo "$PROMPT" | wc -c | tr -d ' ') chars"

# ─── Spawn doc-writer agent ──────────────────────────────────────────────────
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
AGENT_LOG="$LOGDIR/doc-writer-${TIMESTAMP}.log"

log "LAUNCH session=$SESSION_ID msgs=$USER_MSG_COUNT dir=$WORKING_DIR"
log "DEBUG agent log file=$AGENT_LOG"
log "DEBUG command: $TIMEOUT_CMD $AGENT_TIMEOUT claude --print --model haiku --dangerously-skip-permissions -p <prompt>"

nohup $TIMEOUT_CMD $AGENT_TIMEOUT env \
  -u CLAUDECODE -u CLAUDE_CODE_SSE_PORT -u CLAUDE_CODE_ENTRYPOINT \
  CLAUDE_HOOK_SPAWNED=1 \
  claude --print \
  --model haiku \
  --dangerously-skip-permissions \
  -p "$PROMPT" \
  > "$AGENT_LOG" 2>&1 &

AGENT_PID=$!
log "DETACHED pid=$AGENT_PID session=$SESSION_ID logfile=$AGENT_LOG"
log "DEBUG check agent output with: tail -f $AGENT_LOG"
