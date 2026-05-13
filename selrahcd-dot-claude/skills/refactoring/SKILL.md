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
