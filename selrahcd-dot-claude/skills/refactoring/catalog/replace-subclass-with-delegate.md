# Replace Subclass with Delegate

## Motivation
Inheritance was the right tool yesterday, but the subclass needs to vary along an axis the parent did not anticipate, or the subclass relationship is restrictive (single inheritance) when the variation should be composable. Replacing inheritance with delegation restores flexibility.

## When NOT to use
When inheritance models the relationship cleanly and the cost of indirection adds no value. When you need polymorphic substitutability across many call sites and a delegate would require manual dispatch.

## Mechanics
1. Create a delegate class for the variation the subclass represents. Move the subclass-specific data and methods to it.
2. In the parent class, add a field for the delegate and a constructor argument or factory to set it. 🧪
3. For each method overridden in the subclass, add a delegating method in the parent that calls the delegate.
4. Migrate callers from subclass instances to parent instances configured with the delegate. 🧪
5. Once no callers use the subclass directly, delete the subclass. 🧪

## Example
Before: `Booking` with `PremiumBooking extends Booking`.
After: `Booking` with an optional `PremiumDelegate`; `new Booking(...)` or `new Booking(..., new PremiumDelegate(...))`.

## Common pitfalls
- Trying to remove the inheritance and add the delegate in one commit.
- Implementing the delegate as a parallel class hierarchy of its own, recreating the problem.
- Leaving the subclass around as a "convenience" — defer cleanup and the migration drifts.
