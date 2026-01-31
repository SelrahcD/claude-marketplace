# Dependencies & Control

Tests must control their dependencies to be reliable and deterministic.

## Date and Time Handling

Two approaches to control time in tests:

### Option 1: Pass Date as Parameter

Change the API to accept a date directly. This is often simpler and more explicit.

```typescript
// ❌ Bad: Hidden dependency on current time
function isValid(expirationDate: Date): boolean {
  return expirationDate > new Date();
}

// ✅ Good: Explicit date parameter
function isValidOn(expirationDate: Date, referenceDate: Date): boolean {
  return expirationDate > referenceDate;
}

test('expiration date after reference date is valid', () => {
  const referenceDate = new Date('2024-06-15');
  const expirationDate = new Date('2024-06-20');

  expect(isValidOn(expirationDate, referenceDate)).toBe(true);
});

test('expiration date before reference date is invalid', () => {
  const referenceDate = new Date('2024-06-15');
  const expirationDate = new Date('2024-06-10');

  expect(isValidOn(expirationDate, referenceDate)).toBe(false);
});
```

### Option 2: Inject a Clock

For cases where the "now" concept is central to the behavior.

```typescript
interface Clock {
  now(): Date;
}

class SubscriptionService {
  constructor(private clock: Clock) {}

  isActive(subscription: Subscription): boolean {
    return subscription.expiresAt > this.clock.now();
  }
}

test('subscription expiring in the future is active', () => {
  const clock: Clock = { now: () => new Date('2024-06-15') };
  const service = new SubscriptionService(clock);
  const subscription = createSubscription({ expiresAt: new Date('2024-07-01') });

  expect(service.isActive(subscription)).toBe(true);
});
```

**Choose the approach that makes the API clearer.** Passing a date is often simpler.

## Hexagonal Architecture & Test Doubles

With hexagonal architecture, external dependencies are behind interfaces (ports). For testing, we create our own implementations instead of using mocking frameworks.

### Why No Mocking Frameworks

Mocking frameworks (Jest mocks, Vitest mocks) encourage:

- Setting up expectations before acting (breaks Arrange-Act-Assert)
- Coupling tests to implementation details
- Complex, hard-to-read test setup

Instead, write simple hand-crafted test doubles.

### Exception: Simple Callback Verification

Using `jest.fn()` or `vi.fn()` is acceptable for verifying simple one-shot callbacks, such as React component prop handlers:

```typescript
// ✅ OK: Simple callback verification
test('calls onClick handler when button is clicked', () => {
  const handleClick = jest.fn();
  render(<Button onClick={handleClick}>Click me</Button>);

  fireEvent.click(screen.getByText('Click me'));

  expect(handleClick).toHaveBeenCalledTimes(1);
});

// ✅ OK: Verifying callback arguments
test('calls onChange with new value', () => {
  const handleChange = jest.fn();
  render(<Input onChange={handleChange} />);

  fireEvent.change(screen.getByRole('textbox'), { target: { value: 'hello' } });

  expect(handleChange).toHaveBeenCalledWith('hello');
});
```

This exception applies when:
- The function is a simple callback passed as a prop
- You only need to verify it was called (and optionally with what arguments)
- There's no complex behavior to stub

For anything more complex (services, repositories, APIs), use hand-crafted test doubles.

### Stubs for Indirect Inputs

Stubs provide canned answers to calls made during the test.

```typescript
// Port (interface)
interface PriceService {
  getPrice(productId: string): Promise<number>;
}

// Stub implementation for tests
class StubPriceService implements PriceService {
  private prices = new Map<string, number>();

  givenPrice(productId: string, price: number): void {
    this.prices.set(productId, price);
  }

  async getPrice(productId: string): Promise<number> {
    const price = this.prices.get(productId);
    if (price === undefined) {
      throw new Error(`No price configured for ${productId}`);
    }
    return price;
  }
}

test('calculates order total from product prices', async () => {
  const priceService = new StubPriceService();
  priceService.givenPrice('product-1', 100);
  priceService.givenPrice('product-2', 50);
  const orderService = new OrderService(priceService);

  const total = await orderService.calculateTotal(['product-1', 'product-2']);

  expect(total).toBe(150);
});
```

### Spies for Verification

Spies record calls for later verification. Use spies in the Assert phase, not the Arrange phase.

```typescript
// Port (interface)
interface EmailSender {
  send(to: string, subject: string, body: string): Promise<void>;
}

// Spy implementation for tests
class SpyEmailSender implements EmailSender {
  private sentEmails: Array<{ to: string; subject: string; body: string }> = [];

  async send(to: string, subject: string, body: string): Promise<void> {
    this.sentEmails.push({ to, subject, body });
  }

  // Verification methods
  wasSentTo(email: string): boolean {
    return this.sentEmails.some((e) => e.to === email);
  }

  sentEmailsCount(): number {
    return this.sentEmails.length;
  }

  lastEmail(): { to: string; subject: string; body: string } | undefined {
    return this.sentEmails[this.sentEmails.length - 1];
  }
}

test('sends welcome email after registration', async () => {
  const emailSender = new SpyEmailSender();
  const userService = new UserService(emailSender);

  await userService.register({ email: 'alice@example.com', name: 'Alice' });

  expect(emailSender.wasSentTo('alice@example.com')).toBe(true);
  expect(emailSender.lastEmail()?.subject).toContain('Welcome');
});
```

### Fakes for Complex Collaborators

Fakes are working implementations suitable for testing.

```typescript
// Port (interface)
interface UserRepository {
  save(user: User): Promise<void>;
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
}

// Fake implementation for tests
class InMemoryUserRepository implements UserRepository {
  private users = new Map<string, User>();

  async save(user: User): Promise<void> {
    this.users.set(user.id, user);
  }

  async findById(id: string): Promise<User | null> {
    return this.users.get(id) || null;
  }

  async findByEmail(email: string): Promise<User | null> {
    for (const user of this.users.values()) {
      if (user.email === email) return user;
    }
    return null;
  }

  // Test helper
  givenUser(user: User): void {
    this.users.set(user.id, user);
  }
}
```

## Arrange-Act-Assert with Test Doubles

Test doubles should support the AAA pattern:

```typescript
test('notifies user when order is shipped', async () => {
  // Arrange
  const emailSender = new SpyEmailSender();
  const orderRepo = new InMemoryOrderRepository();
  const user = createUser({ email: 'alice@example.com' });
  const order = createOrder({ userId: user.id, status: 'processing' });
  orderRepo.givenOrder(order);
  const service = new ShippingService(orderRepo, emailSender);

  // Act
  await service.shipOrder(order.id);

  // Assert
  expect(emailSender.wasSentTo('alice@example.com')).toBe(true);
  expect(emailSender.lastEmail()?.subject).toContain('shipped');
});
```

**Notice:** Verification happens in Assert phase, not Arrange phase. This is why we use spies, not mocks.

## Deterministic Execution

Tests must produce the same result every time:

- Pass dates explicitly instead of using `new Date()`
- Seed random generators when randomness affects assertions
- Use stubs/fakes instead of real external services

```typescript
// ✅ Good: Deterministic with explicit date
test('subscription expires on exact date', () => {
  const expirationDate = new Date('2024-06-15T00:00:00Z');
  const checkDate = new Date('2024-06-15T00:00:00Z');

  expect(isExpiredOn(expirationDate, checkDate)).toBe(true);
});
```

## Checklist

- [ ] Time handled via explicit date parameter or injected clock
- [ ] No `new Date()` or `Date.now()` in code under test
- [ ] Using hand-crafted stubs, spies, fakes (no mocking framework)
- [ ] Exception: `jest.fn()`/`vi.fn()` OK for simple callback verification
- [ ] Stubs provide indirect inputs
- [ ] Spies verify interactions in Assert phase
- [ ] Fakes used for complex collaborators
- [ ] Arrange-Act-Assert pattern preserved
- [ ] Tests produce same result on every run
