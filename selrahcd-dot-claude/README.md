# Dot-Claude Plugin

A Claude Code plugin providing commands, agents, and skills for PR management, test improvements, and test-driven development workflows.

## Features

### Commands

#### `/selrahcd-dot-claude:create-pr`
Streamlines pull request creation using GitHub CLI integration. Creates a PR for your current branch with customizable title and body.

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

### Agents

#### `commit-assistant`
Automated git commit helper that analyzes staged changes and generates meaningful commit messages following conventional commit standards. Invoked automatically after completing code changes or when the user requests a commit.

### Skills

#### `test-driven-development`
A comprehensive Test-Driven Development guide enforcing the RED-GREEN-REFACTOR cycle:
- Uses ZOMBIES ordering for test organization
- Implements TPP (Transformation Priority Premise) transformations
- Follows outside-in development approach
- Integrates with `tdd-guard` for continuous verification
- Documents common pitfalls and best practices

#### `adr`
Manage Architecture Decision Records (ADRs) for documenting technical decisions:
- `/adr new <title>` - Create a new ADR
- `/adr list` - List all existing ADRs
- `/adr show <number>` - Display a specific ADR
- `/adr supersede <number> <new-title>` - Create a new ADR that supersedes an existing one
- `/adr deprecate <number>` - Mark an ADR as deprecated

## Installation

1. Add the marketplace to your Claude Code configuration:
   ```
   /plugin marketplace add SelrahcD/claude-marketplace
   ```

2. Install the plugin:
   ```
   /plugin install dot-claude@Selrahcd-marketplace
   ```

## Requirements

- Claude Code (latest version)
- GitHub CLI (`gh`) - for GitHub-related commands
- Git - for repository operations

## Usage

**Slash commands** are available in Claude Code:

```
/selrahcd-dot-claude:create-pr
/selrahcd-dot-claude:handle-pr-review
/selrahcd-dot-claude:improve-test
```

**Skills** are invoked automatically when relevant, or you can explicitly request them:
- Request TDD workflow: Ask Claude to follow "test-driven development"

## Credits

- BugMagnet command: [Gojko Adzic](https://github.com/gojko/bugmagnet-ai-assistant/)
