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

#### `/selrahcd-dot-claude:refactor`
Starts the refactoring skill. Optional free-text description seeds the SETUP state (e.g., `/refactor split Order into Order + TaxCalculator`).

#### `/selrahcd-dot-claude:prepare-for-ai`
Audits a codebase for AI-readability smells (hidden domain, compound conditions, conditional maze, switch-as-table, generic naming, primitive obsession, tech-layer organization, god files, inconsistent patterns) and applies fixes one refactor at a time:
- Three scan modes: hotspots × smells, severity only, or user-directed path
- Read-only subagent (`prepare-for-ai-scanner`) returns a structured report in chat
- AST-first detection (eslint, ruff, pmd, ast-grep, semgrep…), LM fallback for semantic smells
- Apply phase delegates to the `refactoring` skill — one Fowler refactoring per commit, with a user gate between findings
- Tech-layer organization findings are report-only (slice extraction is a human-led decision)

### Agents

#### `commit-assistant`
Automated git commit helper that analyzes staged changes and generates meaningful commit messages following conventional commit standards. Invoked automatically after completing code changes or when the user requests a commit.

#### `prepare-for-ai-scanner`
Read-only code scanner used by `/prepare-for-ai`. Walks the configured scope, runs AST tooling where available (eslint, ruff, pmd, ast-grep, semgrep, radon…), falls back to LM judgement for semantic smells, and returns a numbered report in chat.

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

#### `refactoring`
Drive a refactor as a sequence of small, named refactorings from Martin Fowler's catalog. Each named refactoring is one commit, verified against a configured safety net (tests, type-checker, or manual review):
- 17 refactorings in the v1 catalog (Extract Method, Inline Variable, Extract Class, Replace Conditional with Polymorphism, etc.)
- Strict state-machine workflow modeled on `tdd-process`
- Hybrid planning: plan upfront, evolve between steps
- Invoke via `/refactor` or natural language ("refactor this", "extract method", "rename X")

#### `prepare-for-ai`
Catalog of nine code smells that hurt human and AI-agent comprehension, with detection recipes (AST-first, LM-fallback) and refactor pointers into the `refactoring` skill. Loaded on demand by the `prepare-for-ai-scanner` agent. Distilled from Adam Tornhill's *Code for Humans and Machines* series.

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
- TDD Process skill: [Nick Tune (NTCoding)](https://github.com/NTCoding)
- Claude Code Optimizer skill: [Nick Tune (NTCoding)](https://github.com/NTCoding)
- Using Git Worktrees skill: [Jesse Vincent](https://github.com/obra/superpowers/)
- Brainstorming skill: [Jesse Vincent](https://github.com/obra/superpowers/)
- Refactoring skill: [Martin Fowler — *Refactoring* (2nd ed.)](https://martinfowler.com/books/refactoring.html)
- Prepare-for-AI skill and command: [Adam Tornhill — *Code for Humans and Machines*](https://adamtornhill.substack.com)
