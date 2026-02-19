# Obsidian Bridge Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a Claude Code plugin that auto-documents sessions to an Obsidian vault via a SessionEnd hook and a spawned doc-writer agent using MCP obsidian.

**Architecture:** A SessionEnd hook shell script spawns a detached `claude --print --model haiku` process with `--mcp-config` pointing to `@mauricio.wolff/mcp-obsidian` and `--strict-mcp-config`. The spawned agent reads the transcript, triages it, and writes summaries to the daily note and optional project notes in the Obsidian vault.

**Tech Stack:** Bash (hook script), Markdown (agent definition), `@mauricio.wolff/mcp-obsidian` (vault access), `jq` (JSON parsing)

**Design doc:** `docs/plans/2026-02-19-obsidian-bridge-design.md`

---

### Task 1: Scaffold the plugin directory and plugin.json

**Files:**
- Create: `selrahcd-obsidian-bridge/.claude-plugin/plugin.json`

**Step 1: Create plugin.json**

```json
{
  "name": "obsidian-bridge",
  "version": "1.0.0",
  "description": "Auto-document Claude sessions to an Obsidian vault via SessionEnd hook",
  "author": {
    "name": "Selrahcd",
    "url": "https://github.com/SelrahcD"
  },
  "repository": "https://github.com/SelrahcD/claude-marketplace",
  "license": "MIT",
  "keywords": ["obsidian", "documentation", "hooks", "session-log"]
}
```

No `hooks`, `agents`, `commands`, or `skills` paths — they are auto-discovered from default locations.

**Step 2: Commit**

```bash
git add selrahcd-obsidian-bridge/.claude-plugin/plugin.json
git commit -m "feat(obsidian-bridge): scaffold plugin with plugin.json"
```

---

### Task 2: Create the hooks.json for SessionEnd

**Files:**
- Create: `selrahcd-obsidian-bridge/hooks/hooks.json`

**Reference:** The existing `selrahcd-notifications/hooks/hooks.json` for the hook format. The hook type for session end is `SessionEnd` (check Claude Code docs if needed — the reference repo uses this in `~/.claude/settings.json`).

**Step 1: Create hooks.json**

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/session-end-obsidian.sh"
          }
        ]
      }
    ]
  }
}
```

Uses `${CLAUDE_PLUGIN_ROOT}` so the path resolves regardless of where the marketplace is installed.

**Step 2: Commit**

```bash
git add selrahcd-obsidian-bridge/hooks/hooks.json
git commit -m "feat(obsidian-bridge): add SessionEnd hook registration"
```

---

### Task 3: Write the session-end shell script

**Files:**
- Create: `selrahcd-obsidian-bridge/scripts/session-end-obsidian.sh`

**Context:** This script is fired by the SessionEnd hook. It reads JSON from stdin, applies guards, finds the project config, and spawns the doc-writer agent. Study `KnutFr/HomeAIPublic/scripts/session-end-runner.sh` (fetched during design) for the spawning pattern.

**Step 1: Write the script**

```bash
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

Read the transcript at the path above, then follow your agent instructions to triage and document this session. Never ask for confirmation."

# ─── MCP config ───────────────────────────────────────────────────────────────
MCP_CONFIG="{\"obsidian\":{\"command\":\"npx\",\"args\":[\"@mauricio.wolff/mcp-obsidian@latest\",\"$OBSIDIAN_VAULT_PATH\"]}}"

# ─── Spawn doc-writer agent ──────────────────────────────────────────────────
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAUNCH session=$SESSION_ID msgs=$USER_MSG_COUNT dir=$WORKING_DIR" >> "$LOGDIR/hook.log"

nohup $TIMEOUT_CMD $AGENT_TIMEOUT env \
  -u CLAUDECODE -u CLAUDE_CODE_SSE_PORT -u CLAUDE_CODE_ENTRYPOINT \
  CLAUDE_HOOK_SPAWNED=1 \
  claude --print \
  --model haiku \
  --mcp-config "$MCP_CONFIG" \
  --strict-mcp-config \
  --dangerously-skip-permissions \
  -p "$PROMPT" \
  > "$LOGDIR/doc-writer-${TIMESTAMP}.log" 2>&1 &

echo "[$(date '+%Y-%m-%d %H:%M:%S')] DETACHED pid=$! session=$SESSION_ID" >> "$LOGDIR/hook.log"
```

**Step 2: Make it executable**

```bash
chmod +x selrahcd-obsidian-bridge/scripts/session-end-obsidian.sh
```

**Step 3: Commit**

```bash
git add selrahcd-obsidian-bridge/scripts/session-end-obsidian.sh
git commit -m "feat(obsidian-bridge): add session-end hook script"
```

---

### Task 4: Write the obsidian-doc-writer agent

**Files:**
- Create: `selrahcd-obsidian-bridge/agents/obsidian-doc-writer.md`

**Context:** This agent runs as a detached `claude --print` process. It receives the transcript path, vault path, and project config via the prompt. It uses the MCP obsidian tools (`read_note`, `write_note`) to read/update vault notes. Study `KnutFr/HomeAIPublic/agents/doc-writer.md` for the agent format (YAML frontmatter with mode, permissions, tools).

**Important details:**
- The daily note path pattern is `🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md`
- The agent must find the "What did I do?" section and insert AFTER the tasks code block (` ```tasks ... ``` `) that follows it
- Since MCP obsidian only has overwrite/append/prepend modes, the agent must `read_note`, manipulate the content string to insert at the right position, then `write_note` with overwrite
- Tags from the config's `tags` array get prefixed with `#` in the output
- Use `[[wiki-links]]` for Obsidian cross-referencing

**Step 1: Write the agent file**

The agent should have this structure:
- YAML frontmatter: name, description, tools (read_note, write_note, search_notes from MCP)
- Autonomous execution mode warning (no user interaction)
- Security: never include secrets from transcript
- Phase 1: Triage — read transcript, decide if worth documenting
- Phase 2: Daily note — read note via MCP, find "What did I do?" section, insert after tasks block, overwrite
- Phase 3: Project notes — if config has `notes` array, append dated entry to each

**Daily note insertion format:**
```markdown
### Claude session — Brief descriptive title
- What was accomplished #tag1 #tag2
- Key details with [[wiki-links]]
  - Sub-details as needed
```

**Project note append format:**
```markdown
- **YYYY-MM-DD**: Brief summary — see [[🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD]]
```

**Anti-loop:** If the transcript discusses the obsidian-bridge plugin itself, skip documenting.

**Step 2: Commit**

```bash
git add selrahcd-obsidian-bridge/agents/obsidian-doc-writer.md
git commit -m "feat(obsidian-bridge): add obsidian-doc-writer agent"
```

---

### Task 5: Register the plugin in marketplace.json

**Files:**
- Modify: `.claude-plugin/marketplace.json`

**Step 1: Add the plugin entry**

Add to the `plugins` array:

```json
{
  "name": "obsidian-bridge",
  "source": "./selrahcd-obsidian-bridge",
  "description": "Auto-document Claude sessions to an Obsidian vault via SessionEnd hook",
  "version": "1.0.0"
}
```

**Step 2: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat(obsidian-bridge): register plugin in marketplace"
```

---

### Task 6: Write the README

**Files:**
- Create: `selrahcd-obsidian-bridge/README.md`

**Step 1: Write README with installation instructions**

Include:
- What the plugin does (1-2 sentences)
- Prerequisites: `claude` CLI, Node.js >= 18, `jq`, `npx`
- Installation steps:
  1. Add plugin to marketplace (already done if using this repo)
  2. Set `OBSIDIAN_VAULT_PATH` env var in `~/.zshrc`
  3. (Optional) Create `.obsidian-bridge.json` in project roots
- Config file format with example
- How to verify it works
- How to check logs (`~/.claude/obsidian-bridge-logs/`)
- Troubleshooting: common issues (vault path wrong, Node.js missing, npx not found)

**Step 2: Commit**

```bash
git add selrahcd-obsidian-bridge/README.md
git commit -m "docs(obsidian-bridge): add README with installation guide"
```

---

### Task 7: Create .obsidian-bridge.json for this repo

**Files:**
- Create: `.obsidian-bridge.json` (at repo root)

**Step 1: Write the config for claude-marketplace**

```json
{
  "project": "Claude Marketplace",
  "tags": ["claude-marketplace", "plugins"],
  "notes": ["🦺 Projects/Claude Marketplace.md"]
}
```

**Step 2: Commit**

```bash
git add .obsidian-bridge.json
git commit -m "feat(obsidian-bridge): add project config for this repo"
```

---

### Task 8: Manual verification

**No files changed — manual testing.**

**Step 1: Verify env var is set**

```bash
echo $OBSIDIAN_VAULT_PATH
# Should print: /Users/charles.desneuf/Obsidian
```

If not set, add to `~/.zshrc`: `export OBSIDIAN_VAULT_PATH="/Users/charles.desneuf/Obsidian"`

**Step 2: Verify the hook is registered**

After installing the plugin, check that the SessionEnd hook appears:

```bash
claude /hooks  # or however hooks are listed
```

**Step 3: Run a test session**

Start a Claude session in this repo, have a conversation with 5+ messages about something meaningful, then exit. Check:
- `~/.claude/obsidian-bridge-logs/hook.log` — should show LAUNCH entry
- `~/.claude/obsidian-bridge-logs/doc-writer-*.log` — should show agent output
- Obsidian daily note — should have new entry under "What did I do?"

**Step 4: Verify project notes** (if the project note exists in Obsidian)

Check `🦺 Projects/Claude Marketplace.md` for a new dated entry.
