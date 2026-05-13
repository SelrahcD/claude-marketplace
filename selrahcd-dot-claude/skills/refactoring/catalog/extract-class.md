# Extract Class

## Motivation
A class has grown to hold two distinct responsibilities. Splitting it into two collaborating classes gives each a single reason to change.

## When NOT to use
When the apparent split is along a usage axis but not a conceptual one — wait for the conceptual split to be obvious before separating.

## Mechanics
1. Decide how to split responsibilities. Name the new class by its intent.
2. Create the empty new class.
3. In the source class, add a field referencing an instance of the new class. Initialize it in the constructor. 🧪
4. For each field that belongs to the new class, apply Move Field. 🧪
5. For each method that belongs to the new class, apply Move Function. 🧪
6. Review the public interfaces of both classes. Decide whether the new class is internal (accessed only via the source) or exposed directly to callers.
7. Update callers accordingly. 🧪

## Example
Before: `Person` holds name, address, phone-area, phone-number.
After: `Person` holds name and a `TelephoneNumber`; `TelephoneNumber` holds area, number, and behavior like formatting.

## Common pitfalls
- Moving fields in bulk instead of one at a time — each Move Field is its own commit per this skill's discipline.
- Exposing the new class everywhere when keeping it internal would preserve encapsulation.
- Splitting before the second responsibility is clearly visible, producing a phantom class that re-merges later.
