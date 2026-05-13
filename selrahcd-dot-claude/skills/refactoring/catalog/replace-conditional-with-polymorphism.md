# Replace Conditional with Polymorphism

## Motivation
A conditional dispatches on a type code (or kind tag) at multiple places. Moving each branch into a subclass turns the dispatch into a virtual call, eliminating the conditional and grouping behavior with type.

## When NOT to use
When there is only one such conditional and the cost of introducing a class hierarchy outweighs the readability gain. When the conditional dispatches on something other than type identity (e.g., a numeric range).

## Mechanics
1. If there isn't yet a class hierarchy, introduce one (subclasses for each branch of the conditional). Apply Replace Type Code with Subclasses first if needed.
2. Move the method containing the conditional into the superclass. 🧪
3. Pick one subclass. Override the method in that subclass and copy the matching branch into it. 🧪
4. Repeat for each subclass.
5. Once all branches are overridden, remove the conditional in the superclass method — or make the superclass method abstract. 🧪

## Example
Before:
```
class Bird {
  getSpeed() {
    switch(this.type) {
      case 'EUROPEAN': return 35;
      case 'AFRICAN': return 40 - 2 * this.numberOfCoconuts;
      case 'NORWEGIAN_BLUE': return this.isNailed ? 0 : 10 + this.voltage / 10;
    }
  }
}
```
After: `EuropeanBird`, `AfricanBird`, `NorwegianBlueBird` each override `getSpeed()`.

## Common pitfalls
- Skipping the hierarchy setup; trying to "polymorphize" without polymorphism in place.
- Migrating all branches in one step, producing a commit that touches every subclass at once.
- Leaving the original conditional behind as a default, defeating the point of the refactoring.
