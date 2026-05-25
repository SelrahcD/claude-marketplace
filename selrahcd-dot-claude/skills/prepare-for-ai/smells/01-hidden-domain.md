# Hidden domain in long procedure

## What it is

A method that mixes multiple business workflows into one weakly-described unit. The domain actions are buried in the procedure body — readers (human or agent) must reverse-engineer which clauses belong to which workflow before they can change anything safely.

Citation: [Make the Domain Explicit — Adam Tornhill](https://adamtornhill.substack.com/p/make-the-domain-explicit-from-procedural).

## AST detection

| Ecosystem | Command | Signal |
|---|---|---|
| Node / TS | `eslint --rule '{"max-lines-per-function": ["error", 40], "complexity": ["error", 10]}' <file>` | Function exceeds length + branch count thresholds |
| Python | `ruff check --select PLR0915,PLR0912 <file>` | Too many statements / too many branches |
| Java | `pmd -R category/java/design.xml/ExcessiveMethodLength,category/java/design.xml/CyclomaticComplexity <file>` | Same |
| Polyglot | `ast-grep -p 'function $F($$$) { $$$ }' <file>` then count statements | Same |

Thresholds (override per project): function > 40 lines AND ≥ 2 distinct branching constructs.

## LM-fallback detection

AST tells you the function is large. Only an LM can tell you it mixes responsibilities. Read the function and ask:

- Are there clusters of statements that could be named with different verbs (`refund …`, `notify …`, `audit …`)?
- Does the parameter list suggest one input but the body branches on a "type" field to dispatch different actions?
- Could each cluster be lifted out and the surrounding method still make sense as an orchestrator?

If yes to any: this is hidden domain, not just a long method.

## Refactor recipe

1. Introduce a small interface for the action family (`BackOfficeTask` in Tornhill's example).
2. For each cluster, create a named class implementing the interface.
3. Build a dispatch table keyed by the discriminator (string, enum, or domain value).
4. The original method becomes an orchestrator: look up the action and execute.

Fowler refactorings to chain (via the `refactoring` skill):

- `Extract Method` (per cluster) → `Move Function` (into new class) → `Replace Conditional with Polymorphism`

## When not to apply

- The clusters share heavy mutable state — extracting them creates worse coupling than the procedure.
- The "long method" is genuinely one workflow that happens to be long (e.g. a calculation pipeline). Length alone is not the smell — mixed responsibility is.
- The discriminator is unstable: cases are added/removed frequently and a table lookup would churn. Polymorphism still helps, but evaluate before extracting.
