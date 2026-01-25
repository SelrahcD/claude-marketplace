# Test Structure

Well-structured tests are easy to read, maintain, and debug.

## Arrange-Act-Assert Pattern

Every test should have three distinct phases:

1. **Arrange** - Set up test data and dependencies
2. **Act** - Execute the behavior being tested
3. **Assert** - Verify the expected outcome

```typescript
// ✅ Good: Clear AAA structure
test('adding product increases cart total', () => {
  const cart = createEmptyCart();
  const product = createProduct({ price: 25 });

  cart.add(product);

  expect(cart.total()).toBe(25);
});
```

### No Phase Comments

The structure should be clear from the code itself. Do NOT add comments like `// Arrange`, `// Act`, `// Assert`.

```typescript
// ❌ Bad: Explicit phase comments
test('adding product increases cart total', () => {
  // Arrange
  const cart = createEmptyCart();

  // Act
  cart.add(product);

  // Assert
  expect(cart.total()).toBe(25);
});

// ✅ Good: Structure is self-evident, use blank lines to separate
test('adding product increases cart total', () => {
  const cart = createEmptyCart();
  const product = createProduct({ price: 25 });

  cart.add(product);

  expect(cart.total()).toBe(25);
});
```

## One Behavior Per Test

Each test should verify exactly one behavior. If a test could fail for multiple reasons, split it.

```typescript
// ❌ Bad: Multiple behaviors
test('cart operations', () => {
  const cart = createEmptyCart();
  expect(cart.isEmpty()).toBe(true);

  cart.add(product);
  expect(cart.isEmpty()).toBe(false);
  expect(cart.total()).toBe(25);

  cart.remove(product);
  expect(cart.isEmpty()).toBe(true);
});

// ✅ Good: One behavior each
test('new cart is empty', () => {
  const cart = createEmptyCart();

  expect(cart.isEmpty()).toBe(true);
});

test('cart with product is not empty', () => {
  const cart = createEmptyCart();

  cart.add(createProduct());

  expect(cart.isEmpty()).toBe(false);
});
```

## Test Independence

Tests must not depend on each other. Each test should:

- Create its own test data
- Not rely on state from previous tests
- Be runnable in any order
- Be runnable in isolation

```typescript
// ❌ Bad: Shared mutable state
let cart: Cart;

beforeEach(() => {
  cart = createEmptyCart();
});

test('adding product', () => {
  cart.add(product);
  expect(cart.items()).toHaveLength(1);
});

test('cart total after adding', () => {
  // Depends on previous test having run!
  expect(cart.total()).toBe(25);
});

// ✅ Good: Each test is independent
test('adding product shows product in cart', () => {
  const cart = createEmptyCart();
  const product = createProduct();

  cart.add(product);

  expect(cart.items()).toContain(product);
});
```

## Parallel Execution

Tests must be safe to run concurrently. This means:

- No shared mutable state between tests
- No reliance on global variables
- No file system conflicts
- Each test creates its own isolated data

```typescript
// ❌ Bad: Global state prevents parallel execution
let globalConfig = { maxItems: 10 };

test('respects max items limit', () => {
  globalConfig.maxItems = 5;
  // Another test might change this simultaneously!
});

// ✅ Good: Isolated configuration per test
test('respects max items limit', () => {
  const config = createConfig({ maxItems: 5 });
  const cart = createCart(config);

  // Safe to run in parallel
});
```

## Checklist

- [ ] Clear Arrange-Act-Assert structure
- [ ] No explicit phase comments
- [ ] Blank lines separate the three phases
- [ ] One behavior per test
- [ ] Single logical assertion (multiple `expect` OK if testing one concept)
- [ ] No shared mutable state between tests
- [ ] Tests runnable in any order
- [ ] Tests safe to run in parallel
