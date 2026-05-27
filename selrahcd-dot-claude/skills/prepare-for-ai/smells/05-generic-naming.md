# Generic naming

## What it is

Identifiers drawn from a small set of "noise words" that carry no domain meaning: `process`, `handle`, `manage`, `do`, `make`, `execute`, `data`, `info`, `item`, `value`, `helper`, `util`, `manager`, `processor`, `service` (when used outside an architectural meaning), `result`, `temp`, `obj`.

Citation: [How Long Should a Function Be? — Adam Tornhill](https://adamtornhill.substack.com/p/how-long-should-a-function-be-and) and [Welcome to Code for Humans and Machines](https://adamtornhill.substack.com/p/welcome-to-code-for-humans-and-machines).

## AST detection

| Ecosystem | Command | Signal |
|---|---|---|
| Polyglot | `ast-grep -p 'function process$_($$$) { $$$ }' <file>` (and variants per noise word) | Function name starts with / equals a noise word |
| Polyglot | `grep -nE '\\b(process|handle|manage|do|make|execute|helper|util|manager|processor)[A-Z]?[a-zA-Z]*\\s*\\(' <file>` | Cheap textual screen |
| Node / TS | `eslint --rule '{"id-denylist": ["error", "data", "info", "item", "value", "result", "temp", "obj"]}' <file>` | Forbidden identifiers |

Use the screen to nominate candidates. Names that pass the screen still need the LM pass — `processPayment` may be fine, `process(input)` is not.

## LM-fallback detection

For each candidate identifier (function, class, variable), ask:

- Could you rename it to something that mentions a domain concept and the code still type-check?
- Does the name describe the *what* (`Order`, `Refund`, `LedgerEntry`) rather than the *machinery* (`Processor`, `Handler`, `Manager`)?
- For a function: does the verb describe a domain action (`charge`, `cancel`, `dispatch`) rather than a generic verb (`process`, `do`, `handle`)?
- If the identifier appears in many unrelated contexts, it is probably too generic.

Skip when the noise word has a precise technical meaning in context (e.g. `EventHandler` in a UI framework callback signature).

## Refactor recipe

1. Identify the domain concept the identifier represents — ask the surrounding code, the tests, the schema, the user.
2. `Rename Function` / `Rename Variable` / `Rename Class` (Fowler).
3. If the rename reveals the identifier was juggling multiple concepts, do `Extract Method` / `Extract Class` first, then rename each piece.

Fowler refactorings via the `refactoring` skill:

- `Rename Function`, `Change Function Declaration`, `Extract Class` (when one name was hiding two concepts)

## When not to apply

- The identifier is genuinely generic by design: framework hooks (`handle(event)`), test fixtures, mathematical operations on abstract values.
- The codebase already uses the noise word consistently as a deliberate convention (e.g. `*Service` everywhere in a Spring app) — rename the convention itself, not one outlier, or leave it.
- Renaming would create a misleading domain term you cannot defend with a citation from the domain.
