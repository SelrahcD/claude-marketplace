# Introduce Parameter Object

## Motivation
A group of parameters travels together to many functions. Bundling them into an object names the cluster, reduces parameter-list noise, and creates a home for related behavior.

## When NOT to use
When the parameters genuinely have no shared meaning. When the cluster is used in only one place.

## Mechanics
1. Create a class to represent the cluster. Make it value-like (immutable, equals by content).
2. Run a static check.
3. Apply Change Function Declaration on each function that takes the cluster: add the new parameter object as a parameter, retaining the old parameters for now. 🧪
4. Update each caller to pass the new parameter object alongside the old arguments. 🧪
5. Migrate the function body to read from the new parameter object. 🧪
6. Apply Change Function Declaration again to remove the old parameters. 🧪
7. Move related behavior onto the new class as a follow-up (a separate refactoring).

## Example
Before: `withinRange(date, start, end)` and `findReadingsInRange(reading, start, end)` both take `start` and `end`.
After: `DateRange` class; `withinRange(date, range)` and `findReadingsInRange(reading, range)`.

## Common pitfalls
- Bundling parameters that travel together by coincidence rather than concept.
- Moving behavior onto the new class in the same commit — that's a separate Move Function step.
- Creating a mutable parameter object that leaks state across calls.
