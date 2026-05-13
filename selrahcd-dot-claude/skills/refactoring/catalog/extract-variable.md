# Extract Variable

## Motivation
A sub-expression is doing real work but its meaning is hidden inside a larger expression. Naming it as a local variable makes the intent explicit and the surrounding code easier to read.

## When NOT to use
When the sub-expression is already trivial. When the variable would be referenced only once and the inline expression is already self-explanatory.

## Mechanics
1. Identify the sub-expression to name.
2. Declare an immutable local variable initialized to that sub-expression.
3. Replace the sub-expression in its original location with the variable. 🧪
4. If the sub-expression appears multiple times in the surrounding code, replace each occurrence. 🧪

## Example
Before:
```
return order.quantity * order.itemPrice -
  Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 +
  Math.min(order.quantity * order.itemPrice * 0.1, 100);
```
After:
```
const basePrice = order.quantity * order.itemPrice;
const quantityDiscount = Math.max(0, order.quantity - 500) * order.itemPrice * 0.05;
const shipping = Math.min(basePrice * 0.1, 100);
return basePrice - quantityDiscount + shipping;
```

## Common pitfalls
- Variable name that restates the mechanism (`a_times_b`) instead of the intent (`basePrice`).
- Extracting too aggressively — every sub-expression is not a variable.
- Mutating the extracted variable later, defeating the readability gain.
