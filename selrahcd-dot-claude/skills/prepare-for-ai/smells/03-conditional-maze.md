# Conditional maze

## What it is

Nested `if` chains where each level encodes a separate policy check. The control flow looks like selection but is actually a sequence of independent rules — short-circuiting on the first match. Rule order matters but is hidden in the nesting.

Citation: [Kill the Conditional Maze — Adam Tornhill](https://adamtornhill.substack.com/p/kill-the-conditional-maze-from-if).

## AST detection

| Ecosystem | Command | Signal |
|---|---|---|
| Node / TS | `eslint --rule '{"max-depth": ["error", 3]}' <file>` | Nesting depth |
| Python | `ruff check --select PLR0912 <file>` | Too many branches |
| Polyglot | `radon cc -nc <file>` (Python) | Cyclomatic complexity ≥ C |
| Polyglot | `ast-grep -p 'if ($_) { if ($_) { if ($_) { $$$ } } }' <file>` | Three+ nested `if`s |

Threshold: nesting depth ≥ 3 OR cyclomatic complexity ≥ 10 in a function whose branches lead to early returns.

## LM-fallback detection

Read the function and ask:

- Does each `if` body either return a result or fall through to the next check?
- Could each check be stated as "rule N: if X, then Y"?
- Are there comments labelling the branches (`// check quoted fragments`, `// reject if author is banned`)? Comments-as-labels are a strong tell.
- Is the order of checks load-bearing — would swapping two `if`s change behaviour?

If yes: it's a rule pipeline pretending to be a decision tree.

## Refactor recipe

1. Extract each conditional block into a named method `tryRuleName(input) → Optional<Result>`.
2. Empty return = "rule doesn't apply, continue".
3. The replacement orchestrator is a loop over an ordered list of rule references.
4. Side effects (logging, auditing) move into the rule that triggers them.

Fowler refactorings via the `refactoring` skill:

- `Extract Method` (per rule) → `Change Function Declaration` (unify return to `Optional<Result>`) → assemble pipeline

## When not to apply

- Rules share heavy mutable state — polymorphism / strategy fits better than a flat pipeline.
- You are selecting a behaviour *family* (e.g. dispatch by type) rather than running ordered checks — that is Replace Conditional with Polymorphism, not a pipeline.
- The "nested ifs" are actually a single decision tree (true selection logic), not sequential policies.
