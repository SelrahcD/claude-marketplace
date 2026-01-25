# Claude Code Instructions

## Version Management

When making changes to plugins (commands, skills, or plugin configuration), always update the version numbers:

1. **Plugin version** (`dot-claude/.claude-plugin/plugin.json`): Increment the `version` field following semantic versioning:
   - Patch (x.x.X): Bug fixes, documentation updates, minor improvements
   - Minor (x.X.0): New commands, new skills, new features
   - Major (X.0.0): Breaking changes, major restructuring

2. **Marketplace version** (`.claude-plugin/marketplace.json`): Add a `version` field if not present and keep it in sync with plugin changes.

## Files to Update

When modifying any file in `dot-claude/`:
- `dot-claude/.claude-plugin/plugin.json` - Update `version`
- `.claude-plugin/marketplace.json` - Update `version` (add if missing)
