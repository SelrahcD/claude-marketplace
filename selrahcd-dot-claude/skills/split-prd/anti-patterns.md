# Anti-Pattern Detection Guide

Use this guide to identify common story splitting anti-patterns in PRDs.

## Core Principle: The Usability Test

**Every story must be usable end-to-end.**

A user must be able to _complete a real task_ with the output of a story. Not just "see value" but actually use it.

| Test             | Question                                           |
| ---------------- | -------------------------------------------------- |
| **Usability**    | Can the user complete a task with ONLY this story? |
| **Independence** | Does it work without other stories being done?     |
| **Entry Point**  | Does this story include its own way to access it?  |

### Entry Point Rule

**A story must include its own entry point.** If Story B needs a button on Screen A to access it, then Story B adds that button—not Story A.

**Why:** Prevents dead-end buttons, keeps stories independent, ensures each story is self-contained.

**Bad:**

```
S1: User views expense groups
    - Shows list of groups
    - "View expenses" button on each group (LEADS NOWHERE!)

S2: User views expenses in group
    - Shows expense list
    - Assumes button exists from S1
```

S1 has a button that does nothing. S2 depends on S1's UI.

**Good:**

```
S1: User views expense groups
    - Shows list of groups
    - Tapping group shows empty state or "coming soon"
    - Story is complete and usable as-is

S2: User views expenses in group
    - ADDS tap handler to group list item
    - Shows expense list when group tapped
    - Story includes its own entry point
```

Each story is self-contained. No dead-end buttons.

---

## Splitting: Good vs Bad Axes

When a story is too big, don't split by component. Find a different axis:

| Good Split Axis   | Example                        | Why It Works           |
| ----------------- | ------------------------------ | ---------------------- |
| **View mode**     | List view → Paginated view     | Each is complete       |
| **Input method**  | Manual entry → Receipt scan    | Manual works alone     |
| **Data scope**    | Single group → Multiple groups | Single group is usable |
| **Feature depth** | Equal split → Custom split     | Each split type works  |
| **Platform**      | Mobile → Tablet                | Mobile is complete     |
| **Quality**       | Basic UI → Polished UI         | Basic version works    |

| Bad Split Axis    | Example                | Problem                         |
| ----------------- | ---------------------- | ------------------------------- |
| **By component**  | View → Navigate → Edit | Can't use view without navigate |
| **By UI element** | Amount → Payer → Split | Incomplete information          |
| **By layer**      | Data → Logic → UI      | No value until combined         |

**If splitting breaks usability, find a different axis.**

---

## Anti-Pattern Catalog

### Unusable Fragment

**Symptom:** Story is split so finely that individual pieces cannot complete a task.

**Examples:**

- "User views expense details" (but can't navigate to find an expense)
- "User sees balance summary" (but can't see which expenses contribute)
- "User enters expense amount" (but can't save it)

**Detection:** Ask "Can the user complete their goal with ONLY this story?"

**Fix:** Combine fragments into usable story, or find different split axis.

---

### Horizontal Slice

**Symptom:** Story describes a single technical layer without user-facing value.

**Examples:**

- "Backend story"
- "Database layer"
- "API endpoints"
- "D2.1: Expense data layer"

**Detection Keywords:** layer, backend, frontend, database, API, infrastructure, schema, migration

**Fix:** Slice vertically through all layers. Ask "What can the user DO after this?"

**Before:**

```
D2.1: Expense data layer
D2.2: Expense API endpoints
D2.3: Expense UI components
```

**After:**

```json
{
  "category": "functional",
  "description": "User views group expenses",
  "steps": ["Open group", "See expense list", "Tap expense for details"],
  "acceptance_criteria": [
    "Expenses shown with date and amount",
    "Detail view shows payer and split",
    "Balances displayed"
  ],
  "passes": false
}
```

---

### Infrastructure Milestone

**Symptom:** Entire milestone dedicated to setup with no user value.

**Examples:**

- "M1: Project setup"
- "M0: Development environment"
- "D1.1: Initialize repository"

**Detection Keywords:** setup, initialize, configure, bootstrap, scaffold, infrastructure

**Fix:** Embed setup in the first user story. Setup is a means, not an end.

**Before:**

```
M1: Project Setup
- D1.1: React Native project initialization
- D1.2: Code quality tooling
- D1.3: CI pipeline
```

**After:**

```json
{
  "category": "functional",
  "description": "User opens app and sees their groups",
  "steps": ["Launch app", "See list of expense groups", "Tap to open a group"],
  "acceptance_criteria": [
    "App launches without crash",
    "Groups list renders",
    "Navigation to group works"
  ],
  "passes": false
}
```

Note: Project setup, tooling, and CI happen as part of delivering this story.

---

### Technical Decomposition

**Symptom:** Deliverables named after technical components, not user outcomes.

**Examples:**

- "D2.1: Data layer"
- "D2.2: State management"
- "D2.3: Component library"

**Detection Keywords:** component, module, service, handler, manager, utility, helper

**Fix:** Ask "What can the user DO after this is complete?"

---

### Iceberg Story

**Symptom:** Small visible UI but huge hidden technical work.

**Examples:**

- "Add expense form" (requires split calculation, currency handling, offline sync)
- "Show balance summary" (requires debt simplification algorithm, multi-currency)

**Detection:** UI description seems simple but involves complex backend work.

**Fix:** Split by data/rule complexity. Deliver simplest version first.

**Before:**

```
User can add and split expenses
```

**After:**

```json
{"category": "functional", "description": "User adds expense with equal split", "steps": ["Tap add expense", "Enter amount", "Save with equal split"], "acceptance_criteria": ["Amount entry available", "Split divided equally", "Expense saved to list"], "passes": false}
{"category": "functional", "description": "User adds expense with custom amounts", "steps": ["Tap add expense", "Enter amount", "Assign custom shares to each person"], "acceptance_criteria": ["Custom amount input per person", "Total must match expense amount", "Validation prevents mismatch"], "passes": false}
{"category": "functional", "description": "User adds expense with percentage split", "steps": ["Tap add expense", "Enter amount", "Assign percentages"], "acceptance_criteria": ["Percentage input available", "Must total 100%", "Amounts calculated from percentages"], "passes": false}
```

---

### Component Story

**Symptom:** Story describes building a component, not using it.

**Examples:**

- "Build the balance summary component"
- "Create the expense form"
- "Implement the settlement calculator"

**Detection Keywords:** build, create, implement, develop, construct (when referring to components)

**Fix:** Describe what the user can do WITH the component.

**Before:**

```
Build the balance summary component
```

**After:**

```json
{
  "category": "functional",
  "description": "User sees who owes them money",
  "steps": ["Open group", "See balance summary", "See list of people who owe me"],
  "acceptance_criteria": [
    "Balance summary visible on group screen",
    "Shows net amount per person",
    "Positive = they owe me, negative = I owe them"
  ],
  "passes": false
}
```

---

### Dependency Chain

**Symptom:** Stories that cannot deliver value without other stories being complete first.

**Examples:**

- "D2.1 depends on D1.3 depends on D1.2 depends on D1.1"
- Multiple stories required before any user value

**Detection:** Check dependency field in specs. Long chains indicate problem.

**Fix:** Restructure so each story can deliver some value independently.

---

### Gold Plating

**Symptom:** Story includes unnecessary polish or features.

**Examples:**

- "Beautiful animations" in MVP
- "Full error handling for all edge cases" early on
- "Support all currencies" when one would do

**Detection Keywords:** beautiful, polished, complete, full, all, every, comprehensive

**Fix:** Split quality enhancements into separate stories. Deliver functional first.

---

### Spike Disguised as Story

**Symptom:** Research or investigation pretending to deliver value.

**Examples:**

- "Investigate payment integration options"
- "Research offline sync strategies"
- "Evaluate state management libraries"

**Detection Keywords:** investigate, research, evaluate, explore, assess, analyze

**Fix:** Make it an explicit spike with timebox. Follow with real story.

```json
{
  "category": "technical",
  "description": "Spike: Evaluate debt simplification algorithms",
  "steps": ["Research 3 approaches", "Build proof of concept", "Document findings"],
  "acceptance_criteria": [
    "Comparison documented",
    "POC demonstrates feasibility",
    "Recommendation made"
  ],
  "passes": false
}
```

---

### Overly Complex First Story

**Symptom:** First story tries to do too much instead of the simplest valuable thing.

**Examples:**

- "User views detailed expense breakdown with per-item splits and category tracking"
- "User settles up with integrated payment processing"

**Detection:** First story in a capability area has many acceptance criteria or complex steps.

**Fix:** Propose simpler alternative that still delivers value.

**Before:**

```json
{
  "category": "functional",
  "description": "User views expense with itemized breakdown",
  "steps": [
    "Open expense",
    "See line items",
    "See per-person item assignment",
    "See category for each item"
  ],
  "acceptance_criteria": [
    "Itemized view available",
    "Items assigned to people",
    "Categories displayed",
    "Totals calculated"
  ],
  "passes": false
}
```

**After (simpler first):**

```json
{
  "category": "functional",
  "description": "User views expense details",
  "steps": ["Open expense", "See amount and description", "See who paid", "See how it was split"],
  "acceptance_criteria": [
    "Amount and description shown",
    "Payer displayed",
    "Split breakdown visible"
  ],
  "passes": false
}
```

Then propose itemization as a follow-up story.

---

## Validation Checklist

For each story, verify:

| Check           | Question                             | Pass Criteria                    |
| --------------- | ------------------------------------ | -------------------------------- |
| **Usable**      | Can user complete a real task?       | End-to-end workflow works        |
| **Entry Point** | Does story include its own access?   | No dead-end buttons elsewhere    |
| Vertical        | Does it touch all layers needed?     | User can see/use the result      |
| Independent     | Can it deliver value alone?          | No other stories required        |
| Valuable        | Does user get something?             | Clear user benefit stated        |
| Testable        | Can we verify it works?              | Acceptance criteria are specific |
| Small           | Can it fit in a sprint?              | Scope is bounded                 |
| User-focused    | Is it written from user perspective? | Starts with "User can..."        |
| Minimal         | Is this the simplest version?        | No unnecessary features included |

## Quick Reference

| Anti-Pattern            | Key Signal                   | Quick Fix                            |
| ----------------------- | ---------------------------- | ------------------------------------ |
| **Unusable fragment**   | Can't complete task alone    | Combine or find different split axis |
| **Missing entry point** | Assumes UI from other story  | Story adds its own button/link       |
| Horizontal slice        | Layer names                  | Add user action                      |
| Infrastructure          | "Setup" milestone            | Embed in first story                 |
| Technical decomposition | Component names              | Ask "user can DO what?"              |
| Iceberg                 | Simple UI, complex backend   | Split by data complexity             |
| Component story         | "Build the X"                | "User can Y with X"                  |
| Dependency chain        | Long depends-on list         | Make independently valuable          |
| Gold plating            | "Beautiful", "complete"      | Defer quality stories                |
| Disguised spike         | "Research", "evaluate"       | Make explicit spike                  |
| Overly complex          | Too many acceptance criteria | Find simpler first version           |
