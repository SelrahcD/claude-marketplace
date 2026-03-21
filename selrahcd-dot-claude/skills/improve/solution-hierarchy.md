# Solution Hierarchy

When proposing solutions for observations, prefer higher-numbered durability. The most durable solutions are hardest to bypass.

## Ranked Solutions (Most to Least Durable)

### 1. Type system / compiler checks
Impossible to bypass. The code won't compile or run if violated.
- **When:** The problem involves incorrect types, missing fields, wrong interfaces
- **Example:** Add a TypeScript type that prevents passing raw strings where IDs are expected

### 2. Linter rules
Fast, deterministic, runs on every save. Catches issues before code executes.
- **When:** The problem is a code style or structural pattern that should always be enforced
- **Example:** ESLint rule that flags direct `console.log` usage in production code

### 3. Tests
Catches regressions, documents expected behavior. Runs on every commit.
- **When:** The problem involves incorrect behavior that could recur
- **Example:** Test that verifies error messages include the failing field name

### 4. Pre-commit hooks
Last automated gate before code enters the repository.
- **When:** The problem should be caught before commit but isn't a linter/test concern
- **Example:** Hook that checks for TODO comments without linked issues

### 5. Claude hooks
PreToolUse, PostToolUse, UserPromptSubmit. Shapes Claude's behavior automatically.
- **When:** The problem is a Claude behavioral pattern that should be intercepted
- **Example:** PreToolUse hook that warns before editing files outside the project root

### 6. Skills or commands
New or improved reusable behaviors. Activated by name or trigger words.
- **When:** The problem is a recurring workflow pattern that should be standardized
- **Example:** A skill that enforces a specific code review checklist

### 7. CLAUDE.md / AGENTS.md
Project context and conventions. Read at session start.
- **When:** The problem is missing project context or conventions
- **Example:** Adding "always use named exports" to CLAUDE.md

### 8. Prompt instructions
Least durable — depends on Claude reading and following text.
- **When:** Nothing else fits, or as a temporary measure while building a more durable solution
- **Example:** Adding a reminder to a skill's anti-patterns section

## Choosing the Right Level

Ask these questions in order:

1. **Can the type system prevent this?** If yes, use level 1.
2. **Can a linter catch this statically?** If yes, use level 2.
3. **Can a test detect this at runtime?** If yes, use level 3.
4. **Should this be caught at commit time?** If yes, use level 4.
5. **Is this a Claude behavioral issue?** If yes, try level 5 first, then level 6.
6. **Is this a recurring workflow?** If yes, use level 6.
7. **Is this missing context?** If yes, use level 7.
8. **Nothing else fits?** Use level 8, but consider if a more durable option exists.

Always prefer higher durability. Multiple levels can be combined — a test (3) plus a CLAUDE.md note (7) is better than just a note alone.
