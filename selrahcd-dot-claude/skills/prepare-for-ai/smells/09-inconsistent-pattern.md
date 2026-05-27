# Inconsistent pattern

## What it is

The same problem is solved two (or more) different ways in different parts of the codebase. Agents and humans cannot rely on convention — they must check which variant is in play before they can predict behaviour or copy from another site.

Citation: [Welcome to Code for Humans and Machines — Adam Tornhill](https://adamtornhill.substack.com/p/welcome-to-code-for-humans-and-machines) (the "predictability" requirement).

## AST detection

This smell is almost exclusively semantic — no linter can decide that two implementations solve the same problem. Tooling can only narrow the search:

| Ecosystem | Command | Signal |
|---|---|---|
| Polyglot | `ast-grep -p 'switch ($X) { case $_: return $_; $$$ }' <root>` and `ast-grep -p 'Map.of($$$)' <root>` | Both forms in use for similar lookups — candidate for normalisation |
| Polyglot | `grep -rnE 'try \{' <root> \| wc -l` vs `grep -rnE 'Result<' <root> \| wc -l` | Mixed error-handling styles |
| Polyglot | `grep -rnE '(new Date\\(|Instant\\.now\\(\\)|Clock\\.systemUTC)' <root>` | Mixed time sources |

Use these to *find pairs to compare*. The judgement is LM.

## LM-fallback detection

Pick a problem and look for two solutions. Strong candidates:

- **Dispatch**: switch in one place, polymorphism in another, map lookup in a third — all for the same kind of selection.
- **Error handling**: exceptions in one module, `Result`/`Either` in another, sentinel return values in a third.
- **Validation**: in the constructor in one module, in a separate validator class in another, inline at call sites in a third.
- **Time**: `new Date()` here, an injected `Clock` there.
- **ID generation**: database auto-increment in one place, UUID v4 in another, application-side typed IDs in a third.
- **Persistence access**: repository pattern in one slice, raw query builders in another.

For each candidate, ask: is there a deliberate reason for the difference (different requirements, different historical context)? If not, the difference is accidental — and accidental difference is the smell.

## Refactor recipe

1. Decide which variant is the convention. Prefer the one that aligns with the project's stated style (CLAUDE.md, ADRs, dominant pattern by count).
2. Migrate outliers to the convention, one site at a time.
3. If neither variant is clearly better, write the choice down (CLAUDE.md or an ADR) before migrating — the value is the convention, not the variant.

Fowler refactorings via the `refactoring` skill:

- Variable per site: usually `Rename Function` + `Change Function Declaration` + `Move Function`, or a full `Replace Conditional with Polymorphism` if the outlier is structurally different.

## When not to apply

- The variants exist for legitimate reasons (different SLAs, different external constraints, deliberate experimentation). Record the reason, do not flatten.
- The codebase is mid-migration from one variant to another and the inconsistency is temporary — accelerate the migration, don't pick the losing variant.
- The "inconsistency" is across bounded contexts that are meant to be independent. Variation across contexts is fine; variation within a context is the smell.
