# Claude Marketplace Plugin - SelrahcD Edition

A collection of productivity-focused plugins for [Claude Code](https://claude.com/claude-code).

## Available Plugins

### [Notifications Plugin](./selrahcd-notifications/README.md)
Desktop notifications for Claude Code events - get notified when sessions start/end, when Claude finishes responding, or when attention is needed.

### [Dot-Claude Plugin](./selrahcd-dot-claude/README.md)
Commands and skills for PR management, test improvements, and test-driven development workflows. Includes:
- `/create-pr` - Streamlined pull request creation
- `/handle-pr-review` - Automated PR review handling
- `/improve-test` - Test file quality improvements
- `test-driven-development` skill for TDD workflows

## Installation

### From Marketplace

Add the marketplace and install plugins:

```
/plugin marketplace add SelrahcD/claude-marketplace
/plugin install notifications@Selrahcd-marketplace
/plugin install dot-claude@Selrahcd-marketplace
```

### Local Installation

Clone the repository and install plugins from your local path:

```bash
git clone https://github.com/SelrahcD/claude-marketplace.git
```

Then in Claude Code:

```
/plugin install /path/to/claude-marketplace/selrahcd-notifications
/plugin install /path/to/claude-marketplace/selrahcd-dot-claude
```

See each plugin's README for detailed setup and usage instructions.

## Requirements

- Claude Code (latest version)
- See individual plugin READMEs for plugin-specific requirements

## Support

For issues or questions about Claude Code and plugins, refer to the [Claude Code documentation](https://docs.claude.com/en/docs/claude-code/).
