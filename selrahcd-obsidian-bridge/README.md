# obsidian-bridge

## What it does

After each Claude Code session, automatically logs a summary to your Obsidian vault. Updates daily notes and optional project-specific notes.

## How it works

A SessionEnd hook spawns a detached Claude agent (haiku model) that reads the session transcript, triages it, and writes notes via the MCP obsidian server. The MCP obsidian server must be configured globally in `~/.claude.json`.

## Prerequisites

- `claude` CLI installed and in PATH
- Node.js >= 18 (for `npx` to run the MCP obsidian server)
- `jq` for JSON parsing
- `gtimeout` on macOS (`brew install coreutils`) or `timeout` on Linux

## Installation

### Step 1: Add the plugin

Add the plugin to your Claude Code marketplace (already done if using this repo).

### Step 2: Set the vault path

Add to `~/.zshrc` (or `~/.zsh.conf.d/obsidian` if your dotfiles are shared across machines):

```bash
export OBSIDIAN_VAULT_PATH="/path/to/your/obsidian/vault"
```

This path differs per machine.

### Step 3: Configure MCP obsidian server

Add the MCP obsidian server to `~/.claude.json` (create the file if it doesn't exist):

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "npx",
      "args": ["@mauricio.wolff/mcp-obsidian@latest", "/path/to/your/obsidian/vault"]
    }
  }
}
```

Replace the vault path with your actual path. This makes the MCP available to the doc-writer agent (and optionally to your regular Claude sessions too).

To avoid slow `npx` downloads, you can pre-install globally: `npm install -g @mauricio.wolff/mcp-obsidian@latest`

### Step 4: Configure project-specific notes (optional)

In any git repo, create `.claude/obsidian-bridge.json`:

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

#### Optional: tracked efforts

You can also list ad-hoc tracked efforts (a refactor in progress, an investigation, a migration) under a `tracking[]` array. Each entry pins a vault note to a focus area so the `vault-index` skill, `/track`, and `/til` can surface the right note without scanning the whole vault.

```json
{
  "project": "My Project",
  "tags": ["my-project"],
  "notes": ["🦺 Projects/My Project.md"],
  "tracking": [
    {
      "label": "auth-refactor",
      "description": "Migration of auth middleware to new session token format",
      "notes": ["🦺 Projects/Auth Refactoring.md"],
      "tags": ["auth-refactor"]
    }
  ]
}
```

Per tracking entry:
- `label`: kebab-case identifier, unique within the file
- `description`: one-sentence explanation of the effort
- `notes`: vault-relative paths
- `tags`: optional, falls back to top-level `tags` when absent

You don't have to write `tracking` entries by hand. The plugin will offer to register a new tracked entry whenever it writes a note that looks like it documents an ongoing effort.

## Daily note format

The agent inserts under the "What did I do?" section:

```markdown
### Brief descriptive title
#ai-assisted/claude #project-tag

A freeform paragraph summarizing the session.

- Key details with [[wiki-links]]
```

## Skills

### `vault-index`

Triggers when you work with the Obsidian vault via MCP, or when you mention a tracked effort. It reads `.claude/obsidian-bridge.json`, surfaces the tracked notes as candidate destinations before writing, and offers to register new long-lived notes in the index after they're written.

The `track` and `til` commands embed the same logic inline so they remain self-contained when invoked explicitly.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OBSIDIAN_VAULT_PATH` | *(required)* | Path to your Obsidian vault |
| `OBSIDIAN_BRIDGE_AUTO_REPORT` | `false` | Set to `true` to enable the automatic session-end report |

To enable the auto-report, add to your shell profile or Claude Code settings:

```bash
export OBSIDIAN_BRIDGE_AUTO_REPORT=true
```

Or in `~/.claude/settings.json`:

```json
{
  "env": {
    "OBSIDIAN_BRIDGE_AUTO_REPORT": "true"
  }
}
```

## Logs

Check `~/.claude/obsidian-bridge-logs/` for hook logs and agent output.

## Troubleshooting

- **Nothing happens:** check that `OBSIDIAN_VAULT_PATH` is set and that the session had 5+ messages
- **Agent errors:** check `~/.claude/obsidian-bridge-logs/doc-writer-*.log`
- **MCP errors:** verify that `npx @mauricio.wolff/mcp-obsidian@latest $OBSIDIAN_VAULT_PATH` works
