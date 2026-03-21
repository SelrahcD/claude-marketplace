---
name: design-principles
description: Knowledge base of design principles covering CQS, Hexagonal Architecture, DDD patterns, identity management, naming conventions, and OOP discipline. Used as reference by design review agents.
---

# Design Principles Knowledge Base

## 1. Command Query Separation (CQS)

### Rules

- Methods either change state (command) or return data (query), never both.
- Commands return `void`. They perform side effects but produce no return value.
- Queries have no side effects. Calling a query twice yields the same result.
- Factory methods are the accepted exception: they create and return a new object without modifying existing state.

### Violation examples

- `addItemAndReturnTotal(item: Item): number` -- changes state AND returns data. Split into `addItem(item: Item): void` and `getTotal(): number`.
- A `save(entity: Entity): string` method that persists and returns the generated ID. The caller should provide the ID upfront; `save` should return `void`.
- `stack.pop(): Item` -- mutates the stack and returns the removed element. Separate into `peek(): Item` (query) and `remove(): void` (command).

## 2. Hexagonal Architecture

### Rules

- The domain sits at the center with zero infrastructure dependencies.
- Ports are interfaces defined by the domain to express its needs (driven ports) or its entry points (driving ports).
- Adapters live in the infrastructure layer and implement ports.
- Dependency direction is always outer toward inner -- infrastructure depends on domain, never the reverse.
- No framework annotations (`@Injectable`, `@Entity`, decorators) in domain code.
- The application layer orchestrates use cases by coordinating domain objects and ports.
- Tests must be runnable without infrastructure (databases, HTTP, file system) by substituting adapters with in-memory or stub implementations.

### Violation examples

- A domain entity importing `TypeORM` decorators: `@Entity() class Order { @Column() status: string }`. The domain now depends on infrastructure.
- A domain service directly calling `fetch()` or `axios.get()` instead of depending on a port interface like `HttpClient`.
- An application service that instantiates a concrete `PostgresOrderRepository` instead of receiving an `OrderRepository` port via constructor injection.
- A domain model importing `express.Request` to validate input -- the domain should receive already-validated value objects from the application layer.

## 3. DDD Tactical Patterns

### Rules

**Aggregates**
- Protect domain invariants -- all state changes go through the aggregate root.
- Define a consistency boundary: everything inside is guaranteed consistent after each operation.
- External access only through the aggregate root, never by reaching into child entities.
- Keep aggregates small. If an aggregate grows large, look for a missing boundary.
- Reference other aggregates by ID, not by direct object reference.

**Value Objects**
- Immutable once created.
- Compared by value, not by reference or identity.
- Carry domain behavior (validation, computation) rather than being plain data holders.

**Entities**
- Have a stable identity that persists across state changes.
- State changes happen through methods that enforce invariants.
- No public setters that allow bypassing business rules.

**Domain Events**
- Named in past tense reflecting something that happened: `OrderShipped`, `PaymentReceived`.
- Use ubiquitous language from the domain, not technical jargon.
- Avoid vague names like `OrderUpdated`, `DataChanged`, `EntityModified`.

**Repositories**
- One repository per aggregate root.
- The repository interface is defined in the domain layer.
- The repository implementation lives in the infrastructure layer.

### Violation examples

- Accessing a child entity directly: `order.lineItems[0].changeQuantity(5)` instead of `order.changeLineItemQuantity(lineItemId, 5)`. The aggregate root must mediate.
- A value object with a setter: `class Money { setAmount(n: number) { this.amount = n } }`. Value objects are immutable -- create a new instance instead.
- An entity with a public setter that skips validation: `order.status = "shipped"` instead of `order.ship()` which checks preconditions.
- A domain event named `OrderUpdated` -- what was updated? Use `OrderShipped`, `OrderCancelled`, or `ShippingAddressChanged` instead.
- A repository for a child entity: `LineItemRepository`. Line items are part of the Order aggregate and should be persisted through `OrderRepository`.

## 4. DDD Strategic Patterns

### Rules

- Define bounded contexts with explicit boundaries. Each context has its own model, its own language, and its own rules.
- Maintain a ubiquitous language within each bounded context -- the same term means the same thing everywhere inside that context.
- Different bounded contexts may have different models for the same real-world concept. A `Product` in the Catalog context is not the same as a `Product` in the Shipping context.
- Use context mapping to define relationships between contexts:
  - **Anti-Corruption Layer (ACL)**: translate between contexts to prevent one model from leaking into another.
  - **Shared Kernel**: a small, explicitly shared subset of the model that two contexts agree on.
  - **Published Language**: a well-documented, versioned language (schema) for inter-context communication.

### Violation examples

- A single `User` class used across authentication, billing, and social features. Each context should have its own model: `Credentials` (auth), `Customer` (billing), `Profile` (social).
- Directly importing types from another bounded context: `import { Product } from '../catalog/Product'` inside the shipping context. Use an ACL to translate.
- A shared database table that multiple contexts read from and write to without an explicit shared kernel agreement. Changes in one context silently break the other.
- Coupling two contexts by passing rich domain objects across the boundary instead of using a published language (DTOs, events with a defined schema).

## 5. Identity

### Rules

- Use UUIDs generated by the caller or the domain layer, never database auto-increment IDs.
- The creator of an entity decides its ID at construction time. The ID is available immediately, not after persistence.
- Wrap IDs in value objects with a specific type -- not raw `string` or `number`.

### Violation examples

- `class Order { id?: number }` where `id` is optional because it is assigned by the database after insert. The order should have a known `OrderId` from the moment it is created.
- Passing raw strings as IDs: `getOrder(id: string)`. Use a typed value object: `getOrder(id: OrderId)`. This prevents accidentally passing a `CustomerId` where an `OrderId` is expected.
- Relying on `AUTO_INCREMENT` or `SERIAL` for entity identity. The domain cannot generate IDs independently of the database, coupling identity to infrastructure.
- Using a plain `number` for an ID: `findCustomer(id: number)`. Nothing prevents `findCustomer(orderId)` from compiling -- use distinct types.

## 6. Naming

### Rules

- Use domain language everywhere: class names, method names, variables, module names.
- Avoid generic filler names: `data`, `service`, `manager`, `handler`, `helper`, `utils`, `processor`, `info`, `item`, `stuff`, `object`, `thing`.
- Method names express intent and domain meaning: `ship()` not `updateStatus()`, `approve()` not `setApproved(true)`.
- If you cannot name something in domain language, the model is wrong. Naming difficulty is a design signal.

### Violation examples

- `OrderService` -- what does it do? `OrderFulfillment`, `OrderPricing`, or `ShipmentScheduler` each express a clear responsibility.
- `processData(data: any)` -- neither the method name nor the parameter convey meaning. Use `calculateShippingCost(parcel: Parcel)`.
- `UserManager` -- managing what? `AccountRegistration`, `AccessControl`, or `ProfileEditor` describe actual behavior.
- `handleEvent(event: Event)` -- vague. Use `applyDiscount(couponApplied: CouponApplied)` to name the concrete action and event.
- A module named `utils/helpers.ts` collecting unrelated functions. Each function belongs in the domain concept it serves.

## 7. OOP Discipline

### Rules

- No helper or utility classes. Behavior belongs on the objects that own the data.
- No anemic domain models -- objects carry both state and behavior, not just data.
- Tell, don't ask: tell an object to do something rather than extracting its data and deciding externally.
- Keep classes small and focused on a single responsibility.
- Encapsulate internal state. External code should not reach into an object's internals.

### Violation examples

- `OrderHelper.calculateTotal(order: Order)` -- the calculation belongs on `Order` itself: `order.total()`.
- An anemic model: `class Order { status: string; items: Item[]; total: number }` with all logic in a separate `OrderService`. The `Order` class should contain `ship()`, `cancel()`, `addItem()`, etc.
- Ask-then-decide: `if (order.getStatus() === "paid") { order.setStatus("shipped") }`. Instead: `order.ship()` which internally checks preconditions and transitions state.
- A god class `ApplicationController` with 40 methods spanning user management, billing, and reporting. Split into focused classes aligned with bounded contexts.
- Exposing internals: `order.getItems().push(newItem)` allows external code to mutate the order's item list. Provide `order.addItem(newItem)` which enforces invariants.
