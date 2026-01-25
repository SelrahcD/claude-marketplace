# Spec Validation Rules

Apply these rules to validate each spec. A spec must pass ALL checks.

## Entry Point Rules

### Rule 1: Owns Entry Point

**Question:** Does this story ADD its own way to access its functionality?

**Pass:** Story includes the button/link/navigation that users use to reach it.

**Fail:** Story assumes UI from another story exists.

### Rule 2: No Forward Entry Points

**Question:** Does this story add UI (button/link) that leads to ANOTHER story's functionality?

**Pass:** All navigation added by this story leads to destinations within this story.

**Fail:** Story has acceptance criteria like "Tapping X transitions to [other story's screen]".

**Example Violation:**

```
EG-01: "Tapping group navigates to expense list"  ← VIOLATION
EG-02: Expense list view (assumes tap handler exists)
```

EG-01 adds navigation for EG-02's functionality. The tap handler belongs in EG-02.

### Rule 3: Self-Contained Navigation

**Question:** If story adds navigation, does the destination exist within THIS story?

**Pass:** Navigation leads to screens/states defined in the same story.

**Fail:** Navigation leads to screens defined in dependent stories.

**Key Principle:** If Story B needs a button on Screen A to access it, then Story B adds that button—not Story A.

---

## Usability Rules

### Rule 4: Completes a Task

**Question:** Can user complete a real task with ONLY this story implemented?

**Pass:** User achieves a meaningful goal end-to-end.

**Fail:** Partial workflow that requires other stories to be useful.

### Rule 5: Standalone Value

**Question:** Is this story useful if no dependent stories are ever built?

**Pass:** User gets value even if development stops after this story.

**Fail:** Story only "sets up" for future stories.

### Rule 6: No Dead Ends

**Question:** Does every UI element in this story have a working destination?

**Pass:** All buttons, links, and interactive elements lead somewhere functional.

**Fail:** UI elements that lead nowhere, show "coming soon", or require other stories.

---

## INVEST Rules

### Rule 7: Independent

**Question:** Can this story deliver value without waiting for other stories?

**Pass:** Story can be built and released on its own.

**Fail:** Long dependency chains, blocked until other work completes.

### Rule 8: Negotiable

**Question:** Can scope flex without breaking the story's value?

**Pass:** Some acceptance criteria could be deferred without losing core value.

**Fail:** All-or-nothing requirements, no room to negotiate scope.

### Rule 9: Valuable

**Question:** Does user get something they can actually use?

**Pass:** Clear user benefit, enables a real task.

**Fail:** Technical output only, no user-facing value.

### Rule 10: Estimable

**Question:** Can the team reasonably size this work?

**Pass:** Clear enough to estimate effort.

**Fail:** Too vague, too many unknowns, needs spike first.

### Rule 11: Small

**Question:** Does this fit in a single sprint?

**Pass:** Bounded scope, focused on one thing.

**Fail:** Too many acceptance criteria, multiple user goals combined.

### Rule 12: Testable

**Question:** Can we verify it works end-to-end?

**Pass:** Specific, observable acceptance criteria.

**Fail:** Vague criteria like "works well" or "is fast".

---

## Anti-Pattern Rules

### Rule 13: Not a Fragment

**Question:** Is this more than a partial piece of functionality?

**Pass:** Complete workflow from start to finish.

**Fail:** "User views X" but can't navigate to X or do anything with it.

**Keywords indicating fragments:** "displays", "shows" (without action)

### Rule 14: Not Horizontal

**Question:** Does story touch all technical layers needed for the user outcome?

**Pass:** Vertical slice through UI, logic, and data as needed.

**Fail:** Single layer only (e.g., "backend API", "data layer", "UI components").

**Keywords indicating horizontal slice:** backend, frontend, API, database, data layer, infrastructure, schema, migration, component library

### Rule 15: Not Infrastructure

**Question:** Does this deliver direct user value?

**Pass:** User can do something after this story.

**Fail:** Setup, configuration, or tooling with no user outcome.

**Keywords indicating infrastructure:** setup, initialize, configure, bootstrap, scaffold

### Rule 16: Not an Iceberg

**Question:** Is the technical complexity proportional to visible scope?

**Pass:** Acceptance criteria reflect actual implementation effort.

**Fail:** Simple-sounding UI that requires complex algorithms, offline sync, multi-platform edge cases, etc.

**Detection:** Count acceptance criteria vs. likely implementation tasks. Large gap = iceberg.

### Rule 17: Not Gold-Plated

**Question:** Is this the minimum viable version?

**Pass:** Simplest version that delivers value.

**Fail:** Includes polish, comprehensive coverage, or "nice to have" features.

**Keywords indicating gold plating:** beautiful, polished, complete, full, all, every, comprehensive, perfect

### Rule 18: Not a Disguised Spike

**Question:** Does this deliver working functionality, not just research?

**Pass:** User can use something after this story.

**Fail:** Output is documentation, recommendations, or "findings".

**Keywords indicating spike:** investigate, research, evaluate, explore, assess, analyze, spike

---

## Validation Output Format

For each spec, produce this output:

```
## [SPEC-ID]: [Title]

### Entry Points
- [ ] Owns entry point: [PASS/FAIL] - [evidence]
- [ ] No forward entry points: [PASS/FAIL] - [evidence]
- [ ] Self-contained navigation: [PASS/FAIL] - [evidence]

### Usability
- [ ] Completes a task: [PASS/FAIL] - [evidence]
- [ ] Standalone value: [PASS/FAIL] - [evidence]
- [ ] No dead ends: [PASS/FAIL] - [evidence]

### INVEST
- [ ] Independent: [PASS/FAIL] - [evidence]
- [ ] Small: [PASS/FAIL] - [evidence]
- [ ] Testable: [PASS/FAIL] - [evidence]

### Anti-Patterns
- [ ] Not a fragment: [PASS/FAIL] - [evidence]
- [ ] Not horizontal: [PASS/FAIL] - [evidence]
- [ ] Not infrastructure: [PASS/FAIL] - [evidence]
- [ ] Not an iceberg: [PASS/FAIL] - [evidence]
- [ ] Not gold-plated: [PASS/FAIL] - [evidence]

### Result
**Status:** [PASS / FAIL]
**Issues:** [List any failed checks with brief explanation]
**Recommendation:** [If FAIL, suggest fix]
```
