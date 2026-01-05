# Claude Marketplace Plugin - SelrahcD Edition

A collection of productivity-focused commands and skills for [Claude Code](https://claude.com/claude-code). This marketplace plugin extends Claude's capabilities with specialized workflows for GitHub PR management, test refactoring, and test-driven development.

## What Is This?

This is a Claude AI marketplace plugin that packages developer productivity tools into reusable commands and skills. It integrates with Claude Code to provide:

- **Slash commands** for automating common development workflows
- **Skills** that encapsulate best practices and methodologies
- **GitHub integration** for streamlined pull request management
- **Test quality improvements** for better code coverage and clarity

## Features

### Notification

Display notifications when attention is required.

### Commands

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

### Skills

#### `test-driven-development`
A comprehensive Test-Driven Development guide enforcing the RED-GREEN-REFACTOR cycle:
- Uses ZOMBIES ordering for test organization
- Implements TPP (Transformation Priority Premise) transformations
- Follows outside-in development approach
- Integrates with `tdd-guard` for continuous verification
- Documents common pitfalls and best practices

## Installation

This marketplace plugin integrates with Claude Code. To install:

1. Ensure you have Claude Code installed
2. Add this repository's marketplace plugin to your Claude Code configuration, `/plugin marketplace add SelrahcD/claude-marketplace`


### Install dot-claude plugin

Install plugin, `/plugin install dot-claude@Selrahcd-marketplace `

For detailed installation instructions, refer to the [Claude Code Plugins Documentation](https://docs.claude.com/en/docs/claude-code/plugins).

## Usage

### Using Commands

Commands are available as slash commands in Claude Code:

```
/selrahcd:create-pr
/selrahcd:handle-pr-review
/selrahcd:improve-test
```

Type any command to execute it within your Claude Code session.

### Using Skills

Skills are invoked automatically when relevant to your task, or you can explicitly request them:

- Request test improvements: Ask Claude to "improve my test using the test improvement command"
- Request TDD workflow: Ask Claude to follow "test-driven development"
- Request PR handling: Use `/selrahcd-dot-claude:handle-pr-review`

## Project Structure

```
.
├── README.md                        # This file
├── .claude-plugin/
│   └── marketplace.json             # Marketplace plugin configuration
└── dot-claude/
    ├── .claude-plugin/
    │   └── plugin.json              # Plugin metadata
    ├── commands/                    # Slash command definitions
    │   ├── create-pr.md
    │   ├── handle-pr-review.md
    │   └── improve-test.md
    └── skills/                      # Reusable skill implementations
        └── test-driven-development/
            └── index.md
```

## Requirements

- Claude Code (latest version)
- GitHub CLI (`gh`) - for GitHub-related commands
- Git - for repository operations

## Contributing

This is a personal marketplace plugin, but feel free to reference it or adapt its patterns for your own Claude Code extensions.

## Support

For issues or questions about Claude Code and plugins, refer to the [Claude Code documentation](https://docs.claude.com/en/docs/claude-code/).

## Credits

The BugMagnet command is from [Gojko Adzic](https://github.com/gojko/bugmagnet-ai-assistant/)
[Notifier](https://github.com/hta218/claude-code-notifier)
