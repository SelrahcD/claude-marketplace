# Primitive obsession on domain concept

## What it is

A primitive (`String`, `int`, `double`, `boolean`) carrying a domain meaning is passed around as itself instead of a typed value. The compiler cannot tell a `String email` from a `String userId`; readers must remember which is which.

Citation: [How Long Should a Function Be? — Adam Tornhill](https://adamtornhill.substack.com/p/how-long-should-a-function-be-and) (the `HumidityBand` example).

## AST detection

| Ecosystem | Command | Signal |
|---|---|---|
| Polyglot | `ast-grep -p 'function $F($P: string, $$$): $_ { $$$ }' <file>` then group by parameter name | Same `String` parameter name appearing across many signatures (`email`, `userId`, `orderId`) |
| Polyglot | `grep -nE '^\s*(public\|fun\|def) .+\\((String|int|str|float) [a-z][a-zA-Z]+,' <file>` | Cheap textual screen |
| Java | `pmd -R category/java/codestyle.xml/AbstractNaming` (proxy) | — |

Run a count across the codebase: any primitive parameter name appearing in ≥ 5 distinct signatures is a value-type candidate.

## LM-fallback detection

For each repeated primitive parameter, ask:

- Does the value have invariants the primitive cannot enforce (non-empty, format, range)?
- Is the value passed through many layers without the primitive's other operations being used (a `String` that is never sliced, only compared)?
- Would mixing it up with another primitive of the same type cause a real bug (passing `email` where `userId` is expected)?
- Does the codebase already validate / normalise this value in multiple places?

If yes: the primitive is hiding a domain type.

## Refactor recipe

1. Introduce a small value type: immutable, validated in the constructor, equality by value.
2. Replace the parameter type one call site at a time.
3. Push validation / normalisation into the constructor; remove duplicated checks at call sites.
4. Consider co-locating related operations (formatting, comparison) on the type.

Fowler refactorings via the `refactoring` skill:

- `Replace Primitive with Object` → `Change Function Declaration` (per call site) → `Inline Method` (on now-redundant validators)

## When not to apply

- The primitive truly has no domain meaning beyond its type (a numeric configuration knob, an array index, a generic counter).
- The codebase is short-lived or the boundary is external (DB column, JSON field) and you would only add a layer of conversion with no real safety benefit.
- The domain type would be one-shot — used in exactly one call signature with no invariants to enforce.
