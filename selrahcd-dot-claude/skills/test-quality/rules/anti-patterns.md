# Anti-Patterns

Common test anti-patterns to detect and fix.

## Logic in Tests

Tests should not contain conditional logic, loops, or try-catch blocks.

```typescript
// ❌ Bad: Conditional in test
test('handles all user types', () => {
  for (const type of ['admin', 'user', 'guest']) {
    const user = createUser({ type });
    if (type === 'admin') {
      expect(user.canDelete()).toBe(true);
    } else {
      expect(user.canDelete()).toBe(false);
    }
  }
});

// ✅ Good: Separate tests, no logic
test('admin can delete', () => {
  const admin = createUser({ type: 'admin' });

  expect(admin.canDelete()).toBe(true);
});

test('regular user cannot delete', () => {
  const user = createUser({ type: 'user' });

  expect(user.canDelete()).toBe(false);
});

test('guest cannot delete', () => {
  const guest = createUser({ type: 'guest' });

  expect(guest.canDelete()).toBe(false);
});
```

```typescript
// ❌ Bad: Try-catch hiding failures
test('throws on invalid input', () => {
  try {
    processInput(null);
    fail('Should have thrown');
  } catch (e) {
    expect(e.message).toContain('invalid');
  }
});

// ✅ Good: Use assertion for exceptions
test('throws on invalid input', () => {
  expect(() => processInput(null)).toThrow('invalid');
});
```

## Test Interdependence

Tests must not depend on other tests running first.

```typescript
// ❌ Bad: Tests depend on order
describe('user workflow', () => {
  let userId: string;

  test('creates user', async () => {
    const user = await createUser({ name: 'Alice' });
    userId = user.id; // Stored for next test
    expect(user).toBeDefined();
  });

  test('updates user', async () => {
    // Fails if previous test didn't run!
    await updateUser(userId, { name: 'Bob' });
  });
});

// ✅ Good: Each test is independent
test('creates user with name', async () => {
  const user = await createUser({ name: 'Alice' });

  expect(user.name).toBe('Alice');
});

test('updates user name', async () => {
  const user = await createUser({ name: 'Alice' });

  await updateUser(user.id, { name: 'Bob' });

  const updated = await getUser(user.id);
  expect(updated.name).toBe('Bob');
});
```

## Over-Mocking

Don't mock everything. Don't mock what you don't own. Don't mock value objects.

```typescript
// ❌ Bad: Mocking value objects
test('calculates order total', () => {
  const mockMoney = { amount: 100, currency: 'USD' };
  const mockItem = { price: mockMoney, quantity: 2 };
  // Over-complicated, hard to understand
});

// ✅ Good: Use real value objects
test('calculates order total', () => {
  const item = createOrderItem({ price: 100, quantity: 2 });
  const order = createOrder({ items: [item] });

  expect(order.total()).toBe(200);
});
```

```typescript
// ❌ Bad: Mocking third-party library internals
test('parses date', () => {
  // Mocking date-fns internals - fragile, couples to library
});

// ✅ Good: Wrap third-party behind your own interface
interface DateParser {
  parse(dateString: string): Date;
}

class DateFnsDateParser implements DateParser {
  parse(dateString: string): Date {
    return dateFns.parse(dateString, 'yyyy-MM-dd', new Date());
  }
}

// In tests, use a stub
class StubDateParser implements DateParser {
  private result: Date = new Date();

  givenParsedDate(date: Date): void {
    this.result = date;
  }

  parse(_dateString: string): Date {
    return this.result;
  }
}
```

## Implementation-Focused Tests

Tests should verify behavior, not implementation details.

```typescript
// ❌ Bad: Testing implementation
test('stores items in array', () => {
  const cart = createCart();
  cart.add(product);
  expect(cart._items).toEqual([product]); // Testing internal structure
});

test('calls forEach on items', () => {
  // Testing how, not what
});

// ✅ Good: Testing behavior
test('added product appears in cart', () => {
  const cart = createCart();
  const product = createProduct();

  cart.add(product);

  expect(cart.contains(product)).toBe(true);
});

test('total equals sum of product prices', () => {
  const cart = createCart();
  cart.add(createProduct({ price: 10 }));
  cart.add(createProduct({ price: 20 }));

  expect(cart.total()).toBe(30);
});
```

## Assertion Roulette

Tests with many unrelated assertions - unclear what's being tested.

```typescript
// ❌ Bad: Assertion roulette
test('user operations', () => {
  const user = createUser();
  expect(user.id).toBeDefined();
  expect(user.name).toBe('Default');
  expect(user.email).toContain('@');
  expect(user.isActive).toBe(true);
  expect(user.roles).toHaveLength(0);
  expect(user.createdAt).toBeInstanceOf(Date);
});

// ✅ Good: Focused tests
test('new user has generated id', () => {
  const user = createUser();

  expect(user.id).toBeDefined();
});

test('new user is active by default', () => {
  const user = createUser();

  expect(user.isActive).toBe(true);
});

test('new user has no roles', () => {
  const user = createUser();

  expect(user.roles).toHaveLength(0);
});
```

## Flaky Tests

Tests that sometimes pass and sometimes fail.

Common causes:

- Timing dependencies
- Order dependencies
- Shared state
- Real external services
- Uncontrolled randomness

```typescript
// ❌ Bad: Timing-dependent
test('debounces input', async () => {
  input.type('hello');
  await sleep(100); // Might not be enough!
  expect(handler).toHaveBeenCalledTimes(1);
});

// ✅ Good: Controlled timing via clock
test('debounces input', async () => {
  const clock = new ControllableClock();
  const debouncer = new Debouncer(clock, 100);
  const spy = new SpyHandler();

  debouncer.call(spy.handle);
  clock.advance(100);

  expect(spy.callCount()).toBe(1);
});
```

## Checklist

- [ ] No conditionals (if/else) in tests
- [ ] No loops (for/while) in tests
- [ ] No try-catch blocks (use `.toThrow()`)
- [ ] Tests don't depend on execution order
- [ ] Not mocking value objects
- [ ] Not mocking third-party library internals
- [ ] Testing behavior, not implementation
- [ ] Single focus per test (no assertion roulette)
- [ ] No flaky/intermittent failures
- [ ] No real time delays (`sleep`, `setTimeout`)
