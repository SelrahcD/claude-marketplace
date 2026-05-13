# Decompose Conditional

## Motivation
A conditional is hard to read because each branch and the condition itself are inline blocks of logic. Extracting each into a well-named method turns the conditional into a readable summary of intent.

## When NOT to use
When the conditional and its branches are already one-liners that read clearly.

## Mechanics
1. Apply Extract Method to the condition. 🧪
2. Apply Extract Method to the then-branch. 🧪
3. Apply Extract Method to the else-branch (or each branch in an if/else-if chain). 🧪

## Example
Before:
```
if (date.before(SUMMER_START) || date.after(SUMMER_END))
  charge = quantity * winterRate + winterServiceCharge;
else
  charge = quantity * summerRate;
```
After:
```
if (notSummer(date))
  charge = winterCharge(quantity);
else
  charge = summerCharge(quantity);
```

## Common pitfalls
- Extracting predicates with names that restate the logic instead of its meaning.
- Stopping at the condition without extracting the branches — the inline branches still mask intent.
- Producing methods so small the call overhead dominates readability — group when natural.
