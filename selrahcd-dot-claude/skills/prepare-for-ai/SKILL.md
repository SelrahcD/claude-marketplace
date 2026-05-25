---
name: prepare-for-ai
description: Catalog of code smells that hurt human and AI-agent comprehension, with detection recipes (AST-first, LM-fallback) and refactor pointers. Use when scanning a codebase for AI-readability improvements, or when explaining why a piece of code is harder for agents to reason about than it should be.
user-invocable: false
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Prepare-for-AI Catalog

A codebase is AI-ready when humans and agents can reason about it locally. The smells in this catalog hide intent, force reconstruction, or scatter related logic. They hurt humans too — but agents pay a higher price because their context is finite and their patience for ambiguity is zero.

Source: Adam Tornhill, *Code for Humans and Machines* (https://adamtornhill.substack.com).

## Detection strategy

For each target file, run two passes and merge results:

### 1. AST pass (prefer when available)

Discover project tooling once, then use it:

| Ecosystem | Discovery signal | Linters / AST tools to prefer |
|---|---|---|
| Node / TS | `package.json`, `.eslintrc*`, `eslint.config.*` | `eslint` (with `complexity`, `max-depth`, `max-lines`, `max-lines-per-function`), `tsc --noEmit` |
| Python | `pyproject.toml`, `ruff.toml`, `.flake8`, `setup.cfg` | `ruff check --select C901,PLR0912,PLR0915`, `radon cc`, `pylint --disable=all --enable=R0912,R0915,R0914` |
| Rust | `Cargo.toml`, `clippy.toml` | `cargo clippy -- -W clippy::cognitive_complexity` |
| Go | `go.mod` | `gocyclo`, `gocognit`, `staticcheck` |
| Java / Kotlin | `pom.xml`, `build.gradle*` | `pmd`, `checkstyle`, `detekt` |
| Polyglot | any | `ast-grep`, `semgrep`, `tree-sitter` |

Each smell file lists concrete commands. If the tool is on `PATH` or declared in the project, use it — its output is more reliable than reading. If no AST tool is available for a smell or language, fall back to the LM pass.

### 2. LM pass (fallback for semantic smells)

Some smells need judgement no linter can give: whether a name carries domain meaning, whether two pieces of code solve the same problem differently, whether a long method mixes responsibilities. For these, read the file and apply the heuristics in the smell file.

### Merge

Same `file:line` from both passes collapses into one finding. Record detection source as `[AST: <tool> <rule>]` or `[LM]` so reviewers can calibrate trust.

## Catalog

| # | Smell | File |
|---|---|---|
| 1 | Hidden domain in long procedure | [smells/01-hidden-domain.md](smells/01-hidden-domain.md) |
| 2 | Compound boolean condition | [smells/02-compound-boolean.md](smells/02-compound-boolean.md) |
| 3 | Conditional maze | [smells/03-conditional-maze.md](smells/03-conditional-maze.md) |
| 4 | Switch as table | [smells/04-switch-as-table.md](smells/04-switch-as-table.md) |
| 5 | Generic naming | [smells/05-generic-naming.md](smells/05-generic-naming.md) |
| 6 | Primitive obsession on domain concept | [smells/06-primitive-obsession.md](smells/06-primitive-obsession.md) |
| 7 | Tech-layer organization | [smells/07-tech-layer-organization.md](smells/07-tech-layer-organization.md) |
| 8 | God file | [smells/08-god-file.md](smells/08-god-file.md) |
| 9 | Inconsistent pattern | [smells/09-inconsistent-pattern.md](smells/09-inconsistent-pattern.md) |

## Report format

When a consumer (e.g. the `prepare-for-ai-scanner` agent) emits a report, use this shape:

```
## Prepare-for-AI Report

Mode: <hotspots-x-smells | severity-only | user-directed:<path>>
Scope: <N files scanned>
Findings: <N total>

### Hidden domain in long procedure (N)

1. `path/to/File.java:42-180` — `handleCase()` — [AST: pmd ExcessiveMethodLength] / [LM]
   Mixes refund, welcome-package, and audit workflows. Extract per-action commands.
   Effort: M

2. ...

### Compound boolean condition (N)
...
```

Each finding: file:line range — focal symbol — detection source — one-sentence rationale — refactor pointer — effort (S / M / L).

## Hotspot prioritization (used by the scanner in hotspot mode)

```bash
git log --since=6.months --format= --name-only \
  | grep -v '^$' \
  | sort | uniq -c | sort -rn \
  | head -50
```

Cross the top-churn files with file size (`wc -l`). Files with high churn AND high size are Tornhill's hotspots — the most valuable refactoring targets. Cold code is left alone regardless of smells.
