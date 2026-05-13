# Hide Delegate

## Motivation
A client reaches through a server object to call methods on a delegate. The client now depends on the chain. Hiding the delegate behind methods on the server collapses that dependency.

## When NOT to use
When the delegate is part of the server's public contract by intent (e.g., exposing a collection). When wrapping every delegate method would balloon the server's interface (consider whether the server is doing too much).

## Mechanics
1. For each method on the delegate that clients call via the server, create a delegating method on the server.
2. Run a static check.
3. Update each client to call the new method on the server instead of reaching through. 🧪
4. Once no client reaches through, remove the server's accessor for the delegate (or restrict it). 🧪

## Example
Before:
```
manager = aPerson.department.manager;
```
After:
```
manager = aPerson.manager;
```

## Common pitfalls
- Wrapping every delegate method, producing a server with a sprawling interface that mirrors the delegate.
- Removing the delegate accessor before all clients are migrated.
- Hiding a delegate when the cleaner refactoring is to move the client's logic onto the server (or vice versa).
