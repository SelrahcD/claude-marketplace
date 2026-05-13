# Replace Primitive with Object

## Motivation
A primitive (string, number) is carrying meaning and behavior beyond its raw type — comparisons, parsing, validation, formatting. Promoting it to a value object collects that behavior in one place.

## When NOT to use
When the primitive really is just a primitive — a counter, an array index, a temperature reading with no special operations.

## Mechanics
1. Apply Encapsulate Variable on the field that holds the primitive, if not already done.
2. Create a simple value class for the data. Constructor takes the primitive; getter returns it.
3. Run a static check.
4. Change the setter to wrap the incoming primitive in the new class.
5. Change the getter to return the underlying primitive (or the object, depending on consumer needs). 🧪
6. Consider renaming accessors to reflect the new abstraction.
7. Move behavior that operates on the primitive onto the new class. 🧪

## Example
Before: `order.priority = "high"` with string comparisons scattered everywhere.
After: `order.priority = new Priority("high")` with `priority.higherThan(other)` on the class.

## Common pitfalls
- Skipping Encapsulate Variable first, making the migration impossible to do incrementally.
- Making the new class hold so little behavior that it's just a wrapper — defer the promotion until behavior is real.
- Mixing the migration with adding new behavior, breaking the one-refactoring-per-commit rule.
