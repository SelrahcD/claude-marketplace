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
  "repository": "https://github.com/author/repo",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": "./commands/",
  "agents": "./agents/",
  "skills": "./skills/",
  "hooks": "./hooks/"
}
```

Only include component paths (commands, agents, skills, hooks, mcpServers, lspServers, outputStyles) that the plugin actually provides.

## Version Management

When making changes to a plugin (commands, skills, or plugin configuration), update the version in that plugin's `.claude-plugin/plugin.json` following semantic versioning:

- Patch (x.x.X): Bug fixes, documentation updates, minor improvements
- Minor (x.X.0): New commands, new skills, new features
- Major (X.0.0): Breaking changes, major restructuring

## Credits

When adding skills or commands based on external work, add credits to the plugin's README.md file in the Credits section. Format: `- <Skill/Command name>: [Author Name](link)`
