---
name: test-quality
description: Validates that tests are well-written following best practices. Checks structure, setup patterns, dependencies, naming, and detects anti-patterns. Can run as an agent to review and improve test code.
runAsAgent: true
commands:
  - improve-test
  - test-quality
---

# Test Quality Validator

Validates that tests follow best practices and proposes improvements.

## Usage

- `/test-quality <file>` - Validate a specific test file
- `/test-quality` - Validate recently modified test files

## Categories

This skill checks tests against seven quality categories:

1. **Structure** - Arrange-Act-Assert, one behavior per test, parallel execution
2. **Setup & Data** - Factories, builders, data visibility
3. **Dependencies** - Date injection, stubs, spies, fakes (no mocking frameworks)
4. **Naming & Readability** - Domain vocabulary, custom assertions
5. **Unit Test Criteria** - Fast, isolated, concurrent
6. **Anti-patterns** - Logic in tests, interdependence, over-mocking
7. **Database** - Fake repositories, integration tests, parallel DB tests

## Validation Process

### Step 1: Read the Test File

Read the specified test file(s) to analyze.

### Step 2: Launch Validation Agents in Parallel

Launch a validation agent for each category using the Task tool. Run all agents in parallel.

**Use this template for each category:**

```
Task tool with:
  subagent_type: "general-purpose"
  model: "sonnet"
  prompt: |
    You are a test quality validator for the "[CATEGORY_NAME]" category.

    ## Your Task

    Validate the test file against the rules in the documentation below.

    ## Test File to Validate

    Path: [TEST_FILE_PATH]

    ## Validation Rules

    Read the rules documentation at: [SKILL_ROOT]/rules/[RULES_FILE].md

    ## Process

    1. Read the rules documentation file
    2. Read the test file
    3. Check each test against all rules in the documentation
    4. Report findings

    ## Output Format

    ```markdown
    ## [CATEGORY_NAME] Validation: [filename]

    ### Findings

    #### ✅ Passed
    - [List of rules that pass]

    #### ❌ Issues Found
    1. **[Test name]**: [Issue description]
       - Line: [line number]
       - Rule violated: [which rule]
       - **Problematic code:**
         ```
         [The actual code with the problem - ALWAYS include this]
         ```
       - Suggestion: [how to fix]

    ### Summary
    - Tests checked: N
    - Issues found: N
    ```

    **IMPORTANT:** Always include the actual problematic code snippet for each issue found. Never report an issue without showing the code that violates the rule.
```

**Categories and their rules files:**

| Category | Rules File |
|----------|------------|
| Structure | `structure.md` |
| Setup & Data | `setup-data.md` |
| Dependencies | `dependencies.md` |
| Naming & Readability | `naming-readability.md` |
| Unit Test Criteria | `unit-test-criteria.md` |
| Anti-patterns | `anti-patterns.md` |
| Database | `database.md` (only if test involves database) |

### Step 3: Aggregate Results

Collect all agent reports and compile into a single summary.

### Step 4: Present Improvements One by One

For each violation found by agents, present them **one at a time** to the user, **ordered by importance** (major issues first, minor issues last).

**Issue Priority (present in this order):**
1. **Major** - Breaks test reliability, causes false positives/negatives, or hides bugs
2. **Medium** - Reduces maintainability, causes confusion, or violates best practices
3. **Minor** - Style issues, naming improvements, or minor readability concerns

**For each improvement:**

1. Show the issue:
   - **What's wrong** - Specific issue found, with the problematic code snippet
   - **Why it matters** - Impact on test quality
   - **How to fix** - Concrete code suggestion with before/after code

2. Ask user to approve or skip this specific improvement

3. If approved, apply the fix using Edit tool

4. Move to the next improvement

**Important:** Do NOT present all improvements at once. Walk through them one by one, getting user approval for each before proceeding to the next.

### Step 5: Summary

After all improvements have been reviewed, provide a summary of:
- How many improvements were applied
- How many were skipped
- Remaining issues (if any)

## Output Format

```markdown
## Test Quality Report: [filename]

### Summary

- **Tests analyzed:** N
- **Issues found:** N
- **Categories with issues:** [list]

### Structure

- ✅ Arrange-Act-Assert pattern followed
- ❌ Multiple behaviors in single test

### Setup & Data

- ✅ Using factories for object creation
- ❌ Magic values in assertions not visible in arrange

[... other categories ...]

---

## Improvement 1 of N: [Test name] - [Issue]

**Category:** [category name]

**What's wrong:**
[description]

**Why it matters:**
[impact]

**Current:**

```typescript
[problematic code]
```

**Suggested:**

```typescript
[improved code]
```

Apply this fix? (yes/skip)
```

After user responds, show next improvement or summary.

## Quick Checks

For rapid validation, focus on these high-impact items:

1. Can you understand the test without reading implementation?
2. Are asserted values visible in the test setup?
3. Is there only one reason this test would fail?
4. Does the test name describe a behavior?
5. Would the test break if implementation changes but behavior doesn't?
