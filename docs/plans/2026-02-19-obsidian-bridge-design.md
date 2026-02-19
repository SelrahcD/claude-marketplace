# Obsidian Bridge Plugin Design

## Goal

A Claude Code plugin that automatically logs session summaries to an Obsidian vault after each Claude session ends. Updates both daily notes and project-specific notes.

## Plugin: `selrahcd-obsidian-bridge` v1.0.0

### Structure

```
selrahcd-obsidian-bridge/
├── .claude-plugin/plugin.json
├── agents/obsidian-doc-writer.md
├── hooks/hooks.json
├── scripts/session-end-obsidian.sh
└── README.md
```

### Flow

1. `SessionEnd` hook fires `session-end-obsidian.sh`
2. Script reads stdin JSON (`session_id`, `transcript_path`, `cwd`)
3. Guards: anti-loop (`CLAUDE_HOOK_SPAWNED`), `OBSIDIAN_VAULT_PATH` must be set, minimum 5 user messages
4. Looks for `.obsidian-bridge.json` in `cwd`, then git repo root
5. Spawns detached `claude --print --model haiku` with:
   - `--mcp-config` inline JSON pointing obsidian MCP at `$OBSIDIAN_VAULT_PATH`
   - `--strict-mcp-config` so only the obsidian MCP is available (no global MCP leaking)
6. Agent triages transcript (skip if trivial)
7. Agent reads daily note via MCP obsidian, inserts session summary under "What did I do?" section
8. If `.obsidian-bridge.json` found, also updates project-specific notes

### Environment

- **`OBSIDIAN_VAULT_PATH`**: Global env var pointing to the Obsidian vault root. Set in `.zshrc` or `.zshenv`. Different per machine. Also serves as enable/disable guard (not set = hook exits silently).

### MCP Obsidian — Global Configuration

The MCP obsidian server is configured globally in `~/.claude.json`. The spawned doc-writer agent inherits this configuration. `--mcp-config` with `--strict-mcp-config` was found to cause `claude --print` to hang indefinitely, so the global approach is required.

The agent also reads its instructions from disk (the prompt tells it to `Read $PLUGIN_ROOT/agents/obsidian-doc-writer.md`), matching the pattern used by KnutFr/HomeAIPublic.

### Project Config: `.obsidian-bridge.json`

Placed in the project root (git repo root). Tells the agent which project this is and what Obsidian notes to update. The script looks for it in `cwd` first, then falls back to `git rev-parse --show-toplevel`.

```json
{
  "project": "claude-marketplace",
  "tags": ["claude-marketplace", "plugins"],
  "notes": ["🦺 Projects/Claude Marketplace.md"]
}
```

- `project`: Project name, used in wiki-links and as context
- `tags`: Obsidian tags applied to each session entry (without `#` prefix)
- `notes`: Vault-relative paths to project notes to update

### Daily Note Format

Path: `🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md`

The agent inserts content under the existing "What did I do?" section, after the `tasks` code block. Format:

```markdown
### Claude session — Brief descriptive title
- What was accomplished #tag1 #tag2
- Key details with [[wiki-links]] to relevant notes
  - Sub-details indented as needed
```

### Project Note Updates

When `.obsidian-bridge.json` specifies `notes`, the agent appends a dated entry to each note, linking back to the daily note:

```markdown
- **YYYY-MM-DD**: Brief summary — see [[🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD]]
```

### Session-End Script Details

`scripts/session-end-obsidian.sh`:
- Reads JSON from stdin
- **Anti-loop guard**: exits if `CLAUDE_HOOK_SPAWNED=1`
- **Vault check**: exits silently if `OBSIDIAN_VAULT_PATH` not set
- **Message threshold**: counts user messages in transcript, skips if < 5
- **Config lookup**: checks `cwd` then `git -C "$cwd" rev-parse --show-toplevel` for `.obsidian-bridge.json`
- **Sleep 500ms**: lets transcript finish writing
- **Spawn**: `nohup claude --print --model haiku --mcp-config '...' --strict-mcp-config -p "..." &`
  - Strips: `CLAUDECODE`, `CLAUDE_CODE_SSE_PORT`, `CLAUDE_CODE_ENTRYPOINT`
  - Sets: `CLAUDE_HOOK_SPAWNED=1`
  - Passes: transcript content, cwd, vault path, config file content (if found)

### Agent: `obsidian-doc-writer.md`

**Phase 1 — Triage**: Read the transcript. If the session was trivial (just exploring, asking questions, no meaningful work done), stop without writing anything.

**Phase 2 — Daily note**:
1. Use `read_note` to get the current daily note at `🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD.md`
2. Find the "What did I do?" section and the end of the tasks code block
3. Insert a sub-header session entry with bullet points, tags from config, and wiki-links
4. Use `write_note` with `overwrite` mode to save the updated content

**Phase 3 — Project notes**:
1. If `.obsidian-bridge.json` was provided, iterate over `notes` array
2. Use `read_note` on each project note
3. Append a dated entry linking to the daily note
4. Use `write_note` with `overwrite` or `append` mode

### Dependencies

- `claude` CLI available in PATH
- `npx` and Node.js >= 18 (for the MCP obsidian server)
- `OBSIDIAN_VAULT_PATH` env var set on each machine
- `jq` for JSON parsing in the shell script

### Installation

#### 1. Install the plugin

Add the plugin to your Claude Code marketplace. The plugin auto-registers its `SessionEnd` hook.

#### 2. Set the vault path environment variable

Add to your `~/.zshrc` (or `~/.zshenv`):

```bash
export OBSIDIAN_VAULT_PATH="/path/to/your/obsidian/vault"
```

This is different on each machine. Examples:
- Laptop 1: `export OBSIDIAN_VAULT_PATH="/Users/charles/Obsidian"`
- Laptop 2: `export OBSIDIAN_VAULT_PATH="/Users/charles.desneuf/Obsidian"`

#### 3. Ensure Node.js is available

The MCP obsidian server runs via `npx`. Make sure Node.js >= 18 is installed:

```bash
node --version  # Should be >= 18
```

#### 4. (Optional) Configure projects

In any git repo where you want project-specific notes, create `.obsidian-bridge.json` at the repo root:

```json
{
  "project": "My Project",
  "tags": ["my-project"],
  "notes": ["🦺 Projects/My Project.md"]
}
```

#### 5. Verify

Run a Claude session with more than 5 messages, then check your Obsidian daily note. You should see a new entry under "What did I do?".

### Not in Scope (for now)

- Process improvement / config enhancement (from reference repo)
- Automatic creation of daily notes (assumes they already exist from Obsidian template)
- Global MCP obsidian access in regular sessions
