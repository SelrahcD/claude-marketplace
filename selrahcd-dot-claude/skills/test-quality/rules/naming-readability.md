# Naming & Readability

Test names and code should communicate intent clearly using domain language.

## Behavior-Focused Names

Test names describe **what the system does**, not how it does it.

```typescript
// ❌ Bad: Implementation-focused
test('pushes item to array');
test('calls reduce on items');
test('sets isValid to true');
test('maps over collection');

// ✅ Good: Behavior-focused
test('adding product shows product in cart');
test('cart total sums all product prices');
test('valid email address is accepted');
test('search returns matching recipes');
```

## Domain Vocabulary

Use business/domain terms, not technical terms.

```typescript
// ❌ Bad: Technical vocabulary
test('array contains element after push');
test('map returns undefined for missing key');
test('reduces list to single value');

// ✅ Good: Domain vocabulary
test('cart contains product after adding');
test('unknown ingredient returns no recipes');
test('order total includes all item prices');
```

## Vocabulary Alignment

The terms in the test name should appear in the test body.

```typescript
// ❌ Bad: Name and body use different terms
test('premium members receive free shipping', () => {
  const user = createUser({ type: 'gold' }); // "gold" not "premium"
  const order = createOrder(user);
  expect(order.deliveryCost).toBe(0); // "deliveryCost" not "shipping"
});

// ✅ Good: Consistent vocabulary
test('premium members receive free shipping', () => {
  const premiumMember = createMember({ membership: 'premium' });
  const order = createOrder(premiumMember);

  expect(order.shippingCost).toBe(0);
});
```

## Custom Assertions

Extract repeated assertion patterns into custom matchers for clarity.

```typescript
// ❌ Bad: Repetitive, unclear intent
test('successful response', () => {
  expect(response.status).toBe(200);
  expect(response.headers['content-type']).toContain('application/json');
  expect(response.body).toBeDefined();
});

test('another successful response', () => {
  expect(response.status).toBe(200);
  expect(response.headers['content-type']).toContain('application/json');
  expect(response.body).toBeDefined();
});

// ✅ Good: Custom assertion with clear intent
function expectSuccessfulJsonResponse(response: Response) {
  expect(response.status).toBe(200);
  expect(response.headers['content-type']).toContain('application/json');
  expect(response.body).toBeDefined();
}

test('fetch user returns successful response', () => {
  const response = fetchUser('123');

  expectSuccessfulJsonResponse(response);
  expect(response.body.name).toBe('Alice');
});
```

## Clear Failure Messages

When a test fails, the message should explain what went wrong.

```typescript
// ❌ Bad: Unclear failure message
expect(result).toBe(true);
// Failure: expected false to be true

// ✅ Good: Clear failure message
expect(user.canAccessPremiumContent()).toBe(true);
// Failure: expected canAccessPremiumContent() to be true

// ✅ Even better: Custom message
expect(user.canAccessPremiumContent()).toBe(
  true,
  `Premium member should access premium content, but membership was: ${user.membership}`
);
```

## Descriptive Test Blocks

Use `describe` blocks to group related tests and provide context.

```typescript
// ✅ Good: Hierarchical organization
describe('ShoppingCart', () => {
  describe('when empty', () => {
    test('has zero total', () => {
      /* ... */
    });
    test('has no items', () => {
      /* ... */
    });
  });

  describe('when adding products', () => {
    test('increases total by product price', () => {
      /* ... */
    });
    test('shows product in items list', () => {
      /* ... */
    });
  });

  describe('when applying discount', () => {
    test('reduces total by discount percentage', () => {
      /* ... */
    });
    test('rejects invalid discount codes', () => {
      /* ... */
    });
  });
});
```

## Checklist

- [ ] Test names describe behavior, not implementation
- [ ] Using domain vocabulary, not technical terms
- [ ] Terms in test name match terms in test body
- [ ] Repeated assertions extracted to custom matchers
- [ ] Failure messages clearly explain what went wrong
- [ ] Related tests grouped in describe blocks
- [ ] Test names form readable sentences
