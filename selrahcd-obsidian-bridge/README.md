# obsidian-bridge

## What it does

After each Claude Code session, automatically logs a summary to your Obsidian vault. Updates daily notes and optional project-specific notes.

## How it works

A SessionEnd hook spawns a detached Claude agent (haiku model) that reads the session transcript, triages it, and writes notes via the MCP obsidian server. The MCP server is scoped exclusively to this agent and is not available globally.

## Prerequisites

- `claude` CLI installed and in PATH
- Node.js >= 18 (for `npx` to run the MCP obsidian server)
- `jq` for JSON parsing
- `gtimeout` on macOS (`brew install coreutils`) or `timeout` on Linux

## Installation

### Step 1: Add the plugin

Add the plugin to your Claude Code marketplace (already done if using this repo).

### Step 2: Set the vault path

Add to `~/.zshrc`:

```bash
export OBSIDIAN_VAULT_PATH="/path/to/your/obsidian/vault"
```

This path differs per machine.

### Step 3: Configure project-specific notes (optional)

In any git repo, create `.obsidian-bridge.json` at the root:

```json
{
  "project": "My Project",
  "tags": ["my-project"],
  "notes": ["🦺 Projects/My Project.md"]
}
```

- `project`: name used in wiki-links
- `tags`: applied as #tags to each entry (without # prefix)
- `notes`: vault-relative paths to project notes to update

## Daily note format

The agent inserts under the "What did I do?" section:

```markdown
### Claude session — Brief title
- What was done #tag1 #tag2
- Details with [[wiki-links]]
```

## Logs

Check `~/.claude/obsidian-bridge-logs/` for hook logs and agent output.

## Troubleshooting

- **Nothing happens:** check that `OBSIDIAN_VAULT_PATH` is set and that the session had 5+ messages
- **Agent errors:** check `~/.claude/obsidian-bridge-logs/doc-writer-*.log`
- **MCP errors:** verify that `npx @mauricio.wolff/mcp-obsidian@latest $OBSIDIAN_VAULT_PATH` works
