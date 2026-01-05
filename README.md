# Claude Marketplace Plugin - SelrahcD Edition

A collection of productivity-focused plugins for [Claude Code](https://claude.com/claude-code). This marketplace provides two complementary plugins that extend Claude's capabilities with development workflows and system notifications.

## What Is This?

This is a Claude AI marketplace that packages developer productivity tools into reusable plugins. It provides:

- **System notifications** for Claude Code events
- **Slash commands** for automating common development workflows
- **Skills** that encapsulate best practices and methodologies
- **GitHub integration** for streamlined pull request management
- **Test quality improvements** for better code coverage and clarity

## Available Plugins

This marketplace contains two plugins:

### 1. Notifications Plugin (`notifications`)
Desktop notifications for Claude Code events - get notified when sessions start/end, when Claude finishes responding, or when attention is needed.

### 2. Dot-Claude Plugin (`dot-claude`)
Commands and skills for PR management, test improvements, and test-driven development workflows.

## Features by Plugin

### Notifications Plugin

**Real-time desktop notifications** for Claude Code events:
- Session start/end notifications
- Response completion alerts
- Custom notifications from Claude
- Cross-platform support (macOS, Linux, Windows)

See [selrahcd-notifications/README.md](./selrahcd-notifications/README.md) for detailed documentation.

### Dot-Claude Plugin

#### Commands

#### `/selrahcd-dot-claude:create-pr`
Streamlines pull request creation from Claude Code using GitHub CLI integration. Creates a PR for your current branch with customizable title and body.

#### `/selrahcd-dot-claude:handle-pr-review`
Automates GitHub PR review workflows by:
- Fetching unresolved comments on your pull request
- Processing them one by one for targeted fixes
- Creating commits for each resolution
- Replying to comments with commit links
- Tracking progress with an integrated todo list

#### `/selrahcd-dot-claude:improve-test`
Refactors test files to improve quality:
- Enhances readability through better naming and organization
- Reduces duplication by extracting factories and builders
- Logically groups related tests
- Supports TypeScript/JavaScript, Python, Java, and C#

#### Skills

##### `test-driven-development`
A comprehensive Test-Driven Development guide enforcing the RED-GREEN-REFACTOR cycle:
- Uses ZOMBIES ordering for test organization
- Implements TPP (Transformation Priority Premise) transformations
- Follows outside-in development approach
- Integrates with `tdd-guard` for continuous verification
- Documents common pitfalls and best practices

## Installation

### Add the Marketplace

First, add this marketplace to your Claude Code configuration:

```
/plugin marketplace add SelrahcD/claude-marketplace
```

### Install Plugins

You can install either or both plugins depending on your needs:

**Install both plugins:**
```
/plugin install notifications@Selrahcd-marketplace
/plugin install dot-claude@Selrahcd-marketplace
```

**Or install individually:**
```
/plugin install notifications@Selrahcd-marketplace
```
```
/plugin install dot-claude@Selrahcd-marketplace
```

### Post-Installation Setup

#### For Notifications Plugin

Install the platform-specific notification tools:

- **macOS**: `brew install terminal-notifier jq`
- **Linux**: `sudo apt-get install libnotify-bin jq` (Debian/Ubuntu)
- **Windows**: No additional setup required

The plugin automatically references its notification script using `${CLAUDE_PLUGIN_ROOT}`, so no manual file copying is needed.

See [selrahcd-notifications/README.md](./selrahcd-notifications/README.md) for detailed information.

For general plugin installation help, refer to the [Claude Code Plugins Documentation](https://docs.claude.com/en/docs/claude-code/plugins).

## Usage

### Notifications Plugin

The notifications plugin works automatically once installed and configured. You'll receive desktop notifications for:
- Session start/end events
- When Claude finishes responding
- Custom notification messages from Claude

No manual commands needed - notifications appear automatically.

### Dot-Claude Plugin

**Slash commands** are available in Claude Code:

```
/selrahcd-dot-claude:create-pr
/selrahcd-dot-claude:handle-pr-review
/selrahcd-dot-claude:improve-test
```

Type any command to execute it within your Claude Code session.

**Skills** are invoked automatically when relevant, or you can explicitly request them:

- Request test improvements: Ask Claude to "improve my test using the test improvement command"
- Request TDD workflow: Ask Claude to follow "test-driven development"
- Request PR handling: Use `/selrahcd-dot-claude:handle-pr-review`

## Project Structure

```
.
├── README.md                           # This file
├── .claude-plugin/
│   └── marketplace.json                # Marketplace configuration
├── selrahcd-notifications/             # Notifications plugin
│   ├── .claude-plugin/
│   │   └── plugin.json                 # Plugin metadata
│   ├── hooks/
│   │   └── hooks.json                  # Hook configuration
│   ├── scripts/
│   │   └── claude-code-notifier.sh     # Notification script
│   └── README.md                       # Notifications plugin docs
└── selrahcd-dot-claude/                # Dot-Claude plugin
    ├── .claude-plugin/
    │   └── plugin.json                 # Plugin metadata
    ├── commands/                       # Slash command definitions
    │   ├── create-pr.md
    │   ├── handle-pr-review.md
    │   ├── improve-test.md
    │   └── bugmagnet.md
    ├── hooks/
    │   └── hooks.json                  # Hook configuration
    ├── skills/                         # Reusable skill implementations
    │   └── test-driven-development/
    │       └── SKILL.md
    └── claude-code-notifier.sh         # Legacy notification script (deprecated)
```

## Requirements

### Core Requirements
- Claude Code (latest version)

### Plugin-Specific Requirements

**Notifications Plugin:**
- macOS: `terminal-notifier` and `jq` (install via Homebrew)
- Linux: `libnotify-bin` and `jq` (install via package manager)
- Windows: Built-in PowerShell (no additional requirements)

**Dot-Claude Plugin:**
- GitHub CLI (`gh`) - for GitHub-related commands
- Git - for repository operations

## Contributing

This is a personal marketplace plugin, but feel free to reference it or adapt its patterns for your own Claude Code extensions.

## Support

For issues or questions about Claude Code and plugins, refer to the [Claude Code documentation](https://docs.claude.com/en/docs/claude-code/).

## Credits

- BugMagnet command: [Gojko Adzic](https://github.com/gojko/bugmagnet-ai-assistant/)
- Notification script: Based on [claude-code-notifier](https://github.com/hta218/claude-code-notifier) by [@hta218](https://github.com/hta218)
