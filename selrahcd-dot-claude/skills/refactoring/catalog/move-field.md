# Move Field

## Motivation
A field is more used by another class than by its current owner, or it logically belongs with another class's data. Move it so reads and writes happen where the data conceptually lives.

## When NOT to use
When access patterns are evenly split. When moving would force breaking encapsulation elsewhere.

## Mechanics
1. Ensure the field is encapsulated (has accessor methods). If not, apply Encapsulate Variable first.
2. Test. 🧪
3. Create the field in the target class with corresponding accessors.
4. Run a static check.
5. Update accessors in the source class to delegate to the target. 🧪
6. Examine callers. Where appropriate, update them to access the field via the target directly.
7. Remove the field from the source class. 🧪

## Example
Before: `Customer.discountRate` is read mostly by `CustomerContract`.
After: `CustomerContract.discountRate`, and `Customer.discountRate` is gone.

## Common pitfalls
- Moving without encapsulating first — direct field access scattered across callers makes the move risky.
- Forgetting to update persistence/serialization code that referenced the old location.
- Stopping after the delegate step, leaving the field "moved" but still living in two places.
