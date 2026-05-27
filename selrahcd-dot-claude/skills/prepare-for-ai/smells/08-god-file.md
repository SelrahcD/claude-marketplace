# God file

## What it is

A single file holding many unrelated concepts: large by line count, large by public-export count, or both. Agents must load all of it to answer questions about any of it; humans cannot hold its purpose in mind.

Citation: [Welcome to Code for Humans and Machines — Adam Tornhill](https://adamtornhill.substack.com/p/welcome-to-code-for-humans-and-machines).

## AST detection

| Ecosystem | Command | Signal |
|---|---|---|
| Polyglot | `wc -l <file>` | > 400 lines |
| Node / TS | `eslint --rule '{"max-lines": ["error", 400]}' <file>` | Same, ergonomic |
| Polyglot | `grep -cE '^(export |public class |def |fun |func )' <file>` | ≥ 10 top-level public exports |
| Polyglot | `ast-grep -p 'class $_ { $$$ }' <file>` then count methods per class | A single class with ≥ 15 public methods |

Combine signals: a file is a god file when it crosses ≥ 2 thresholds. A 600-line file with one tightly-cohesive class is not a god file. A 200-line file with 12 unrelated exports often is.

## LM-fallback detection

Read the file and ask:

- Can you describe the file's purpose in one phrase without the word "and"?
- Are there exports that no consumer imports together (e.g. a utility function and an HTTP client in the same file)?
- Does the file mix levels of abstraction (orchestration + helpers + framework wiring + domain types)?
- If you had to split it in two, would the split be obvious?

If yes: it is a god file.

## Refactor recipe

1. Group exports by cohesion: which ones change together, are imported together, share a concept.
2. Move each group into its own file with a name that states its purpose.
3. Update imports.
4. If the file is one giant class, prefer `Extract Class` before file moves — splitting a class across files without splitting responsibility is cosmetic.

Fowler refactorings via the `refactoring` skill:

- `Extract Class` (when one class is too large) → `Move Function` / `Move Field` (per concept group) → file-level moves

## When not to apply

- The file is large but cohesive (a complete state machine, a complete grammar, a generated file). Cohesion overrides line count.
- The exports are large because of test fixtures or constant tables — split if it helps navigation, leave if splitting fragments the data.
- Splitting would create circular imports — restructure dependencies first, then split.
