# Encapsulate Variable

## Motivation
A variable (field, module-level data) is accessed directly from many places. Wrapping access in getter/setter functions gives a single point to add validation, logging, or change the underlying storage later.

## When NOT to use
When the variable is genuinely local and short-lived. When the language already enforces controlled access (e.g., a private final field in a value object).

## Mechanics
1. Create get and set functions for the variable.
2. Run a static check.
3. Replace each reference to the variable with the appropriate function call, one at a time. 🧪
4. Restrict the visibility of the variable (private). 🧪
5. If the variable is a mutable structure, decide whether the getter should return a copy.

## Example
Before:
```
let defaultOwner = { firstName: "Martin", lastName: "Fowler" };
```
After:
```
let defaultOwnerData = { firstName: "Martin", lastName: "Fowler" };
function defaultOwner() { return defaultOwnerData; }
function setDefaultOwner(arg) { defaultOwnerData = arg; }
```

## Common pitfalls
- Returning a reference to a mutable internal structure, letting callers bypass the setter.
- Not migrating all references before restricting visibility — easy in dynamic languages.
- Encapsulating immutable primitives where the indirection adds noise without value.
