---
name: split-prd
description: Transform technical PRD features into usable user stories. Use when analyzing PRDs, splitting features into stories, or when user mentions story splitting, user stories, or INVEST criteria.
---

# PRD Splitting Skill

Transform technical PRD features into usable user stories, update the PRD with story references, and create spec files.

## Core Principle: Usability

**Every story must be usable end-to-end.** A user must be able to complete a real task with the output of a story—not just "see value" but actually use it.

See [anti-patterns.md](anti-patterns.md) for the full Usability Test, Entry Point Rule, and good vs bad split axes.

**Key rules:**

- Each story includes its own entry point (buttons, links, navigation)
- If a story is too big, split by user journey (view mode, input method, data scope)—NOT by component
- Stories can be built in any order that makes sense

## Core Concepts

### Feature Sets vs Milestones

- **Feature sets** = logical groupings of related functionality (e.g., "Transaction Management", "Budget Tracking")
- **Milestones** = delivery groupings that can include stories from multiple feature sets
- A milestone might include "basic transactions + basic budget view" while the full "Budget Tracking" feature set spans multiple milestones

### ID Scheme

Stories use feature-set based IDs: `{CODE}-{NN}`

- Code: 2-3 uppercase letters derived from feature set name (first letters of words)
- Number: Sequential within feature set (01, 02, etc.)

Examples: `TM-01` (Transaction Management), `BT-02` (Budget Tracking)

## Usage

`/split-prd [path]` - Analyze PRD and create user stories as specs

**Arguments:**

- `path` (optional): Path to PRD file. Defaults to `docs/PRD.md`

## The 3 Levels of Slicing

| Level          | Purpose                    | Output               |
| -------------- | -------------------------- | -------------------- |
| **Capability** | What value can we deliver? | User capabilities    |
| **Functional** | How do users achieve this? | User journey steps   |
| **Technical**  | How do we build each step? | Implementation tasks |

## Workflow

### Step 1: Generate Split (Sub-agent)

Spawn an Explore sub-agent to analyze the PRD and generate the split:

```
Task: Generate user story split from PRD

1. Read PRD at [path] (or docs/PRD.md if not specified)
2. Read techniques at .claude/skills/split-prd/techniques.md
3. Read anti-patterns at .claude/skills/split-prd/anti-patterns.md

Analysis:
4. Identify problem statement and features
5. Find generic terms (who, what, where)
6. Explore variations using techniques

Capability Slicing:
7. Apply capability slicing - what value can we deliver?
8. Group capabilities into feature sets
9. Derive feature set codes (first letters of words, 2-3 chars uppercase)

Functional Slicing:
10. For each capability, identify user journey steps
11. Find simplest path to deliver value
12. Note what can be deferred to later stories

Output for each story:
- Proposed ID (e.g., TM-01)
- Feature set name and code
- Title
- Description (user-facing)
- Acceptance criteria
- Dependencies (other story IDs)
- PRD reference (section)
```

### Step 2: Validate Specs (Parallel Sub-agents)

Spawn **one `spec-validator` agent per spec**, running in parallel. Each agent validates a single spec against all rules defined in [validation-rules.md](validation-rules.md).

**Agent:** `.claude/agents/spec-validator.md`

**Execution:**

Launch all validation agents in a single message with parallel Task tool calls:

```
For each spec file:
  Task(
    subagent_type: "spec-validator",
    prompt: "Validate spec {SPEC-ID} at specs/{filename}.md"
  )
```

**Example with 3 specs:**

```
Task 1: Validate spec TM-01 at specs/TM-01-add-transaction.md
Task 2: Validate spec TM-02 at specs/TM-02-view-transactions.md
Task 3: Validate spec BT-01 at specs/BT-01-set-budget.md
```

All three run in parallel and return validation reports.

**After all agents complete:**

1. Collect results from all validators
2. Separate into: passing specs, failing specs
3. For failing specs, prepare decision options (see Step 4)
4. Present summary and begin one-at-a-time decision flow

**Validation Rules Reference:**

See [validation-rules.md](validation-rules.md) for complete checklist including:

- Entry point rules (owns entry point, no forward entry points, self-contained)
- Usability rules (completes task, standalone value, no dead ends)
- INVEST criteria
- Anti-pattern detection

**INVEST Criteria:**

- **I**ndependent - Usable alone, includes its own entry point
- **N**egotiable - Scope can flex
- **V**aluable - User can complete a real task
- **E**stimable - Team can size it
- **S**mall - Fits in a sprint (if too big, find different split axis—not by component)
- **T**estable - Can verify it works end-to-end

### Step 3: Propose PRD Update

Update the PRD with:

1. **Feature Sets table** (add or update):

```markdown
## Feature Sets

| Code | Name                   | Description                            |
| ---- | ---------------------- | -------------------------------------- |
| TM   | Transaction Management | Record and view financial transactions |
| BT   | Budget Tracking        | Set and monitor spending budgets       |
```

2. **Milestone sections** with story links:

```markdown
### M1: Basic Transaction Flow

**Goal:** User can record and view transactions.

- [TM-01](../specs/TM-01-add-transaction.md): Add a transaction
- [TM-02](../specs/TM-02-view-transactions.md): View transaction list
- [BT-01](../specs/BT-01-view-spending.md): View spending summary
```

Present summary to user for validation.

### Step 4: User Validation (One Issue at a Time)

Present validation issues **one at a time** to avoid overwhelming the user. For each issue:

1. **Show the issue:** Display one story that needs a decision
2. **Present options:** Show original vs alternative split
3. **Wait for decision:** Let user choose before moving on
4. **Record choice:** Track the decision
5. **Proceed to next:** Only after decision, show the next issue

**Format for each issue:**

```
## Decision 1 of N: [Story ID]

**Issue:** [Brief description of the problem]

| Option | Description |
|--------|-------------|
| A | [Original approach with noted issues] |
| B | [Alternative split approach] |
| C (Recommended) | [Another alternative if applicable] |

Which do you prefer? (A / B / C / other)
```

Note: Present 2-4 options depending on the issue. Mark one as recommended if it clearly stands out.

After all issues are resolved:

```
## All decisions complete

✓ [N] issues resolved
✓ [M] stories ready

Proceed to create specs? (yes / no)
```

User may:

- Choose an option (A, B, or provide alternative)
- Ask for clarification before deciding
- Request to revisit a previous decision

### Step 5: Create Specs

For each approved story, use the `/spec create` command:

1. For each story in order:
   - Invoke `/spec create {ID} "{title}" --feature-set "{feature-set}"`
   - Fill in the spec content (description, acceptance criteria, dependencies, PRD reference)
   - Validation runs automatically after creation
   - Handle any validation prompts interactively

2. Report created files and suggest running `/spec list` to verify.

**Note:** Using `/spec create` ensures all specs are validated immediately upon creation.

## Story Categories

- `functional` - Core user capability (CRUD, workflow)
- `quality` - Performance, reliability, polish
- `context` - Platform, form factor, environment
- `technical` - Spike, infrastructure (should be rare/embedded)

## Example Transformation

**Before (Technical):**

```
M2: Expense Display
- D2.1: Expense data layer
- D2.2: Group overview screen
- D2.3: Expense detail screen
- D2.4: Split calculation engine
```

**After (User Value):**

```
Feature Set: ED (Expense Display)

ED-01: View Group Expenses
- Description: User views group expenses and sees who owes what
- Acceptance criteria:
  - Group shows all expenses with date, description, amount
  - Balance summary shows net amounts owed between members
  - Expense detail shows payer and split breakdown
  - Split amounts are accurate to the cent
```

## Proposing Alternatives

When a story is too complex, propose multiple viable approaches:

**Example:**

```
## Decision 1 of 3: BT-01

**Original:** Full budget management with categories, alerts, and reports

**Issue:** Too large, combines multiple user goals

| Option | Description |
|--------|-------------|
| A | Keep as-is (large story, may take multiple sprints) |
| B | Split by feature: set budget → view budget → categories → alerts |
| C (Recommended) | Split by journey: basic budget (set + view) → enhancements (categories, alerts) |
| D | Defer budgets entirely, focus on core expense tracking first |

Which do you prefer? (A / B / C / D / other)
```

**Guidelines for options:**

- Always include "keep as-is" as Option A
- Provide 2-4 alternatives based on different split axes
- Mark recommended option if one clearly stands out
- Each alternative must pass the usability test independently
- "other" allows user to propose their own approach

## Incremental Feature Strategy

When reviewing a story, identify features that could be added incrementally:

**Story:** User views transaction details

**Incremental additions:**

- **v1:** Basic info (amount, date, description)
- **v2:** Add category display
- **v3:** Add receipt attachment
- **v4:** Add recurring transaction detection

This approach prevents scope creep while documenting the roadmap.

## Output Format

### After Step 2 (Validation)

First, show a brief summary:

```
## Split Analysis

**Feature Sets Identified:**
- TM (Transaction Management): 3 stories
- BT (Budget Tracking): 4 stories

**Validation Results:**
- 5 stories passed validation
- 2 stories need decisions

Starting validation decisions...
```

Then present **one issue at a time**:

```
## Decision 1 of 2: BT-03

**Original:** Full budget management with categories, alerts, and reports

**Issue:** Too large, combines multiple user goals

| Option | Description |
|--------|-------------|
| A | Keep as single story (has noted issues) |
| B | Split by feature: BT-03 (set budget), BT-04 (categories), BT-05 (alerts) |
| C (Recommended) | Split by journey: BT-03 (set & view budget), BT-04 (add categories later) |

Which do you prefer? (A / B / C / other)
```

Wait for user response. After they decide, show next issue:

```
## Decision 2 of 2: BT-06

**Original:** Export reports in all formats

**Issue:** Gold plating - too many formats for MVP

| Option | Description |
|--------|-------------|
| A | Keep all export formats |
| B (Recommended) | Start with CSV export only, add others later |
| C | Defer entirely - no export in MVP |

Which do you prefer? (A / B / C / other)
```

After all decisions are made:

```
## All decisions complete

✓ 2 issues resolved
✓ 7 stories ready for spec creation

| ID | Title | Status |
|----|-------|--------|
| TM-01 | Add Transaction | Ready |
| TM-02 | View Transactions | Ready |
| BT-01 | Set Budget | Ready |
| ... | ... | ... |

Proceed to create specs? (yes / no)
```

### After Step 5 (Spec Creation)

```
## Created Specs

- specs/TM-01-add-transaction.md
- specs/TM-02-view-transactions.md
- specs/BT-01-set-budget.md
...

Run `/spec list` to see all specs with status.
Run `/spec features TM` to see Transaction Management stories.
```

## Additional Resources

- [techniques.md](techniques.md) - Complete splitting techniques catalog
- [anti-patterns.md](anti-patterns.md) - Anti-pattern detection guide
- [../../templates/spec.md](../../templates/spec.md) - Spec file template
