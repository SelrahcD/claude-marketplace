# Test Quality - Validate Test Files

Validate test files against best practices and propose improvements.

## Usage
```
/test-quality <test-file-path> [<additional-test-files>...]
```

Examples:
```
/test-quality tests/user.test.ts
/test-quality src/__tests__/auth.spec.js src/__tests__/login.spec.js
/test-quality test/models/order_test.rb test/models/product_test.rb
```

## Process

Invoke the `test-quality` skill to validate the provided test file(s).

For each file provided, the skill will:

1. Read and analyze the test file(s)
2. Run parallel validation agents for each quality category:
   - Structure (Arrange-Act-Assert, one behavior per test)
   - Setup & Data (factories, builders, data visibility)
   - Dependencies (stubs, spies, fakes)
   - Naming & Readability (domain vocabulary, custom assertions)
   - Unit Test Criteria (fast, isolated, concurrent)
   - Anti-patterns (logic in tests, interdependence, over-mocking)
   - Database (if applicable)
3. Aggregate results into a comprehensive report
4. Propose specific improvements with code suggestions
5. Offer to apply fixes if requested
