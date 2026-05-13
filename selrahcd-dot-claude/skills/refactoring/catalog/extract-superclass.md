# Extract Superclass

## Motivation
Two classes share data and behavior. Pulling the commonality into a superclass names the relationship and removes duplication.

## When NOT to use
When the apparent similarity is shallow and the classes will diverge — composition or a shared utility may fit better.

## Mechanics
1. Create an empty superclass. Make the candidate classes its subclasses.
2. Test. 🧪
3. Pull up a single shared element at a time (Pull Up Field, Pull Up Method, Pull Up Constructor Body), running the safety net after each. 🧪
4. Examine the remaining methods of each subclass to see if more can move up.
5. Look at callers of the subclasses — should any operate on the superclass type instead? 🧪

## Example
Before: `Employee` and `Department` both have `name`, `annualCost`, and `headCount`.
After: `Party` superclass; `Employee` and `Department` extend it.

## Common pitfalls
- Pulling up too much, creating a "god parent" with members not all subclasses need.
- Skipping the per-element pull-up, producing a single huge commit instead of a sequence.
- Forcing inheritance where composition would be cleaner — favor Extract Class first, then decide.
