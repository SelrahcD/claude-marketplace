# Refactoring Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a `refactoring` skill in `selrahcd-dot-claude` that drives a refactor as a sequence of small, named refactorings from Fowler's catalog, one commit per step, with a state-machine workflow.

**Architecture:** A markdown-only Claude Code skill. `SKILL.md` carries the discipline + state machine (always loaded). A `catalog/` directory holds an `INDEX.md` (loaded at PLAN) and 17 per-refactoring files (lazy-loaded at SELECT). A `/refactor` slash command is a thin wrapper.

**Tech Stack:** Markdown, JSON (plugin metadata), Bash (verification).

**Spec:** [`docs/superpowers/specs/2026-05-13-refactoring-skill-design.md`](../specs/2026-05-13-refactoring-skill-design.md)

---

## Note on testing approach

Skills are markdown — there is no automated test harness. Each task's verification consists of:
1. Reading the written file back to confirm structure and content (Read tool).
2. For JSON files: validating syntax with `jq empty <file>`.
3. The final smoke task (Task 13) loads the plugin in Claude Code and confirms the skill + slash command are discoverable.

No fake TDD red/green cycle. Commits are still made per task to mirror the discipline the skill itself teaches.

---

## File structure

| File | Created by | Purpose |
|---|---|---|
| `selrahcd-dot-claude/skills/refactoring/SKILL.md` | Task 1 | Always-loaded discipline + state machine. |
| `selrahcd-dot-claude/skills/refactoring/README.md` | Task 2 | Skill README (usage + examples). |
| `selrahcd-dot-claude/skills/refactoring/catalog/INDEX.md` | Task 3 | List of named refactorings with one-line descriptions. |
| `selrahcd-dot-claude/commands/refactor.md` | Task 4 | `/refactor` slash command wrapper. |
| `selrahcd-dot-claude/skills/refactoring/catalog/extract-method.md` | Task 5 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/inline-method.md` | Task 5 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/extract-variable.md` | Task 5 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/inline-variable.md` | Task 5 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/move-function.md` | Task 6 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/move-field.md` | Task 6 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/encapsulate-variable.md` | Task 7 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/replace-primitive-with-object.md` | Task 7 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/decompose-conditional.md` | Task 8 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/replace-conditional-with-polymorphism.md` | Task 8 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/rename-function.md` | Task 9 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/introduce-parameter-object.md` | Task 9 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/change-function-declaration.md` | Task 9 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/extract-superclass.md` | Task 10 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/replace-subclass-with-delegate.md` | Task 10 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/extract-class.md` | Task 11 | Catalog entry. |
| `selrahcd-dot-claude/skills/refactoring/catalog/hide-delegate.md` | Task 11 | Catalog entry. |
| `selrahcd-dot-claude/.claude-plugin/plugin.json` | Task 12 | Version bump 1.29.0 → 1.30.0. |
| `.claude-plugin/marketplace.json` | Task 12 | Version bump 1.29.0 → 1.30.0 for `dot-claude` plugin entry. |
| `selrahcd-dot-claude/README.md` | Task 12 | Add Skills entry + Credits. |

---

### Task 1: Write SKILL.md (discipline + state machine)

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/SKILL.md`

- [ ] **Step 1: Create skill directory and catalog subdirectory**

```bash
mkdir -p selrahcd-dot-claude/skills/refactoring/catalog
```

- [ ] **Step 2: Write SKILL.md**

```markdown
---
name: refactoring
description: Apply a refactor as a sequence of small, named refactorings from Fowler's catalog, with one commit per step verified by tests. Use when the user says "refactor", "extract method", "extract class", "inline", "rename", "move method", "clean up this code", "restructure without changing behavior", or invokes /refactor.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
---

# 🚨 CRITICAL: REFACTORING STATE MACHINE GOVERNANCE 🚨

**EVERY SINGLE MESSAGE MUST START WITH YOUR CURRENT REFACTORING STATE.**

Format:
```
🎯 REFACTOR: SETUP
📋 REFACTOR: PLAN
🔍 REFACTOR: SELECT
🔧 REFACTOR: APPLY
🧪 REFACTOR: VERIFY
💾 REFACTOR: COMMIT
🔄 REFACTOR: REASSESS
✅ REFACTOR: COMPLETE
⚠️ REFACTOR: BLOCKED
🔥 REFACTOR: VIOLATION_DETECTED
```

When you read a file → prefix with state. When you run a command → prefix with state. When you ask a question → prefix with state.

**🚨 FAILURE TO ANNOUNCE STATE = SEVERE VIOLATION 🚨**

---

## Purpose

Turn a refactor request into a clean sequence of small commits — one per named refactoring from Fowler's catalog — each verified against a configured safety net. The git history becomes the unit of review.

**Invariant:** Between any two commits produced by this skill, exactly one named refactoring is applied. No bundled changes.

## State machine

```
                  user request
                       ↓
                 ┌──────────┐
                 │  SETUP   │
                 └────┬─────┘
                      ↓
                 ┌──────────┐  ←──── REASSESS (plan changed)
                 │   PLAN   │
                 └────┬─────┘
                      ↓ user approves plan
                 ┌──────────┐
             ┌──→│  SELECT  │
             │   └────┬─────┘
             │        ↓ catalog file loaded
             │   ┌──────────┐
             │   │  APPLY   │ (internal 🧪 verifies per catalog markers)
             │   └────┬─────┘
             │        ↓ mechanics done
             │   ┌──────────┐
             │   │  VERIFY  │
             │   └────┬─────┘
             │        ↓ safety net green
             │   ┌──────────┐
             │   │  COMMIT  │
             │   └────┬─────┘
             │        ↓
             │   ┌──────────┐
             │   │ REASSESS │ ── plan changed ──→ PLAN
             │   └────┬─────┘
             │        │ more steps remain
             └────────┘
                      │ all steps done
                      ↓
                 ┌──────────┐
                 │ COMPLETE │
                 └──────────┘
```

## States

### SETUP

**Prefix:** `🎯 REFACTOR: SETUP`

**Purpose:** One-time initialization. Establish safety net, target, goal, and clean working tree.

**Actions:**
1. Run `git status` (no `-uall`). Working tree MUST be empty. If not, ask user to commit or stash. STOP until clean.
2. Capture target: which file(s) / function(s) / class(es) are being refactored, and what is the goal (in the user's words).
3. Ask the user to declare the safety net. Use AskUserQuestion with options:
   - **(a) tests** — provide a test command (e.g., `npm test`, `pytest -q`)
   - **(b) type-checker** — provide a check command (e.g., `tsc --noEmit`)
   - **(c) tests + type-checker** — both, in order
   - **(d) manual review** — no automated check; user replies "ok" at each gate
4. If (a), (b), or (c): run the command once. Capture verbatim output. If it fails at baseline, transition to BLOCKED — refactoring on a broken baseline gives no signal.
5. Record the working branch (`git rev-parse --abbrev-ref HEAD`). All commits go here; no branch switching mid-refactor.
6. Transition to PLAN.

**Pre-transition validation (announce before moving to PLAN):**
- ✓ Working tree clean: [yes — git status output]
- ✓ Target captured: [files / functions]
- ✓ Goal captured: [user's words]
- ✓ Safety net declared: [(a) / (b) / (c) / (d) + command if applicable]
- ✓ Baseline green: [yes — verbatim output] OR [N/A for manual mode]

### PLAN

**Prefix:** `📋 REFACTOR: PLAN`

**Purpose:** Produce an ordered list of named refactorings to apply.

**Actions:**
1. Read `catalog/INDEX.md` (relative to this skill's directory).
2. Identify candidate refactorings from the catalog that move the target toward the goal.
3. Produce an ordered list. Each entry: `<Refactoring Name> on <target>` — e.g., `Extract Method on Order#total`, `Move Function on Customer.discountFor`.
4. Present the plan to the user. Ask explicitly: "Approve, edit, or rewrite?"
5. If user requests edits, revise and re-present. Loop until user approves.
6. Transition to SELECT with the first item in the plan.

**Pre-transition validation:**
- ✓ Plan presented: [yes — list shown]
- ✓ User approved: [yes]
- ✓ First step identified: [refactoring name + target]

### SELECT

**Prefix:** `🔍 REFACTOR: SELECT`

**Purpose:** Load the catalog file for the next refactoring so its mechanics are in context.

**Actions:**
1. Identify the next item in the plan.
2. Resolve its catalog file: `<this-skill>/catalog/<kebab-case-name>.md`. For example, `Extract Method` → `extract-method.md`.
3. Read the catalog file with the Read tool.
4. Announce: which refactoring, which target, and confirm the mechanics are loaded.
5. Transition to APPLY.

**Pre-transition validation:**
- ✓ Catalog file path: [path]
- ✓ Catalog file read: [yes]
- ✓ Target reaffirmed: [where this refactoring applies]

### APPLY

**Prefix:** `🔧 REFACTOR: APPLY`

**Purpose:** Execute the mechanics' sub-steps from the catalog file. Run the safety net at every sub-step marked 🧪.

**Actions:**
1. Walk through the catalog file's `## Mechanics` section in order.
2. For each sub-step:
   a. Announce the sub-step verbatim.
   b. Apply the edit (Edit / Write).
   c. If the sub-step carries a 🧪 marker:
      - In safety mode (a)/(b)/(c): run the safety-net command. Show verbatim output. If it fails: try to fix or revert; if persistent, transition to BLOCKED.
      - In manual mode (d): show the diff for what changed since the previous 🧪 (or since the last commit). Wait for user "ok" before continuing.
3. After all sub-steps: transition to VERIFY.

**Critical rules:**
- 🚨 NEVER skip a 🧪 marker. They encode Fowler's "compile and test" cadence.
- 🚨 NEVER fold edits unrelated to the named refactoring into APPLY. If you notice an unrelated change, revert it and continue.

**Pre-transition validation:**
- ✓ All mechanics sub-steps executed: [yes — list]
- ✓ 🧪 verifications all green: [yes — outputs shown]
- ✓ No unrelated edits: [yes]

### VERIFY

**Prefix:** `🧪 REFACTOR: VERIFY`

**Purpose:** Final verification before committing this step.

**Actions:**
1. In safety mode (a)/(b)/(c): run the safety-net command one more time. Show verbatim output. Must be green.
2. In manual mode (d): show `git diff` (the cumulative change since the last commit). Wait for user "ok".
3. Run `git status` to confirm only files within the refactoring's scope are dirty.
4. If anything outside scope is dirty: transition to VIOLATION_DETECTED.
5. Otherwise: transition to COMMIT.

**Pre-transition validation:**
- ✓ Safety net green: [yes — output] OR ✓ User approved diff: [yes]
- ✓ Only in-scope files dirty: [yes — git status output]

### COMMIT

**Prefix:** `💾 REFACTOR: COMMIT`

**Purpose:** Create exactly one commit for this refactoring.

**Actions:**
1. Stage in-scope files: `git add <files>`. NEVER `git add -A` or `git add .`.
2. Compose the title: `refactor: <Refactoring Name> '<target>' from <location>`.
   Examples:
   - `refactor: Extract Method 'calculateTax' from Order#total`
   - `refactor: Inline Variable 'temp' in PriceCalculator#discountFor`
3. If motivation is non-obvious (e.g., this step prepares a later one): add a body of 1-3 lines. Otherwise, title only.
4. Commit with HEREDOC:

   ```bash
   git commit -m "$(cat <<'EOF'
   refactor: <Refactoring Name> '<target>' from <location>
   EOF
   )"
   ```

   (Add a blank line + body lines before the closing `EOF` if a body is warranted.)

5. Run `git log -1 --oneline` to confirm the commit landed.
6. Transition to REASSESS.

**Critical rules:**
- 🚨 NEVER use `--no-verify`.
- 🚨 NEVER include `Co-Authored-By` lines — they are not part of this skill's commit convention.
- 🚨 NEVER amend a previous commit. Each refactoring is its own commit.

### REASSESS

**Prefix:** `🔄 REFACTOR: REASSESS`

**Purpose:** Decide whether the plan still holds.

**Actions:**
1. Re-read the remaining plan items.
2. Ask: did the last refactoring reveal something that changes what comes next? (New smell, missed dependency, simpler path.)
3. If yes: transition back to PLAN with a revised plan. Note what changed and why.
4. If no, and items remain: transition to SELECT for the next item.
5. If no items remain: transition to COMPLETE.

### COMPLETE

**Prefix:** `✅ REFACTOR: COMPLETE`

**Purpose:** Wrap-up.

**Actions:**
1. Show the list of commits produced (`git log --oneline <baseline>..HEAD`).
2. Summarize: count of refactorings applied, named refactorings in order.
3. Suggest follow-ups (further refactorings, tests to add, code review).

### BLOCKED

**Prefix:** `⚠️ REFACTOR: BLOCKED`

**Purpose:** Cannot proceed.

**Actions:**
1. State the blocker plainly.
2. State which state you were in and what you were trying to do.
3. Suggest possible resolutions (revert step, fix tests, adjust plan).
4. STOP. Wait for user.

**Critical rules:**
- 🚨 NEVER improvise around a blocker.
- 🚨 NEVER commit broken state to "unblock yourself".

### VIOLATION_DETECTED

**Prefix:** `🔥 REFACTOR: VIOLATION_DETECTED`

**Triggers:**
- Forgot state prefix on a message.
- Skipped a 🧪 verification.
- Started APPLY without loading the catalog file.
- Bundled unrelated edits into a step.
- Committed without VERIFY passing.

**Actions:**
1. Announce: `🔥 REFACTOR: VIOLATION_DETECTED`.
2. State which rule was violated.
3. Propose recovery (revert, re-run verification, split commit).
4. Wait for user approval before continuing.

## Rules

1. **One refactoring per commit.** No exceptions.
2. **No commits without VERIFY passing.** No exceptions.
3. **Catalog is source of truth for mechanics.** Read `catalog/<name>.md` before applying — do not improvise from memory.
4. **State prefix on every message.** No exceptions.
5. **No branch switching mid-refactor.** All commits go on the branch recorded at SETUP.
6. **No `git add -A` / `git add .`.** Always stage explicit paths.
7. **Manual-mode "ok" is the safety net.** In mode (d), do not commit without an explicit user "ok" on the diff.
```

- [ ] **Step 3: Read SKILL.md back to confirm structure**

Run: `head -20 selrahcd-dot-claude/skills/refactoring/SKILL.md`
Expected: frontmatter starts with `---`, contains `name: refactoring` and `user-invocable: true`.

- [ ] **Step 4: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/SKILL.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add refactoring skill SKILL.md with state machine
EOF
)"
```

---

### Task 2: Write skill README.md

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/README.md`

- [ ] **Step 1: Write README.md**

```markdown
# Refactoring skill

Drive a refactor as a sequence of small, named refactorings from Martin Fowler's catalog. Each named refactoring is one commit. Each commit is verified against a safety net (tests, type-checker, or manual review).

## Why

When a PR reviewer reads the commits of a refactor session, they should see the sequence of named refactorings applied, in order, without having to reconstruct intent from diffs. This skill enforces that discipline.

## How to invoke

- **Slash command:** `/refactor` (optionally with a free-text description: `/refactor split Order into Order + TaxCalculator`).
- **Natural language:** "refactor this", "extract a method here", "rename X to Y", "this code is messy, clean it up", "restructure without changing behavior".

## What you get

1. A SETUP step where you declare a safety net (tests / type-checker / both / manual).
2. A PLAN — an ordered list of named refactorings from Fowler's catalog. You approve or edit before any code changes.
3. Per refactoring: the skill loads the catalog mechanics, applies them step by step, runs verification, and commits with a message like `refactor: Extract Method 'calculateTax' from Order#total`.
4. A REASSESS step between refactorings so the plan can evolve if the code reveals something new.

## Catalog

17 refactorings ship in v1, covering Composing methods, Moving features, Organizing data, Simplifying conditionals, Refactoring APIs, Dealing with inheritance, and Larger restructurings. See `catalog/INDEX.md`.

## Limits

- The skill never delegates to `/commit` — it writes its own commit messages because the refactoring name is load-bearing.
- The skill operates on the current branch only. No branch switching mid-refactor.
- The skill is independent from `tdd-process`. To do a structured multi-step refactor while in TDD, exit `tdd-process` first.

## Credits

Mechanics drawn from *Refactoring: Improving the Design of Existing Code* (2nd ed.) by Martin Fowler.
```

- [ ] **Step 2: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/README.md
git commit -m "$(cat <<'EOF'
docs(dot-claude): add refactoring skill README
EOF
)"
```

---

### Task 3: Write catalog INDEX.md

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/INDEX.md`

- [ ] **Step 1: Write INDEX.md**

```markdown
# Refactoring Catalog

Each entry: `[Refactoring Name](file.md) — one-sentence description of when to use it`.

## Composing methods
- [Extract Method](extract-method.md) — Turn a code fragment into its own method when the fragment needs naming or reuse.
- [Inline Method](inline-method.md) — Replace a method call with its body when the method's name no longer adds clarity.
- [Extract Variable](extract-variable.md) — Name a sub-expression to make intent explicit.
- [Inline Variable](inline-variable.md) — Replace a variable with its expression when the name doesn't earn its place.

## Moving features
- [Move Function](move-function.md) — Relocate a function closer to the data it operates on.
- [Move Field](move-field.md) — Relocate a field to the class that uses it most.

## Organizing data
- [Encapsulate Variable](encapsulate-variable.md) — Wrap a variable in accessor methods to control how it's read and changed.
- [Replace Primitive with Object](replace-primitive-with-object.md) — Promote a primitive carrying behavior into its own type.

## Simplifying conditionals
- [Decompose Conditional](decompose-conditional.md) — Extract each branch and condition into named methods.
- [Replace Conditional with Polymorphism](replace-conditional-with-polymorphism.md) — Move type-based branching into subclasses.

## Refactoring APIs
- [Rename Function](rename-function.md) — Change a name that no longer reflects what it does.
- [Introduce Parameter Object](introduce-parameter-object.md) — Bundle related parameters into a single object.
- [Change Function Declaration](change-function-declaration.md) — Modify name, parameters, or return shape of a function.

## Dealing with inheritance
- [Extract Superclass](extract-superclass.md) — Pull shared code from sibling classes into a parent.
- [Replace Subclass with Delegate](replace-subclass-with-delegate.md) — Swap inheritance for composition when inheritance no longer fits.

## Larger restructurings
- [Extract Class](extract-class.md) — Split a class doing too much into two collaborating classes.
- [Hide Delegate](hide-delegate.md) — Hide a client's knowledge of a delegate behind the server.
```

- [ ] **Step 2: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/catalog/INDEX.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add refactoring catalog INDEX
EOF
)"
```

---

### Task 4: Write /refactor slash command

**Files:**
- Create: `selrahcd-dot-claude/commands/refactor.md`

- [ ] **Step 1: Write refactor.md**

```markdown
---
name: refactor
description: Run the refactoring skill on the current target with Fowler-style small steps and one commit per refactoring.
---
Use the refactoring skill to refactor: $ARGUMENTS
```

- [ ] **Step 2: Commit**

```bash
git add selrahcd-dot-claude/commands/refactor.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add /refactor slash command
EOF
)"
```

---

### Task 5: Composing methods catalog files

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/extract-method.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/inline-method.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/extract-variable.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/inline-variable.md`

- [ ] **Step 1: Write extract-method.md**

```markdown
# Extract Method

## Motivation
A fragment of code does something that can be named at a higher level of intent than its statements reveal. Extracting the fragment into a method gives that intent a name, makes the surrounding code read at a single level of abstraction, and creates a unit reusable elsewhere.

## When NOT to use
When the fragment is trivial and the extracted name would not be clearer than the inline code. When the extracted code depends on many local variables that would need to become parameters or returned values, suggesting a deeper decomposition is needed first.

## Mechanics
1. Create a new function, name it by what it does (intent), not how.
2. Copy the extracted code from the source location into the new function. 🧪
3. Scan the extracted code for any local variables referenced only in the source. Pass them as parameters.
4. Compile.
5. Scan for any variables assigned by the extracted code that are still used in the source. Return them. 🧪
6. Replace the original fragment in the source with a call to the new function. 🧪
7. Look for similar code that can now call the new function (Replace Inline Code with Function Call). 🧪

## Example
Before:
```
function printOwing(invoice) {
  printBanner();
  let outstanding = calculateOutstanding();
  console.log(`name: ${invoice.customer}`);
  console.log(`amount: ${outstanding}`);
}
```
After:
```
function printOwing(invoice) {
  printBanner();
  let outstanding = calculateOutstanding();
  printDetails(invoice, outstanding);
}

function printDetails(invoice, outstanding) {
  console.log(`name: ${invoice.customer}`);
  console.log(`amount: ${outstanding}`);
}
```

## Common pitfalls
- Passing too many parameters because the extracted block touches too much state — that's a signal to split the source method differently or apply Extract Class.
- Reassigning a parameter inside the new function — break this into a separate variable first.
- Naming by mechanism (`doStep1`) instead of intent (`printDetails`).
```

- [ ] **Step 2: Write inline-method.md**

```markdown
# Inline Method

## Motivation
A method's body is as clear as its name, or the indirection it provides no longer earns its keep. Inlining removes a hop the reader doesn't need.

## When NOT to use
When the method is polymorphic (subclasses override it). When the method is called from many places — inlining each call site is expensive and may not improve clarity.

## Mechanics
1. Check the method is not polymorphic.
2. Find all callers.
3. Replace each call with the method's body. 🧪
4. Test after each replacement.
5. Once all callers are inlined, delete the original method. 🧪

## Example
Before:
```
function rating(driver) {
  return moreThanFiveLateDeliveries(driver) ? 2 : 1;
}
function moreThanFiveLateDeliveries(driver) {
  return driver.numberOfLateDeliveries > 5;
}
```
After:
```
function rating(driver) {
  return driver.numberOfLateDeliveries > 5 ? 2 : 1;
}
```

## Common pitfalls
- Inlining a method whose body has side effects that interact with the caller's context.
- Inlining a method called from many places at once instead of one at a time.
- Forgetting to delete the original after the last call site is inlined.
```

- [ ] **Step 3: Write extract-variable.md**

```markdown
# Extract Variable

## Motivation
A sub-expression is doing real work but its meaning is hidden inside a larger expression. Naming it as a local variable makes the intent explicit and the surrounding code easier to read.

## When NOT to use
When the sub-expression is already trivial. When the variable would be referenced only once and the inline expression is already self-explanatory.

## Mechanics
1. Identify the sub-expression to name.
2. Declare an immutable local variable initialized to that sub-expression.
3. Replace the sub-expression in its original location with the variable. 🧪
4. If the sub-expression appears multiple times in the surrounding code, replace each occurrence. 🧪

## Example
Before:
```
return order.quantity * order.itemPrice -
  Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 +
  Math.min(order.quantity * order.itemPrice * 0.1, 100);
```
After:
```
const basePrice = order.quantity * order.itemPrice;
const quantityDiscount = Math.max(0, order.quantity - 500) * order.itemPrice * 0.05;
const shipping = Math.min(basePrice * 0.1, 100);
return basePrice - quantityDiscount + shipping;
```

## Common pitfalls
- Variable name that restates the mechanism (`a_times_b`) instead of the intent (`basePrice`).
- Extracting too aggressively — every sub-expression is not a variable.
- Mutating the extracted variable later, defeating the readability gain.
```

- [ ] **Step 4: Write inline-variable.md**

```markdown
# Inline Variable

## Motivation
A variable's name adds nothing the expression doesn't already say, or the variable is referenced only once and lives only to be passed along.

## When NOT to use
When the variable name conveys intent the expression alone does not. When the expression is expensive and the variable is referenced multiple times.

## Mechanics
1. Check the right-hand side of the assignment is free of side effects.
2. If the variable is not already declared immutable, make it so and verify nothing reassigns it. 🧪
3. Find the first reference; replace it with the right-hand side.
4. Test. 🧪
5. Repeat for each reference.
6. Remove the variable declaration. 🧪

## Example
Before:
```
const basePrice = anOrder.basePrice;
return basePrice > 1000;
```
After:
```
return anOrder.basePrice > 1000;
```

## Common pitfalls
- Inlining an expression with side effects so it now runs multiple times.
- Inlining a variable whose name was the only documentation of intent.
- Forgetting to delete the original declaration once all references are inlined.
```

- [ ] **Step 5: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/catalog/extract-method.md \
        selrahcd-dot-claude/skills/refactoring/catalog/inline-method.md \
        selrahcd-dot-claude/skills/refactoring/catalog/extract-variable.md \
        selrahcd-dot-claude/skills/refactoring/catalog/inline-variable.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add Composing methods catalog entries
EOF
)"
```

---

### Task 6: Moving features catalog files

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/move-function.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/move-field.md`

- [ ] **Step 1: Write move-function.md**

```markdown
# Move Function

## Motivation
A function references data or behavior from another module more than from its own. Moving the function closer to what it uses reduces coupling and clarifies responsibility.

## When NOT to use
When the function uses data from both modules roughly equally. When moving would create a circular dependency between modules.

## Mechanics
1. Examine all program elements used by the function in its current location. Decide whether they should move too.
2. Check the function is not polymorphic (or handle all overrides).
3. Copy the function to its target context. Adjust it to fit (rename if needed, adjust parameter list).
4. Compile in the target context.
5. Work out how to reference the moved function from the source. Replace the function body in the source with a call to the moved function (or remove it entirely if no callers remain in the source). 🧪
6. Decide whether to keep the source function as a forwarding shim or remove it.
7. Update all callers to call the function in its new location. 🧪
8. Once no callers remain in the source, delete the shim. 🧪

## Example
Before: `Account.overdraftCharge()` accesses only fields on `AccountType`.
After: the method lives on `AccountType` as `overdraftCharge()`, and `Account` calls `this.type.overdraftCharge()`.

## Common pitfalls
- Moving a function whose surrounding context (logging, error handling, transaction boundary) is more relevant than its data references.
- Leaving forwarding shims indefinitely — they should be temporary scaffolding, not permanent.
- Moving without checking polymorphism, breaking subclass overrides.
```

- [ ] **Step 2: Write move-field.md**

```markdown
# Move Field

## Motivation
A field is more used by another class than by its current owner, or it logically belongs with another class's data. Move it so reads and writes happen where the data conceptually lives.

## When NOT to use
When access patterns are evenly split. When moving would force breaking encapsulation elsewhere.

## Mechanics
1. Ensure the field is encapsulated (has accessor methods). If not, apply Encapsulate Variable first.
2. Test. 🧪
3. Create the field in the target class with corresponding accessors.
4. Run a static check.
5. Update accessors in the source class to delegate to the target. 🧪
6. Examine callers. Where appropriate, update them to access the field via the target directly.
7. Remove the field from the source class. 🧪

## Example
Before: `Customer.discountRate` is read mostly by `CustomerContract`.
After: `CustomerContract.discountRate`, and `Customer.discountRate` is gone.

## Common pitfalls
- Moving without encapsulating first — direct field access scattered across callers makes the move risky.
- Forgetting to update persistence/serialization code that referenced the old location.
- Stopping after the delegate step, leaving the field "moved" but still living in two places.
```

- [ ] **Step 3: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/catalog/move-function.md \
        selrahcd-dot-claude/skills/refactoring/catalog/move-field.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add Moving features catalog entries
EOF
)"
```

---

### Task 7: Organizing data catalog files

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/encapsulate-variable.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/replace-primitive-with-object.md`

- [ ] **Step 1: Write encapsulate-variable.md**

```markdown
# Encapsulate Variable

## Motivation
A variable (field, module-level data) is accessed directly from many places. Wrapping access in getter/setter functions gives a single point to add validation, logging, or change the underlying storage later.

## When NOT to use
When the variable is genuinely local and short-lived. When the language already enforces controlled access (e.g., a private final field in a value object).

## Mechanics
1. Create get and set functions for the variable.
2. Run a static check.
3. Replace each reference to the variable with the appropriate function call, one at a time. 🧪
4. Restrict the visibility of the variable (private). 🧪
5. If the variable is a mutable structure, decide whether the getter should return a copy.

## Example
Before:
```
let defaultOwner = { firstName: "Martin", lastName: "Fowler" };
```
After:
```
let defaultOwnerData = { firstName: "Martin", lastName: "Fowler" };
function defaultOwner() { return defaultOwnerData; }
function setDefaultOwner(arg) { defaultOwnerData = arg; }
```

## Common pitfalls
- Returning a reference to a mutable internal structure, letting callers bypass the setter.
- Not migrating all references before restricting visibility — easy in dynamic languages.
- Encapsulating immutable primitives where the indirection adds noise without value.
```

- [ ] **Step 2: Write replace-primitive-with-object.md**

```markdown
# Replace Primitive with Object

## Motivation
A primitive (string, number) is carrying meaning and behavior beyond its raw type — comparisons, parsing, validation, formatting. Promoting it to a value object collects that behavior in one place.

## When NOT to use
When the primitive really is just a primitive — a counter, an array index, a temperature reading with no special operations.

## Mechanics
1. Apply Encapsulate Variable on the field that holds the primitive, if not already done.
2. Create a simple value class for the data. Constructor takes the primitive; getter returns it.
3. Run a static check.
4. Change the setter to wrap the incoming primitive in the new class.
5. Change the getter to return the underlying primitive (or the object, depending on consumer needs). 🧪
6. Consider renaming accessors to reflect the new abstraction.
7. Move behavior that operates on the primitive onto the new class. 🧪

## Example
Before: `order.priority = "high"` with string comparisons scattered everywhere.
After: `order.priority = new Priority("high")` with `priority.higherThan(other)` on the class.

## Common pitfalls
- Skipping Encapsulate Variable first, making the migration impossible to do incrementally.
- Making the new class hold so little behavior that it's just a wrapper — defer the promotion until behavior is real.
- Mixing the migration with adding new behavior, breaking the one-refactoring-per-commit rule.
```

- [ ] **Step 3: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/catalog/encapsulate-variable.md \
        selrahcd-dot-claude/skills/refactoring/catalog/replace-primitive-with-object.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add Organizing data catalog entries
EOF
)"
```

---

### Task 8: Simplifying conditionals catalog files

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/decompose-conditional.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/replace-conditional-with-polymorphism.md`

- [ ] **Step 1: Write decompose-conditional.md**

```markdown
# Decompose Conditional

## Motivation
A conditional is hard to read because each branch and the condition itself are inline blocks of logic. Extracting each into a well-named method turns the conditional into a readable summary of intent.

## When NOT to use
When the conditional and its branches are already one-liners that read clearly.

## Mechanics
1. Apply Extract Method to the condition. 🧪
2. Apply Extract Method to the then-branch. 🧪
3. Apply Extract Method to the else-branch (or each branch in an if/else-if chain). 🧪

## Example
Before:
```
if (date.before(SUMMER_START) || date.after(SUMMER_END))
  charge = quantity * winterRate + winterServiceCharge;
else
  charge = quantity * summerRate;
```
After:
```
if (notSummer(date))
  charge = winterCharge(quantity);
else
  charge = summerCharge(quantity);
```

## Common pitfalls
- Extracting predicates with names that restate the logic instead of its meaning.
- Stopping at the condition without extracting the branches — the inline branches still mask intent.
- Producing methods so small the call overhead dominates readability — group when natural.
```

- [ ] **Step 2: Write replace-conditional-with-polymorphism.md**

```markdown
# Replace Conditional with Polymorphism

## Motivation
A conditional dispatches on a type code (or kind tag) at multiple places. Moving each branch into a subclass turns the dispatch into a virtual call, eliminating the conditional and grouping behavior with type.

## When NOT to use
When there is only one such conditional and the cost of introducing a class hierarchy outweighs the readability gain. When the conditional dispatches on something other than type identity (e.g., a numeric range).

## Mechanics
1. If there isn't yet a class hierarchy, introduce one (subclasses for each branch of the conditional). Apply Replace Type Code with Subclasses first if needed.
2. Move the method containing the conditional into the superclass. 🧪
3. Pick one subclass. Override the method in that subclass and copy the matching branch into it. 🧪
4. Repeat for each subclass.
5. Once all branches are overridden, remove the conditional in the superclass method — or make the superclass method abstract. 🧪

## Example
Before:
```
class Bird {
  getSpeed() {
    switch(this.type) {
      case 'EUROPEAN': return 35;
      case 'AFRICAN': return 40 - 2 * this.numberOfCoconuts;
      case 'NORWEGIAN_BLUE': return this.isNailed ? 0 : 10 + this.voltage / 10;
    }
  }
}
```
After: `EuropeanBird`, `AfricanBird`, `NorwegianBlueBird` each override `getSpeed()`.

## Common pitfalls
- Skipping the hierarchy setup; trying to "polymorphize" without polymorphism in place.
- Migrating all branches in one step, producing a commit that touches every subclass at once.
- Leaving the original conditional behind as a default, defeating the point of the refactoring.
```

- [ ] **Step 3: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/catalog/decompose-conditional.md \
        selrahcd-dot-claude/skills/refactoring/catalog/replace-conditional-with-polymorphism.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add Simplifying conditionals catalog entries
EOF
)"
```

---

### Task 9: Refactoring APIs catalog files

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/rename-function.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/introduce-parameter-object.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/change-function-declaration.md`

- [ ] **Step 1: Write rename-function.md**

```markdown
# Rename Function

## Motivation
A function's name no longer reflects what it does (it has drifted, or was wrong from the start). A clear name is the most direct documentation a function can have.

## When NOT to use
When the function has many external callers you cannot update atomically and renaming would break them — apply a wider migration strategy instead.

## Mechanics
**Simple case (few callers, all internal):**
1. If the function is polymorphic, decide whether to rename all overrides at once.
2. Rename the function.
3. Find every caller. Update each. 🧪

**Migration case (many callers or an external API):**
1. Add a new function with the new name. Have its body call the old function. 🧪
2. Migrate callers one at a time to the new name. 🧪
3. Once no callers remain on the old name, remove the old function. 🧪

## Example
Before: `calc()` is called from twelve places. The function computes a customer's tier discount.
After: `tierDiscountFor(customer)`.

## Common pitfalls
- Renaming via IDE refactor across a polyglot codebase where some callers (templates, configs, reflection) are missed.
- Choosing a name that is technically accurate but obscure to the team.
- Renaming and changing the function's behavior in the same commit.
```

- [ ] **Step 2: Write introduce-parameter-object.md**

```markdown
# Introduce Parameter Object

## Motivation
A group of parameters travels together to many functions. Bundling them into an object names the cluster, reduces parameter-list noise, and creates a home for related behavior.

## When NOT to use
When the parameters genuinely have no shared meaning. When the cluster is used in only one place.

## Mechanics
1. Create a class to represent the cluster. Make it value-like (immutable, equals by content).
2. Run a static check.
3. Apply Change Function Declaration on each function that takes the cluster: add the new parameter object as a parameter, retaining the old parameters for now. 🧪
4. Update each caller to pass the new parameter object alongside the old arguments. 🧪
5. Migrate the function body to read from the new parameter object. 🧪
6. Apply Change Function Declaration again to remove the old parameters. 🧪
7. Move related behavior onto the new class as a follow-up (a separate refactoring).

## Example
Before: `withinRange(date, start, end)` and `findReadingsInRange(reading, start, end)` both take `start` and `end`.
After: `DateRange` class; `withinRange(date, range)` and `findReadingsInRange(reading, range)`.

## Common pitfalls
- Bundling parameters that travel together by coincidence rather than concept.
- Moving behavior onto the new class in the same commit — that's a separate Move Function step.
- Creating a mutable parameter object that leaks state across calls.
```

- [ ] **Step 3: Write change-function-declaration.md**

```markdown
# Change Function Declaration

## Motivation
A function's signature (name, parameters, return shape) no longer fits how it is used. Reshaping the declaration is the most fundamental refactoring on a function's interface and underlies many other refactorings.

## When NOT to use
When the function is part of a published API consumed by code you cannot update — apply a migration variant instead.

## Mechanics
**Simple change (few callers):**
1. If removing a parameter, ensure it isn't used in the body.
2. Make the declaration change.
3. Update each caller. 🧪

**Migration change (many callers):**
1. If the body needs to change, apply Extract Function on the body first to isolate it.
2. Apply Change Function Declaration to the extracted inner function.
3. Have the outer function call the inner with adapted arguments. 🧪
4. Migrate callers one at a time to the new signature. 🧪
5. When no callers remain on the outer function, remove it. 🧪
6. Optionally rename the inner function to the outer's old name.

## Example
Before: `circum(radius)`.
After: `circumference(radius)` (name change) or `circumference(radius, unit)` (parameter addition).

## Common pitfalls
- Combining a name change and a parameter change in one commit — split them.
- Forgetting reflective or dynamic callers (templates, DI containers, serialized configs).
- Migrating callers in bulk instead of one at a time, losing the ability to commit small reviewable steps.
```

- [ ] **Step 4: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/catalog/rename-function.md \
        selrahcd-dot-claude/skills/refactoring/catalog/introduce-parameter-object.md \
        selrahcd-dot-claude/skills/refactoring/catalog/change-function-declaration.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add Refactoring APIs catalog entries
EOF
)"
```

---

### Task 10: Dealing with inheritance catalog files

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/extract-superclass.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/replace-subclass-with-delegate.md`

- [ ] **Step 1: Write extract-superclass.md**

```markdown
# Extract Superclass

## Motivation
Two classes share data and behavior. Pulling the commonality into a superclass names the relationship and removes duplication.

## When NOT to use
When the apparent similarity is shallow and the classes will diverge — composition or a shared utility may fit better.

## Mechanics
1. Create an empty superclass. Make the candidate classes its subclasses.
2. Test. 🧪
3. Pull up a single shared element at a time (Pull Up Field, Pull Up Method, Pull Up Constructor Body), running the safety net after each. 🧪
4. Examine the remaining methods of each subclass to see if more can move up.
5. Look at callers of the subclasses — should any operate on the superclass type instead? 🧪

## Example
Before: `Employee` and `Department` both have `name`, `annualCost`, and `headCount`.
After: `Party` superclass; `Employee` and `Department` extend it.

## Common pitfalls
- Pulling up too much, creating a "god parent" with members not all subclasses need.
- Skipping the per-element pull-up, producing a single huge commit instead of a sequence.
- Forcing inheritance where composition would be cleaner — favor Extract Class first, then decide.
```

- [ ] **Step 2: Write replace-subclass-with-delegate.md**

```markdown
# Replace Subclass with Delegate

## Motivation
Inheritance was the right tool yesterday, but the subclass needs to vary along an axis the parent did not anticipate, or the subclass relationship is restrictive (single inheritance) when the variation should be composable. Replacing inheritance with delegation restores flexibility.

## When NOT to use
When inheritance models the relationship cleanly and the cost of indirection adds no value. When you need polymorphic substitutability across many call sites and a delegate would require manual dispatch.

## Mechanics
1. Create a delegate class for the variation the subclass represents. Move the subclass-specific data and methods to it.
2. In the parent class, add a field for the delegate and a constructor argument or factory to set it. 🧪
3. For each method overridden in the subclass, add a delegating method in the parent that calls the delegate.
4. Migrate callers from subclass instances to parent instances configured with the delegate. 🧪
5. Once no callers use the subclass directly, delete the subclass. 🧪

## Example
Before: `Booking` with `PremiumBooking extends Booking`.
After: `Booking` with an optional `PremiumDelegate`; `new Booking(...)` or `new Booking(..., new PremiumDelegate(...))`.

## Common pitfalls
- Trying to remove the inheritance and add the delegate in one commit.
- Implementing the delegate as a parallel class hierarchy of its own, recreating the problem.
- Leaving the subclass around as a "convenience" — defer cleanup and the migration drifts.
```

- [ ] **Step 3: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/catalog/extract-superclass.md \
        selrahcd-dot-claude/skills/refactoring/catalog/replace-subclass-with-delegate.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add Dealing with inheritance catalog entries
EOF
)"
```

---

### Task 11: Larger restructurings catalog files

**Files:**
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/extract-class.md`
- Create: `selrahcd-dot-claude/skills/refactoring/catalog/hide-delegate.md`

- [ ] **Step 1: Write extract-class.md**

```markdown
# Extract Class

## Motivation
A class has grown to hold two distinct responsibilities. Splitting it into two collaborating classes gives each a single reason to change.

## When NOT to use
When the apparent split is along a usage axis but not a conceptual one — wait for the conceptual split to be obvious before separating.

## Mechanics
1. Decide how to split responsibilities. Name the new class by its intent.
2. Create the empty new class.
3. In the source class, add a field referencing an instance of the new class. Initialize it in the constructor. 🧪
4. For each field that belongs to the new class, apply Move Field. 🧪
5. For each method that belongs to the new class, apply Move Function. 🧪
6. Review the public interfaces of both classes. Decide whether the new class is internal (accessed only via the source) or exposed directly to callers.
7. Update callers accordingly. 🧪

## Example
Before: `Person` holds name, address, phone-area, phone-number.
After: `Person` holds name and a `TelephoneNumber`; `TelephoneNumber` holds area, number, and behavior like formatting.

## Common pitfalls
- Moving fields in bulk instead of one at a time — each Move Field is its own commit per this skill's discipline.
- Exposing the new class everywhere when keeping it internal would preserve encapsulation.
- Splitting before the second responsibility is clearly visible, producing a phantom class that re-merges later.
```

- [ ] **Step 2: Write hide-delegate.md**

```markdown
# Hide Delegate

## Motivation
A client reaches through a server object to call methods on a delegate. The client now depends on the chain. Hiding the delegate behind methods on the server collapses that dependency.

## When NOT to use
When the delegate is part of the server's public contract by intent (e.g., exposing a collection). When wrapping every delegate method would balloon the server's interface (consider whether the server is doing too much).

## Mechanics
1. For each method on the delegate that clients call via the server, create a delegating method on the server.
2. Run a static check.
3. Update each client to call the new method on the server instead of reaching through. 🧪
4. Once no client reaches through, remove the server's accessor for the delegate (or restrict it). 🧪

## Example
Before:
```
manager = aPerson.department.manager;
```
After:
```
manager = aPerson.manager;
```

## Common pitfalls
- Wrapping every delegate method, producing a server with a sprawling interface that mirrors the delegate.
- Removing the delegate accessor before all clients are migrated.
- Hiding a delegate when the cleaner refactoring is to move the client's logic onto the server (or vice versa).
```

- [ ] **Step 3: Commit**

```bash
git add selrahcd-dot-claude/skills/refactoring/catalog/extract-class.md \
        selrahcd-dot-claude/skills/refactoring/catalog/hide-delegate.md
git commit -m "$(cat <<'EOF'
feat(dot-claude): add Larger restructurings catalog entries
EOF
)"
```

---

### Task 12: Plugin metadata updates

**Files:**
- Modify: `selrahcd-dot-claude/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `selrahcd-dot-claude/README.md`

- [ ] **Step 1: Bump plugin version in plugin.json**

Edit `selrahcd-dot-claude/.claude-plugin/plugin.json`. Change:

```json
  "version": "1.29.0",
```

to:

```json
  "version": "1.30.0",
```

- [ ] **Step 2: Validate plugin.json**

Run: `jq empty selrahcd-dot-claude/.claude-plugin/plugin.json`
Expected: no output (valid JSON).

- [ ] **Step 3: Bump matching version in marketplace.json**

Edit `.claude-plugin/marketplace.json`. In the `dot-claude` plugin entry, change:

```json
      "version": "1.29.0"
```

to:

```json
      "version": "1.30.0"
```

- [ ] **Step 4: Validate marketplace.json**

Run: `jq empty .claude-plugin/marketplace.json`
Expected: no output.

- [ ] **Step 5: Add Skills entry to plugin README**

Edit `selrahcd-dot-claude/README.md`. In the `### Skills` section, add this entry after the existing `#### test-driven-development` and `#### adr` entries:

```markdown
#### `refactoring`
Drive a refactor as a sequence of small, named refactorings from Martin Fowler's catalog. Each named refactoring is one commit, verified against a configured safety net (tests, type-checker, or manual review):
- 17 refactorings in the v1 catalog (Extract Method, Inline Variable, Extract Class, Replace Conditional with Polymorphism, etc.)
- Strict state-machine workflow modeled on `tdd-process`
- Hybrid planning: plan upfront, evolve between steps
- Invoke via `/refactor` or natural language ("refactor this", "extract method", "rename X")
```

- [ ] **Step 6: Add Commands entry to plugin README**

Edit `selrahcd-dot-claude/README.md`. In the `### Commands` section, add:

```markdown
#### `/selrahcd-dot-claude:refactor`
Starts the refactoring skill. Optional free-text description seeds the SETUP state (e.g., `/refactor split Order into Order + TaxCalculator`).
```

- [ ] **Step 7: Add Credits entry**

Edit `selrahcd-dot-claude/README.md`. In the `## Credits` section, add:

```markdown
- Refactoring skill: [Martin Fowler — *Refactoring* (2nd ed.)](https://martinfowler.com/books/refactoring.html)
```

- [ ] **Step 8: Commit**

```bash
git add selrahcd-dot-claude/.claude-plugin/plugin.json \
        .claude-plugin/marketplace.json \
        selrahcd-dot-claude/README.md
git commit -m "$(cat <<'EOF'
chore(dot-claude): bump to 1.30.0 for refactoring skill
EOF
)"
```

---

### Task 13: Smoke test

**Files:** none.

- [ ] **Step 1: Verify file structure**

Run:
```bash
find selrahcd-dot-claude/skills/refactoring -type f | sort
```

Expected output (one file per line):
```
selrahcd-dot-claude/skills/refactoring/README.md
selrahcd-dot-claude/skills/refactoring/SKILL.md
selrahcd-dot-claude/skills/refactoring/catalog/INDEX.md
selrahcd-dot-claude/skills/refactoring/catalog/change-function-declaration.md
selrahcd-dot-claude/skills/refactoring/catalog/decompose-conditional.md
selrahcd-dot-claude/skills/refactoring/catalog/encapsulate-variable.md
selrahcd-dot-claude/skills/refactoring/catalog/extract-class.md
selrahcd-dot-claude/skills/refactoring/catalog/extract-method.md
selrahcd-dot-claude/skills/refactoring/catalog/extract-superclass.md
selrahcd-dot-claude/skills/refactoring/catalog/extract-variable.md
selrahcd-dot-claude/skills/refactoring/catalog/hide-delegate.md
selrahcd-dot-claude/skills/refactoring/catalog/inline-method.md
selrahcd-dot-claude/skills/refactoring/catalog/inline-variable.md
selrahcd-dot-claude/skills/refactoring/catalog/introduce-parameter-object.md
selrahcd-dot-claude/skills/refactoring/catalog/move-field.md
selrahcd-dot-claude/skills/refactoring/catalog/move-function.md
selrahcd-dot-claude/skills/refactoring/catalog/rename-function.md
selrahcd-dot-claude/skills/refactoring/catalog/replace-conditional-with-polymorphism.md
selrahcd-dot-claude/skills/refactoring/catalog/replace-primitive-with-object.md
selrahcd-dot-claude/skills/refactoring/catalog/replace-subclass-with-delegate.md
```

- [ ] **Step 2: Verify slash command file**

Run: `cat selrahcd-dot-claude/commands/refactor.md`
Expected: frontmatter with `name: refactor` and the body referencing the refactoring skill.

- [ ] **Step 3: Verify INDEX.md links resolve**

Run:
```bash
grep -oE '\]\([a-z-]+\.md\)' selrahcd-dot-claude/skills/refactoring/catalog/INDEX.md \
  | sed 's/](//;s/)//' \
  | while read f; do test -f "selrahcd-dot-claude/skills/refactoring/catalog/$f" || echo "MISSING: $f"; done
```
Expected: no output (no missing files).

- [ ] **Step 4: Verify version sync**

Run:
```bash
echo "plugin.json:    $(jq -r .version selrahcd-dot-claude/.claude-plugin/plugin.json)"
echo "marketplace:    $(jq -r '.plugins[] | select(.name=="dot-claude") | .version' .claude-plugin/marketplace.json)"
```
Expected:
```
plugin.json:    1.30.0
marketplace:    1.30.0
```

- [ ] **Step 5: Manual load test in Claude Code**

Reload the plugin in Claude Code (`/plugin reload` or restart). Then:
1. Confirm `refactoring` appears in the skills list.
2. Confirm `/refactor` is available as a slash command.
3. Optionally start a dry run: invoke `/refactor` on a trivial target and confirm the SETUP state announces correctly.

This step is manual — the implementing engineer must do it interactively. No automation.

- [ ] **Step 6: Final note**

No commit at this task — the smoke test verifies prior commits. If any verification fails, return to the corresponding task to fix and re-commit.

---

## Self-review notes

**Spec coverage check (against `docs/superpowers/specs/2026-05-13-refactoring-skill-design.md`):**

| Spec requirement | Plan coverage |
|---|---|
| File layout (skill dir, README, INDEX, 17 catalog files, slash command, metadata bumps) | Tasks 1-12 |
| State machine (10 states, prefixes, guards) | Task 1 (SKILL.md) |
| Load-bearing guards (APPLY→VERIFY, VERIFY→COMMIT, one-refactoring-per-commit) | Task 1 (SKILL.md states + Rules section) |
| Catalog `INDEX.md` format | Task 3 |
| Per-refactoring file format (Motivation / When NOT / Mechanics with 🧪 / Example / Pitfalls) | Tasks 5-11 |
| v1 scope: 17 refactorings | Tasks 5-11 |
| Safety net options (tests / type / both / manual) | Task 1 (SETUP state actions) |
| Pre-flight (clean tree, baseline green) | Task 1 (SETUP state actions) |
| Commit format (`refactor: <Name> '<target>' from <location>`) | Task 1 (COMMIT state actions) |
| Slash command `/refactor` | Task 4 |
| Natural-language triggers (in frontmatter description) | Task 1 (frontmatter) |
| Independence from `tdd-process` | Task 1 (no cross-references) + Task 2 (README "Limits") |
| Plugin metadata bumps | Task 12 |
| README Skills entry + Credits | Task 12 |

**No spec requirement is unaddressed.**
