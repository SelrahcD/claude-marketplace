# Switch as table

## What it is

A `switch` / `match` / chained `if-else` whose every branch returns a constant or near-constant value keyed by a domain enum, string, or status code. The structure is a mapping; the code is a tree.

Citation: [Refactoring: Express Selections as Tables — Adam Tornhill](https://adamtornhill.substack.com/p/refactoring-express-selections-as).

## AST detection

| Ecosystem | Command | Signal |
|---|---|---|
| Polyglot | `ast-grep -p 'switch ($_) { case $_: return $_; case $_: return $_; $$$ }' <file>` | Switch where every body is a `return` of a literal/constructor |
| Node / TS | `semgrep -e 'switch ($X) { ... }' --include-flag returns-constants` | Same |
| Python | `ast-grep -p 'match $_: case $_: return $_; case $_: return $_; $$$' <file>` | Pattern-match returning constants |

Threshold: switch (or equivalent) with ≥ 3 branches, where every branch is a single `return` of a literal, enum value, or trivial constructor call with constant args.

## LM-fallback detection

Read the switch and ask:

- Does every branch end in `return SomeConstant` or `return new Thing("literal")`?
- Is the discriminator a domain enum, string code, or status?
- Are there no side effects, no further branching, no logging inside any case?

If yes: this is data masquerading as control flow.

## Refactor recipe

1. Introduce a `Map<Key, Value>` (or language-equivalent: dict, hash, static array) at module / class scope.
2. Replace the switch with `MAP.getOrDefault(key, default)` (or `MAP[key] ?? default`).
3. If construction is non-trivial, populate via a static initialiser block.
4. Keep the default branch behaviour explicit — don't silently drop it.

Fowler refactorings via the `refactoring` skill:

- `Extract Variable` (the map) → `Replace Conditional with Polymorphism`'s table variant (custom — see catalog entry on lookups) → `Inline Method` if the switch was its own function

## When not to apply

- Branches contain meaningful behaviour, side effects, or non-trivial algorithms — use polymorphism / strategy instead. Tables encode data, not behaviour.
- The discriminator is open-ended (new cases added by external code via plugins) — polymorphism with registration is more extensible.
- The "constants" are actually expensive to construct and you'd be eagerly evaluating them — use lazy initialisation or a function-valued table.
