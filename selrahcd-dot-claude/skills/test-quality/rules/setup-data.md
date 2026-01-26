# Setup & Data

Good test data management avoids repetition and makes tests readable.

## Factories and Builders

Use factories or builders to create test objects. This avoids repetition and makes tests maintainable.

**Naming Convention:** Name factory functions `aSomething` (e.g., `aMember`, `aProduct`, `anOrder`). This makes tests read like stories, improving readability and comprehension.

```typescript
// ❌ Bad: Repetitive inline object creation
test('order with premium member gets free shipping', () => {
  const member = {
    id: '123',
    name: 'Alice',
    email: 'alice@example.com',
    membershipType: 'premium',
    joinedAt: new Date('2024-01-01'),
    preferences: { newsletter: true },
  };
  // ...
});

test('order with standard member pays shipping', () => {
  const member = {
    id: '456',
    name: 'Bob',
    email: 'bob@example.com',
    membershipType: 'standard',
    joinedAt: new Date('2024-02-01'),
    preferences: { newsletter: false },
  };
  // ...
});

// ✅ Good: Factory with "aSomething" naming - reads like a story
function aMember(overrides: Partial<Member> = {}): Member {
  return {
    id: randomId(),
    name: randomName(),
    email: randomEmail(),
    membershipType: 'standard',
    joinedAt: randomPastDate(),
    preferences: { newsletter: false },
    ...overrides,
  };
}

test('order with premium member gets free shipping', () => {
  const member = aMember({ membershipType: 'premium' });
  // Reads as: "a member with premium membership"
  // ...
});
```

## Show Relevant, Hide Irrelevant

**Critical Rule:** Any value that appears in an assertion MUST be visible in the arrange or act phase.

```typescript
// ❌ Bad: Price hidden in factory, assertion uses magic number
function aProduct() {
  return { id: randomId(), name: 'Widget', price: 50 };
}

test('cart total equals product price', () => {
  const cart = anEmptyCart();
  cart.add(aProduct());

  expect(cart.total()).toBe(50); // Where does 50 come from?
});

// ✅ Good: Relevant value visible in test
function aProduct(overrides: Partial<Product> = {}) {
  return {
    id: randomId(),
    name: randomName(),
    price: randomPrice(),
    ...overrides,
  };
}

test('cart total equals product price', () => {
  const price = 50;
  const cart = anEmptyCart();

  cart.add(aProduct({ price }));

  expect(cart.total()).toBe(price);
});
```

## Randomize Irrelevant Data

Data that doesn't affect the assertion should be randomized. This:

- Makes clear what data matters
- Prevents accidental coupling to specific values
- Catches hidden dependencies

```typescript
// ✅ Good: Only price matters, rest is random
function aProduct(overrides: Partial<Product> = {}) {
  return {
    id: randomId(), // Irrelevant - randomize
    name: randomString(), // Irrelevant - randomize
    category: randomCategory(), // Irrelevant - randomize
    price: randomPrice(), // Could be relevant - allow override
    ...overrides,
  };
}

test('discount applies percentage to price', () => {
  const originalPrice = 100;
  const discountPercent = 20;

  const product = aProduct({ price: originalPrice });
  const discounted = applyDiscount(product, discountPercent);

  expect(discounted.price).toBe(80); // 100 - 20%
});
```

## Extract Factories to Shared Files

Factories and builders should be extracted to dedicated files and reused across multiple test files. Do not recreate them in each test file.

```typescript
// ❌ Bad: Factory defined in each test file
// tests/orders.test.ts
function aMember(overrides = {}) { /* ... */ }

// tests/shipping.test.ts
function aMember(overrides = {}) { /* ... */ } // Duplicated!

// ✅ Good: Shared factory file
// tests/factories/member.ts
export function aMember(overrides: Partial<Member> = {}): Member {
  return {
    id: randomId(),
    name: randomName(),
    email: randomEmail(),
    membershipType: 'standard',
    ...overrides,
  };
}

// tests/orders.test.ts
import { aMember } from './factories/member';

// tests/shipping.test.ts
import { aMember } from './factories/member';
```

**Benefits:**
- Single source of truth for test data creation
- Changes to object structure only need updating in one place
- Consistent test data across all test files
- Easier to maintain as the domain model evolves

## Builder Pattern for Complex Objects

For objects with many optional fields, use a builder pattern. Name builders `anX` to maintain story-like readability:

```typescript
// ✅ Good: Builder for complex objects with "anX" naming
const anOrder = () => ({
  _data: {
    id: randomId(),
    customerId: randomId(),
    items: [],
    status: 'pending',
    createdAt: new Date(),
  } as Order,

  withItems(items: OrderItem[]) {
    this._data.items = items;
    return this;
  },

  withStatus(status: OrderStatus) {
    this._data.status = status;
    return this;
  },

  withCustomer(customerId: string) {
    this._data.customerId = customerId;
    return this;
  },

  build() {
    return { ...this._data };
  },
});

test('shipped order cannot be cancelled', () => {
  // Reads as: "an order with status shipped"
  const order = anOrder().withStatus('shipped').build();

  expect(() => order.cancel()).toThrow('Cannot cancel shipped order');
});
```

## Checklist

- [ ] Using factories or builders for object creation
- [ ] Factory/builder functions named `aSomething` (e.g., `aMember`, `aProduct`, `anOrder`)
- [ ] Factories extracted to shared files (not duplicated per test file)
- [ ] No repetitive inline object literals
- [ ] All asserted values visible in arrange/act phase
- [ ] No magic numbers or strings in assertions
- [ ] Irrelevant data randomized
- [ ] Factories allow overriding relevant fields
- [ ] Complex objects use builder pattern
