---
name: test-list
description: Create prioritized test lists for test-driven development
---

# Test List - TDD Test Planning

Create prioritized test lists for test-driven development.

## Usage
```
/test-list <feature>
```

Examples:
```
/test-list "password validation"
/test-list "shopping cart checkout"
/test-list "user registration flow"
```

## Process

Invoke the `test-list-planner` skill to:
- Analyze feature requirements
- Apply ZOMBIES ordering (Zero, One, Many, Boundaries, Interfaces, Exceptions, Simple)
- Use Transformation Priority Premise for test ordering
- Produce a checklist of tests ordered from simplest to most complex
