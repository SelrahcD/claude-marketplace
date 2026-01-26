---
name: test-quality
description: Validate test files against best practices and propose improvements
---

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

Invoke the `test-quality` skill to validate the provided test file(s). Follow the workflow defined in the skill.
