# Refactoring Catalog

Each entry: `[Refactoring Name](file.md) — one-sentence description of when to use it`.

## Composing methods
- [Extract Method](extract-method.md) — Turn a code fragment into its own method when the fragment needs naming or reuse.
- [Inline Method](inline-method.md) — Replace a method call with its body when the method's name no longer adds clarity.
- [Extract Variable](extract-variable.md) — Name a sub-expression to make intent explicit.
- [Inline Variable](inline-variable.md) — Replace a variable with its expression when the name doesn't earn its place.

## Moving features
- [Move Function](move-function.md) — Relocate a function closer to the data it operates on.
- [Move Field](move-field.md) — Relocate a field to the class that uses it most.

## Organizing data
- [Encapsulate Variable](encapsulate-variable.md) — Wrap a variable in accessor methods to control how it's read and changed.
- [Replace Primitive with Object](replace-primitive-with-object.md) — Promote a primitive carrying behavior into its own type.

## Simplifying conditionals
- [Decompose Conditional](decompose-conditional.md) — Extract each branch and condition into named methods.
- [Replace Conditional with Polymorphism](replace-conditional-with-polymorphism.md) — Move type-based branching into subclasses.

## Refactoring APIs
- [Rename Function](rename-function.md) — Change a name that no longer reflects what it does.
- [Introduce Parameter Object](introduce-parameter-object.md) — Bundle related parameters into a single object.
- [Change Function Declaration](change-function-declaration.md) — Modify name, parameters, or return shape of a function.

## Dealing with inheritance
- [Extract Superclass](extract-superclass.md) — Pull shared code from sibling classes into a parent.
- [Replace Subclass with Delegate](replace-subclass-with-delegate.md) — Swap inheritance for composition when inheritance no longer fits.

## Larger restructurings
- [Extract Class](extract-class.md) — Split a class doing too much into two collaborating classes.
- [Hide Delegate](hide-delegate.md) — Hide a client's knowledge of a delegate behind the server.
