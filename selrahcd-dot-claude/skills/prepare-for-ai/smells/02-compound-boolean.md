# Compound boolean condition

## What it is

A boolean expression with multiple `&&` / `||` operators that forces the reader to mentally parse each clause and reconstruct the business rule. The rule is encoded but not named.

Citation: [Reveal Intent in Complex Conditions — Adam Tornhill](https://adamtornhill.substack.com/p/reveal-intent-in-complex-conditions).

## AST detection

| Ecosystem | Command | Signal |
|---|---|---|
| Node / TS | `eslint --rule '{"complexity": ["error", 10]}' <file>` | High cyclomatic complexity often correlates |
| Polyglot | `ast-grep -p 'if ($A && $B && $C) { $$$ }' <file>` | Three or more conjuncts in one `if` |
| Polyglot | `ast-grep -p 'if ($A \|\| $B \|\| $C) { $$$ }' <file>` | Three or more disjuncts |
| Polyglot | `semgrep -e '$A && $B && $C && $D' <file>` | Four-way conjunctions are almost always extractable |

Threshold: an `if` / `while` / ternary condition with ≥ 3 boolean operators, OR any mixed `&&` + `||` expression without parentheses-driven grouping.

## LM-fallback detection

Read the condition and ask:

- Can you state the business rule in one phrase ("user is an admin attempting a privileged operation outside business hours")?
- Does the condition mix concerns at different levels of abstraction (`user.role == "admin" && System.currentTimeMillis() > cutoff`)?
- Are the same sub-expressions repeated in nearby conditions?

If yes: the condition is doing the work a name should do.

## Refactor recipe

Two moves, often combined:

1. **Extract Variable** with a domain name: `boolean isPrivilegedAdminOutsideHours = …`.
2. **Extract Method** if the predicate is reused or if naming alone isn't enough to convey intent.

Fowler refactorings via the `refactoring` skill:

- `Extract Variable` (cheapest, often sufficient)
- `Extract Method` (when the predicate is reused or has its own dependencies)
- `Decompose Conditional` (when the surrounding `if/else` body is also opaque)

## When not to apply

- The condition is genuinely one short, idiomatic check (`x != null && x.isReady()`). Extraction here adds noise.
- The predicate would need many parameters to extract — the cure is worse than the disease. Look first for an Introduce Parameter Object opportunity that makes extraction natural.
