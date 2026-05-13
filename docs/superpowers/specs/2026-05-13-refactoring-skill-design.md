# Refactoring skill — design

**Date:** 2026-05-13
**Plugin:** `selrahcd-dot-claude`
**Skill name:** `refactoring`

## Goal

Turn a refactor request into a clean sequence of small commits — one per named refactoring from Fowler's catalog — each verified against a configured safety net. The git history becomes the unit of review: a PR reviewer reading the commit list sees the sequence of named refactorings applied, in order, without having to reconstruct intent from diffs.

## Design decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Scope | Discipline (small step → verify → commit) **plus** catalog of named refactorings from Fowler. One catalog refactoring = one step = one commit. |
| Safety net | Tests must pass after each step by default. Soft fallback: user opts into manual-review mode at SETUP if no tests exist. |
| Planning | Hybrid: produce an ordered plan up front, but the plan can evolve at REASSESS between steps. |
| Catalog layout | `SKILL.md` (always loaded) + `catalog/INDEX.md` (loaded at PLAN) + one `catalog/<name>.md` per refactoring (lazy-loaded at SELECT). |
| Trigger | Slash command `/refactor` **and** natural-language description matchers. Independent from `tdd-process`. |
| Workflow shape | Strict state machine modeled on `tdd-process`. Every message starts with the current state prefix. |
| Commit message | `refactor: <Refactoring Name> '<target>' from <location>`. Optional 1-3 line body only when motivation is non-obvious. |
| Verification cadence | Adaptive. Each catalog file marks sub-steps with 🧪 where a compile/test is required during APPLY. Final VERIFY always runs the safety net before COMMIT. |

## File layout

```
selrahcd-dot-claude/
├── .claude-plugin/
│   └── plugin.json                        # version bump (minor)
├── commands/
│   └── refactor.md                        # /refactor slash command (thin wrapper)
├── skills/
│   └── refactoring/
│       ├── SKILL.md                       # always loaded: discipline + state machine + rules
│       ├── README.md                      # usage + examples
│       └── catalog/
│           ├── INDEX.md                   # one line per refactoring
│           ├── extract-method.md
│           ├── inline-method.md
│           ├── extract-variable.md
│           ├── inline-variable.md
│           ├── move-function.md
│           ├── move-field.md
│           ├── encapsulate-variable.md
│           ├── replace-primitive-with-object.md
│           ├── decompose-conditional.md
│           ├── replace-conditional-with-polymorphism.md
│           ├── rename-function.md
│           ├── introduce-parameter-object.md
│           ├── change-function-declaration.md
│           ├── extract-superclass.md
│           ├── replace-subclass-with-delegate.md
│           ├── extract-class.md
│           └── hide-delegate.md
└── README.md                              # add Skills entry + Credits to Fowler

.claude-plugin/marketplace.json            # matching version bump
```

## State machine

Every message starts with the current state prefix. Modeled on `tdd-process`.

| State | Prefix | Purpose |
|---|---|---|
| SETUP | `🎯 REFACTOR: SETUP` | One-time. Establish safety net (tests / type-checker / both / manual). Capture target code and goal. Verify clean working tree. Run safety net once at green baseline. |
| PLAN | `📋 REFACTOR: PLAN` | Read `catalog/INDEX.md`. Produce an ordered list of named refactorings. Present plan; await user approval before applying anything. |
| SELECT | `🔍 REFACTOR: SELECT` | Pick the next refactoring from the plan. Read its `catalog/<name>.md` so the mechanics are in context. |
| APPLY | `🔧 REFACTOR: APPLY` | Execute the mechanics' sub-steps. At each sub-step marked 🧪 in the catalog file, run the safety-net command (or in manual mode, show the diff and pause). |
| VERIFY | `🧪 REFACTOR: VERIFY` | Final verification before commit. Run the safety net and show verbatim output. In manual-review mode, show the cumulative diff and wait for explicit "ok". |
| COMMIT | `💾 REFACTOR: COMMIT` | Create exactly one commit with the conventional `refactor:` message. |
| REASSESS | `🔄 REFACTOR: REASSESS` | After commit: is the plan still right? If new context emerged, update the plan and announce the change. Then back to SELECT or to COMPLETE. |
| COMPLETE | `✅ REFACTOR: COMPLETE` | All planned steps applied. Summary: commit count, refactorings applied, follow-up suggestions. |
| BLOCKED | `⚠️ REFACTOR: BLOCKED` | Cannot proceed (dirty working tree mid-flight, persistent test failure, missing mechanics). Stop and wait for user. |
| VIOLATION_DETECTED | `🔥 REFACTOR: VIOLATION_DETECTED` | Self-detected drift (skipped verify, multi-refactoring commit, missing state prefix). Announce, propose recovery. |

### Transitions

```
                    user request
                         ↓
                  ┌────────────┐
                  │   SETUP    │
                  └─────┬──────┘
                        ↓
                  ┌────────────┐ ←─────────── REASSESS (plan changed)
                  │    PLAN    │
                  └─────┬──────┘
                        ↓ user approves plan
                  ┌────────────┐
              ┌──→│   SELECT   │
              │   └─────┬──────┘
              │         ↓ catalog file loaded
              │   ┌────────────┐
              │   │   APPLY    │ ← (internal 🧪 verifies per catalog markers)
              │   └─────┬──────┘
              │         ↓ mechanics done
              │   ┌────────────┐
              │   │   VERIFY   │
              │   └─────┬──────┘
              │         ↓ safety net green
              │   ┌────────────┐
              │   │   COMMIT   │
              │   └─────┬──────┘
              │         ↓
              │   ┌────────────┐
              │   │  REASSESS  │ ── plan changed ──→ PLAN
              │   └─────┬──────┘
              │         │ more steps remain
              └─────────┘
                        │ all steps done
                        ↓
                  ┌────────────┐
                  │  COMPLETE  │
                  └────────────┘
```

### Load-bearing guards

- **APPLY → VERIFY:** Cannot transition without showing the executed mechanics sub-steps and the output of each 🧪 verification along the way.
- **VERIFY → COMMIT:** Cannot transition without showing verbatim safety-net output (test pass / type-check pass) or — in manual mode — receiving an explicit "ok" from the user on the shown diff.
- **One-refactoring-per-commit invariant:** Between any two commits, exactly one named refactoring is applied. If Claude detects unrelated changes in the working tree (e.g., reformatted whitespace far from the target), it triggers VIOLATION_DETECTED and proposes reverting the unrelated changes before committing.
- **No commits in BLOCKED:** The state machine cannot commit without a successful VERIFY.

## Catalog

### `INDEX.md` format

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

### Per-refactoring file format

```markdown
# <Refactoring Name>

## Motivation
2-4 sentences. When does this refactoring earn its keep? What smell does it address?

## When NOT to use
1-2 sentences. Common misapplications.

## Mechanics
Numbered sub-steps. Each step that should be followed by a verification carries a 🧪 marker.

1. <Step 1>
2. <Step 2> 🧪
3. <Step 3>
4. <Step 4> 🧪

## Example
Short before/after code snippet (language-agnostic where possible; pseudo-code if needed).

## Common pitfalls
2-4 bullets of "watch out for…" specific to this refactoring.
```

The 🧪 marker is the only mechanical input the APPLY state needs from the catalog — Claude reads the file, applies each sub-step, and runs the safety net after every sub-step that carries the marker.

### v1 scope

The 17 refactorings listed in INDEX.md ship in v1. Adding more later is a single new file in `catalog/` plus one entry in `INDEX.md` — no SKILL.md or state-machine changes needed.

## Safety net

Established at SETUP, enforced throughout.

The skill asks the user to declare one of:

- **(a) tests** — a test command (e.g., `npm test`, `pytest`) that must pass green
- **(b) type-checker** — a compile/type-check command (e.g., `tsc --noEmit`, `mypy .`)
- **(c) tests + type-checker** — both required
- **(d) manual review** — explicit opt-out; user confirms each step by replying "ok"

Whatever is declared becomes the gate for VERIFY → COMMIT.

**Pre-flight at SETUP:**
- Working tree must be clean (`git status` empty). If not, ask the user to commit or stash first.
- Working branch is recorded. No branch switching mid-refactor.
- Safety-net command (if (a)/(b)/(c)) is run once before PLAN to confirm green baseline. If it fails at baseline, the skill enters BLOCKED — refactoring a broken-test baseline gives no signal.

## Commit message

**Title:** `refactor: <Refactoring Name> '<target>' from <location>`

Examples:
- `refactor: Extract Method 'calculateTax' from Order#total`
- `refactor: Inline Variable 'temp' in PriceCalculator#discountFor`
- `refactor: Extract Class 'TelephoneNumber' from Person`

**Body (optional, only when motivation is non-obvious):** 1-3 lines explaining why this commit exists alone — e.g., "preparing for Replace Conditional with Polymorphism" or "splits responsibility before Move Method".

**Default is no body.** Trivial refactorings (Inline Variable, Rename) get title only.

The refactoring skill writes its own commit message and does not delegate to `/commit`, because the refactoring name is load-bearing in the title.

## Triggers

### Slash command

`/refactor [description]` lives in `selrahcd-dot-claude/commands/refactor.md`. Thin wrapper that invokes the skill. With no argument, the skill asks "what code, what goal?" in SETUP. With an argument, the description seeds SETUP.

### Natural-language

The skill's frontmatter `description` is what enables auto-invocation. Draft:

> "Apply a refactor as a sequence of small, named refactorings from Fowler's catalog, with one commit per step verified by tests. Use when the user says 'refactor', 'extract method', 'extract class', 'inline', 'rename', 'move method', 'clean up this code', 'restructure without changing behavior', or invokes `/refactor`."

### Independence from tdd-process

The two skills never invoke each other. If a user is in TDD's REFACTOR state and wants a structured multi-step refactor, they exit `tdd-process` and run `/refactor` separately. A future change may add a one-line pointer from tdd-process's REFACTOR state, but that is out of scope here.

## Plugin metadata updates

- Bump `selrahcd-dot-claude/.claude-plugin/plugin.json` `version` (minor — new skill + new command).
- Bump matching `version` for the `dot-claude` plugin entry in `.claude-plugin/marketplace.json`.
- Add a Skills entry to `selrahcd-dot-claude/README.md` describing the refactoring skill and the `/refactor` command.
- Add a Credits line to `selrahcd-dot-claude/README.md`: `Refactoring skill: Martin Fowler — Refactoring (2nd ed.)`.

## Out of scope (for v1)

- A `/refactor-add` skill that scaffolds a new catalog file from a template.
- Integration hooks with `tdd-process`'s REFACTOR state.
- Language-specific catalog variants (the catalog stays language-agnostic).
- Automated detection of which refactoring to suggest (the user/Claude names the refactoring; the skill applies it).
- More than the 17 refactorings listed. Adding more is a follow-up.

## Success criteria

A PR review of a refactor session shows:
1. A clean sequence of commits, each titled `refactor: <Name> …`.
2. Each commit confined to one named refactoring.
3. Tests green on every commit in the sequence (or, in manual mode, an explicit "ok" record in the conversation).
4. The PR reviewer can follow the sequence as a narrative: "first extracted, then moved, then made polymorphic," without opening every diff.
