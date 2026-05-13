# Change Function Declaration

## Motivation
A function's signature (name, parameters, return shape) no longer fits how it is used. Reshaping the declaration is the most fundamental refactoring on a function's interface and underlies many other refactorings.

## When NOT to use
When the function is part of a published API consumed by code you cannot update — apply a migration variant instead.

## Mechanics
**Simple change (few callers):**
1. If removing a parameter, ensure it isn't used in the body.
2. Make the declaration change.
3. Update each caller. 🧪

**Migration change (many callers):**
1. If the body needs to change, apply Extract Function on the body first to isolate it.
2. Apply Change Function Declaration to the extracted inner function.
3. Have the outer function call the inner with adapted arguments. 🧪
4. Migrate callers one at a time to the new signature. 🧪
5. When no callers remain on the outer function, remove it. 🧪
6. Optionally rename the inner function to the outer's old name.

## Example
Before: `circum(radius)`.
After: `circumference(radius)` (name change) or `circumference(radius, unit)` (parameter addition).

## Common pitfalls
- Combining a name change and a parameter change in one commit — split them.
- Forgetting reflective or dynamic callers (templates, DI containers, serialized configs).
- Migrating callers in bulk instead of one at a time, losing the ability to commit small reviewable steps.
