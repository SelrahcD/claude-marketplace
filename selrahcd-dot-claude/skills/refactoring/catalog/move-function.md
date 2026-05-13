# Move Function

## Motivation
A function references data or behavior from another module more than from its own. Moving the function closer to what it uses reduces coupling and clarifies responsibility.

## When NOT to use
When the function uses data from both modules roughly equally. When moving would create a circular dependency between modules.

## Mechanics
1. Examine all program elements used by the function in its current location. Decide whether they should move too.
2. Check the function is not polymorphic (or handle all overrides).
3. Copy the function to its target context. Adjust it to fit (rename if needed, adjust parameter list).
4. Compile in the target context.
5. Work out how to reference the moved function from the source. Replace the function body in the source with a call to the moved function (or remove it entirely if no callers remain in the source). 🧪
6. Decide whether to keep the source function as a forwarding shim or remove it.
7. Update all callers to call the function in its new location. 🧪
8. Once no callers remain in the source, delete the shim. 🧪

## Example
Before: `Account.overdraftCharge()` accesses only fields on `AccountType`.
After: the method lives on `AccountType` as `overdraftCharge()`, and `Account` calls `this.type.overdraftCharge()`.

## Common pitfalls
- Moving a function whose surrounding context (logging, error handling, transaction boundary) is more relevant than its data references.
- Leaving forwarding shims indefinitely — they should be temporary scaffolding, not permanent.
- Moving without checking polymorphism, breaking subclass overrides.
