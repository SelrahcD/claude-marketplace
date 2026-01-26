# Claude Code Instructions

## Plugin Schema

Each plugin's `.claude-plugin/plugin.json` must follow this schema:

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/repo",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": "./commands/",
  "skills": "./skills/"
}
```

Only include component paths (commands, skills, mcpServers, lspServers, outputStyles) that the plugin actually provides. Default locations like `hooks/hooks.json` are auto-discovered and don't need to be declared.

**Important:** Do not declare `agents` in plugin.json - it causes validation errors. Place agent files in the default `agents/` directory and they will be auto-discovered.

## Version Management

When making changes to a plugin (commands, skills, or plugin configuration), update the version following semantic versioning:

- Patch (x.x.X): Bug fixes, documentation updates, minor improvements
- Minor (x.X.0): New commands, new skills, new features
- Major (X.0.0): Breaking changes, major restructuring

**Always keep versions in sync between:**
1. The plugin's `.claude-plugin/plugin.json` (`version` field)
2. The marketplace's `.claude-plugin/marketplace.json` (plugin entry `version` field)

## Command Naming (dot-claude plugin)

All commands in the `dot-claude` plugin must:
- Have a `name` field in YAML frontmatter
- Have a `description` field in YAML frontmatter
- Use no prefix (e.g., `name: commit` not `name: selrahcd:commit`)

Example:
```yaml
---
name: my-command
description: Brief description of what the command does
---
```

## Credits

When adding skills or commands based on external work, add credits to the plugin's README.md file in the Credits section. Format: `- <Skill/Command name>: [Author Name](link)`
