# Inline Method

## Motivation
A method's body is as clear as its name, or the indirection it provides no longer earns its keep. Inlining removes a hop the reader doesn't need.

## When NOT to use
When the method is polymorphic (subclasses override it). When the method is called from many places — inlining each call site is expensive and may not improve clarity.

## Mechanics
1. Check the method is not polymorphic.
2. Find all callers.
3. Replace each call with the method's body. 🧪
4. Test after each replacement.
5. Once all callers are inlined, delete the original method. 🧪

## Example
Before:
```
function rating(driver) {
  return moreThanFiveLateDeliveries(driver) ? 2 : 1;
}
function moreThanFiveLateDeliveries(driver) {
  return driver.numberOfLateDeliveries > 5;
}
```
After:
```
function rating(driver) {
  return driver.numberOfLateDeliveries > 5 ? 2 : 1;
}
```

## Common pitfalls
- Inlining a method whose body has side effects that interact with the caller's context.
- Inlining a method called from many places at once instead of one at a time.
- Forgetting to delete the original after the last call site is inlined.
