# Inline Variable

## Motivation
A variable's name adds nothing the expression doesn't already say, or the variable is referenced only once and lives only to be passed along.

## When NOT to use
When the variable name conveys intent the expression alone does not. When the expression is expensive and the variable is referenced multiple times.

## Mechanics
1. Check the right-hand side of the assignment is free of side effects.
2. If the variable is not already declared immutable, make it so and verify nothing reassigns it. 🧪
3. Find the first reference; replace it with the right-hand side.
4. Test. 🧪
5. Repeat for each reference.
6. Remove the variable declaration. 🧪

## Example
Before:
```
const basePrice = anOrder.basePrice;
return basePrice > 1000;
```
After:
```
return anOrder.basePrice > 1000;
```

## Common pitfalls
- Inlining an expression with side effects so it now runs multiple times.
- Inlining a variable whose name was the only documentation of intent.
- Forgetting to delete the original declaration once all references are inlined.
