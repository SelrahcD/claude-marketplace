# Rename Function

## Motivation
A function's name no longer reflects what it does (it has drifted, or was wrong from the start). A clear name is the most direct documentation a function can have.

## When NOT to use
When the function has many external callers you cannot update atomically and renaming would break them — apply a wider migration strategy instead.

## Mechanics
**Simple case (few callers, all internal):**
1. If the function is polymorphic, decide whether to rename all overrides at once.
2. Rename the function.
3. Find every caller. Update each. 🧪

**Migration case (many callers or an external API):**
1. Add a new function with the new name. Have its body call the old function. 🧪
2. Migrate callers one at a time to the new name. 🧪
3. Once no callers remain on the old name, remove the old function. 🧪

## Example
Before: `calc()` is called from twelve places. The function computes a customer's tier discount.
After: `tierDiscountFor(customer)`.

## Common pitfalls
- Renaming via IDE refactor across a polyglot codebase where some callers (templates, configs, reflection) are missed.
- Choosing a name that is technically accurate but obscure to the team.
- Renaming and changing the function's behavior in the same commit.
