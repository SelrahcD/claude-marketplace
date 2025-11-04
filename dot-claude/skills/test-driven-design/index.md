---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code - enforces strict RED-GREEN-REFACTOR with outside-in behavior-focused tests, ZOMBIES ordering, TPP transformations, and requirement that every test must fail first
---

# Test-Driven Development

## Overview

**TDD is writing tests first, watching them fail, writing minimal code to pass, then refactoring.** This skill enforces strict RED-GREEN-REFACTOR with test lists, outside-in approach, ZOMBIES ordering, TPP transformations, and quality test patterns.

**Works with tdd-guard:** This workflow integrates with [tdd-guard](https://github.com/nizos/tdd-guard/), a Claude Code hooks system that blocks implementation without failing tests and prevents code beyond current test requirements.

## The Iron Law

```
NEVER WRITE IMPLEMENTATION CODE BEFORE ITS TEST
```

**No exceptions:**
- Not for "simple" functions
- Not for "obvious" logic
- Not when "time is short"
- Not when "I already know it works"
- Not for scaffolding or interfaces

**Violation recovery:** Delete implementation code. Start over with test first.

## The RED-GREEN-REFACTOR Cycle

### Phase 0: TEST LIST (Before RED)

**Always start by creating a test list by splitting the problem in smaller problems and then using ZOMBIES ordering:**


```markdown
## Test List: Shopping Cart
- [ ] Z: New cart is empty
- [ ] Z: New cart has total of 0
- [ ] O: Add one item increases total by item price
- [ ] O: Cart contains the added item
- [ ] M: Add multiple items sums all prices
- [ ] B: Remove item from cart decreases total
- [ ] E: Add item with negative price throws error
```

**Test list rules:**
- Split the problem in smaller problems
  - N something -> do one something after the other
- Create upfront (incomplete is OK, you'll add more)
- Use ZOMBIES ordering (see below)
- Keep in sync - cross off when passing
- Add new tests as you discover them
- Review before each test to pick simplest next

### Phase 1: RED (Watch It Fail)

**For each test in your list:**

1. **Write the test** (and ONLY the test)
2. **Run it** - must see actual failure output
3. **Verify failure reason** - correct failure (not unrelated error)
4. **Check failure message** - is it clear what's wrong?

**Valid failure types:**
- ✅ Test assertion fails
- ✅ Compilation/syntax error (adding new interface)
- ✅ Method/class doesn't exist yet
- ❌ Unrelated error (typo in test, wrong import)

**You MUST see the test fail before writing implementation.**

**CRITICAL: Test passed immediately?** 🚨 SUSPICIOUS

If a new test passes without any code changes:
- **STOP** - investigate why it passed
- Either: test is redundant (delete it)
- Or: you need a different test to expose missing behavior
- Never proceed with a test that didn't fail first

**Common rationalizations:**
- "Test obviously will fail" → Run it anyway
- "I can visualize the failure" → Run it anyway
- "This wastes time" → Run it anyway
- "It passed because implementation is good" → Wrong - investigate

**Why this matters:** Tests that immediately pass prove nothing. You don't know if the test works until you see it fail.

### Phase 2: GREEN (Minimal Code Using TPP)

**Write the MINIMUM code to make the current test pass using the simplest transformation:**

**Transformation Priority Premise (TPP)** - apply transformations in this order (simplest first):

1. **({}→nil)** - No code to nil/null
2. **(nil→constant)** - Return constant value
3. **(constant→constant+)** - More complex constant
4. **(constant→scalar)** - Constant to variable/argument
5. **(statement→statements)** - Add more statements
6. **(unconditional→if)** - Add conditional
7. **(scalar→array)** - Variable to collection
8. **(array→container)** - Array to richer structure
9. **(statement→recursion)** - Add recursion
10. **(if→while)** - Conditional to loop
11. **(expression→function)** - Extract algorithm
12. **(variable→assignment)** - Mutate variables

**GREEN phase rules:**
- Use the highest-priority (simplest) transformation that makes test pass
- Hard-code return values early (constant before scalar)
- Let the NEXT test force generalization
- Avoid jumping to complex transformations
- If test demands low-priority transform, pick a different test

**Run tests - all must be green before proceeding.**

**Example progression:**
```javascript
// Test 1: sum([]) should return 0
return 0;  // (nil→constant)

// Test 2: sum([5]) should return 5
return numbers[0] || 0;  // (constant→scalar), (scalar→array)

// Test 3: sum([1,2]) should return 3
return numbers.reduce((a,b) => a+b, 0);  // (statement→statements)
```

**One test per RED-GREEN cycle.** Small steps.

### Phase 3: REFACTOR (Clean Up)

**Only refactor when ALL tests are green:**

- Small refactorings between cycles
- Remove duplication when it appears
- Improve test quality (see Test Quality section)
- Defer large refactorings until pattern emerges (rule of three)

**Run tests after every refactoring - must stay green.**

**Then return to RED** for the next test on your list.

## Outside-In Approach

**Start from the system boundary or use case level, work inward:**

```
Outside-In TDD Flow:
System Boundary → Use Case → Domain Logic → Infrastructure
```

**In hexagonal architecture:**
- Start at use case/application service level
- Drive out domain behavior
- Add adapters/infrastructure last

**Example - Order Processing:**
```javascript
// Start outside: HTTP endpoint or use case
test('process order returns confirmation', () => {
  const confirmation = processOrder(validOrderRequest);
  expect(confirmation.orderId).toBeDefined();
  expect(confirmation.status).toBe('confirmed');
});

// Then drive inward: domain logic
test('order calculates total from items', () => {
  const order = new Order();
  order.addItem(item(10));
  expect(order.total()).toBe(10);
});
```

**Why outside-in:** Tests at system boundaries describe user-facing behavior. Implementation details emerge naturally.

## ZOMBIES: Test Ordering

**Always start simple, progress to complex using ZOMBIES:**

- **Z**ero - Empty collections, null cases, initial state
- **O**ne - Single item, simplest non-empty case
- **M**any - Multiple items, collections, loops
- **B**oundaries - Edge cases, limits, off-by-one
- **I**nterface - API contracts, method signatures
- **E**xceptions - Error cases, invalid input
- **S**imple - Keep each test simple

**Apply ZOM progression (Zero → One → Many), consider BIE throughout.**

**Why this order:** Easier to keep code working than fix it after breaking. Build confidence incrementally. Aligns with TPP - simple tests allow simple transformations.

**Examples:**

| Feature | Z (Zero) | O (One) | M (Many) | B (Boundary) | E (Exception) |
|---------|----------|---------|----------|--------------|---------------|
| Stack | isEmpty=true, size=0 | push 1 item | push 3, pop LIFO | pop empty throws | push null throws |
| Sum | sum([]) = 0 | sum([5]) = 5 | sum([1,2,3]) = 6 | sum(MAX_INT) | sum(null) throws |

## Unit Tests: Behavior Over Artifacts

**Unit tests test behavior, not individual classes/functions:**

- ✅ Can exercise multiple classes/functions
- ✅ Focus on observable behavior
- ✅ Use domain terminology
- ❌ Don't test implementation details

**A test is a unit test if it (Michael Feathers):**
- Runs fast
- Doesn't talk to database
- Doesn't communicate across network
- Doesn't touch file system
- Doesn't require special environment setup
- Can run concurrently with other tests

**Tests that violate these are integration tests** (still valuable, different purpose).

## Test Quality

### Test Names: Behavior + Domain Terms

**Test names describe business behavior, not implementation:**

```javascript
// ❌ Implementation-focused
test('addItem pushes to items array')
test('calculateTotal calls reduce')

// ✅ Behavior-focused with domain terms
test('adding item increases cart total')
test('applying valid discount code reduces total')
test('guest checkout requires email address')
```

**Vocabulary alignment:** Same terms in test name and test body = good sign.

```javascript
// Good alignment
test('premium members receive free shipping', () => {
  const member = createPremiumMember();
  const order = placeOrder(member, items);
  expect(order.shippingCost).toBe(0);
});
```

### Builders/Factories: Show Relevant, Hide Irrelevant

**Show data that matters for the assertion, hide the rest:**

```javascript
// ❌ BAD: Relevant data hidden in builder
function orderBuilder() {
  return { customerId: 123, items: [item(50)], tax: 0.1 };
}
test('order total includes tax', () => {
  expect(calculateTotal(orderBuilder())).toBe(55); // Where did 50 come from?
});

// ✅ GOOD: Show relevant data, hide irrelevant
function orderBuilder(overrides = {}) {
  return {
    customerId: randomId(), // Hidden - irrelevant
    createdAt: randomDate(), // Hidden - irrelevant
    items: [],
    tax: 0,
    ...overrides
  };
}
test('order total includes tax', () => {
  const itemPrice = 50;
  const taxRate = 0.1;
  const order = orderBuilder({
    items: [item(itemPrice)],
    tax: taxRate
  });
  expect(calculateTotal(order)).toBe(55);
  // Clear: 50 + (50 * 0.1) = 55
});
```

**Principle:** If data affects the assertion, show it in Arrange/Act. If not, hide it (use random values).

### Custom Assertions for Clarity

```javascript
// ❌ Repetitive, unclear intent
expect(response.status).toBe(200);
expect(response.headers['content-type']).toBe('application/json');

// ✅ Clear intent with custom assertion
function expectSuccessJson(response) {
  expect(response.status).toBe(200);
  expect(response.headers['content-type']).toBe('application/json');
  return response.body;
}

test('fetch user returns profile', () => {
  const user = expectSuccessJson(response);
  expect(user.name).toBe('Alice');
});
```

### Keep Tests Focused

- **One behavior per test** - not one method per test
- **Clear Arrange-Act-Assert** sections
- **Avoid test interdependence** - each test stands alone

## Small Steps

**Each RED-GREEN cycle should be small:**

- One test per behavior/requirement
- One assertion per test (preferred)
- Implementation change must be minimal
- Full cycle should take minutes, not hours

**Step too big?** Break the test into smaller tests. Add them to your test list.

## Red Flags - STOP and Start Over

If you catch yourself thinking:

- "I'll just write the implementation first"
- "The test will obviously fail"
- "Tests slow me down"
- "This is too simple to test"
- "I already manually tested it"
- "Time pressure means skip tests"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "Test passed immediately - implementation must be good"

**All of these mean: You're about to violate TDD. STOP.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Tests take 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Time pressure" | TDD is faster - prevents debugging time. |
| "I already manually tested" | Manual tests don't prevent regressions. |
| "Tests-after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Code first, then wrap" | Delete code. Start over with test first. |
| "Spirit not ritual" | Violating the letter IS violating the spirit. |
| "Test passed so code is good" | If test didn't fail first, test proves nothing. |

## Workflow Summary

**For every feature/bugfix:**

1. **Create test list** - incomplete OK, ZOMBIES ordering, outside-in approach
2. **Pick simplest next test** - review list, choose highest priority
3. **RED** - Write test, run it, watch it fail (compilation error OK), verify failure
4. **GREEN** - Minimal code using simplest TPP transformation, run tests (all green)
5. **REFACTOR** - Clean up (tests stay green), improve test quality
6. **Cross off test** - mark complete in test list
7. **Repeat** - next test from list

**Integration with tdd-guard:**
- tdd-guard blocks implementation without failing tests
- tdd-guard prevents over-implementation beyond test requirements
- tdd-guard enforces linting during refactor
- This workflow provides the methodology, tdd-guard provides the enforcement

## Why TDD Works

- **Tests fail first** → Proves tests actually test something
- **Every test must fail** → Suspicious if it passes immediately
- **Outside-in** → Drives design from user needs
- **Behavior-focused** → Tests describe what system does, not how
- **Minimal code** → Prevents over-engineering
- **TPP** → Guides simplest path, avoids impasses
- **Small steps** → Easier to debug, easier to stay green
- **Test list** → Nothing forgotten, visible progress
- **ZOMBIES** → Build confidence incrementally, aligns with TPP
- **Quality tests** → Maintainable, clear intent, domain-aligned

**The discipline is the point.** TDD works BECAUSE it's strict, not despite it.
