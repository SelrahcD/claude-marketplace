# Challenge Skill Design

**Date:** 2026-01-25
**Status:** Approved for implementation

## Overview

A paranoid devil's advocate skill that tears apart plans, designs, and decisions by finding everything that can go wrong. Uses multiple critical perspectives to stress-test any artifact.

## Invocation

- **Explicit:** `/challenge` or `/challenge <file-or-reference>`
- **By other skills:** Can be invoked as a sub-step by coordinator skills

```
/challenge              # challenges whatever is in context
/challenge docs/plan.md # challenges a specific file
/challenge "the migration plan we just discussed"
```

## File Structure

```
skills/challenge/
├── SKILL.md                    # Lean orchestrator
├── critics/
│   ├── universal.md            # 10 always-on critics
│   └── specialized/
│       ├── architecture.md     # 6 critics
│       ├── migration.md        # 6 critics
│       ├── budget.md           # 6 critics
│       ├── travel.md           # 6 critics
│       ├── communication.md    # 6 critics
│       ├── project.md          # 6 critics
│       ├── hiring.md           # 6 critics
│       ├── product.md          # 6 critics
│       ├── legal.md            # 6 critics
│       ├── events.md           # 6 critics
│       ├── career.md           # 6 critics
│       └── purchases.md        # 6 critics
```

## Universal Critics (Always Run)

These 10 critics challenge any artifact regardless of type:

1. **Murphy's Law Pessimist** - What will go wrong
2. **Edge Case Hunter** - Boundaries and rare scenarios
3. **Second-Order Thinker** - Cascading consequences
4. **Assumptions Auditor** - Hidden assumptions
5. **Rollback Skeptic** - Reversibility and escape hatches
6. **Scale Skeptic** - What breaks at 10x/100x/1000x
7. **Cost Skeptic** - Budget, resources, hidden costs
8. **Timeline Skeptic** - Schedule risks, "this always takes longer"
9. **People Skeptic** - Team dynamics, change resistance, skill gaps
10. **Historian** - "We've seen this fail before when..."

## Specialized Critics by Category

### Architecture/Technical Design
- **Security Paranoid** - Attack vectors, data exposure, auth bypasses
- **Integration Pessimist** - "What about system X?" - forgotten integrations
- **Dependency Doomsayer** - External libs/services that could break or disappear
- **Tech Debt Prophet** - "You'll regret this in 2 years"
- **Ops Nightmare** - Deployment pain, monitoring gaps, debugging hell
- **Backwards Compatibility Breaker** - What existing stuff will this break?

### Migration/Change
- **Data Loss Worrier** - Corruption, truncation, encoding issues
- **Downtime Calculator** - Realistic outage expectations
- **Rollback Realist** - "Your rollback plan won't work because..."
- **Parallel Run Skeptic** - Drift, inconsistency, which is source of truth?
- **Communication Gap Finder** - Who wasn't informed?
- **Timing Terrorist** - Why this is the worst possible moment to migrate

### Budget/Financial
- **Hidden Cost Hunter** - What's not in the budget
- **Optimism Deflator** - "Your estimates are 50% too low"
- **Opportunity Cost Calculator** - What else could this money do?
- **Cash Flow Pessimist** - Timing mismatches, runway issues
- **Scope Creep Accountant** - Budget for inevitable additions
- **Vendor Lock-in Accountant** - Future costs of today's choices

### Holiday/Travel
- **Weather Pessimist** - Seasonal risks, storms, "rainy season starts then"
- **Logistics Cynic** - Delays, cancellations, 45-minute layovers
- **Local Knowledge Gap** - Cultural missteps, scams, unsafe areas
- **Health Worrier** - Illness abroad, medical access, vaccine requirements
- **Backup Plan Demander** - What if the airline cancels?
- **Budget Blowout Predictor** - Hidden fees, exchange rates, "tourist prices"

### Communication/Presentation
- **Misinterpretation Finder** - How will this be misread?
- **Audience Skeptic** - Will they care? Understand? Act?
- **Missing Context Critic** - What backstory are you assuming?
- **Tone Deaf Detector** - How could this land badly?
- **Counterargument Anticipator** - What will opponents say?
- **Timing Critic** - Is this the right moment for this message?

### Project/Planning
- **Dependency Chain Analyst** - What blocks what?
- **Resource Collision Finder** - Who's double-booked?
- **Stakeholder Surprise Predictor** - Who will object unexpectedly?
- **Scope Creep Prophet** - What will inevitably be added?
- **Critical Path Cynic** - Where's the real bottleneck?
- **Success Criteria Skeptic** - How will you know it worked?

### Hiring/Team
- **Culture Fit Skeptic** - Will they mesh with the team?
- **Skill Gap Identifier** - What's missing from the job description?
- **Retention Risk Assessor** - Why might they leave in 6 months?
- **Onboarding Realist** - How long until actually productive?
- **Team Dynamic Disruptor** - How does this change existing dynamics?
- **Hiring Bias Detector** - Are you cloning yourself?

### Product/Feature
- **User Confusion Predictor** - Where will users get lost?
- **Adoption Barrier Finder** - Why won't people use this?
- **Competitor Response Anticipator** - How will competitors react?
- **Support Burden Calculator** - What tickets will this generate?
- **Feature Creep Guardian** - Is this solving the core problem?
- **MVP Skeptic** - Is this actually minimal?

### Legal/Compliance
- **Regulatory Radar** - What rules apply that you forgot?
- **Liability Lister** - What could you be sued for?
- **Contract Loophole Finder** - What's not covered?
- **Privacy Paranoid** - Data protection, GDPR, consent issues
- **Audit Trail Demander** - Can you prove compliance?
- **Jurisdiction Jumper** - What about other countries/states?

### Event Planning
- **Attendance Pessimist** - What if half don't show? Or double show?
- **Venue Problem Finder** - Accessibility, capacity, parking, noise
- **Timing Conflict Identifier** - Competing events, bad dates, holidays
- **Catering Catastrophist** - Dietary needs, allergies, supply issues
- **Tech Failure Anticipator** - AV, wifi, power, microphones
- **Weather Contingency Demander** - What if it rains on your outdoor event?

### Career Decisions
- **Grass Is Greener Skeptic** - Is the new thing actually better?
- **Bridge Burning Assessor** - What relationships are you risking?
- **Skill Transferability Critic** - Will your experience translate?
- **Financial Reality Checker** - Can you actually afford this transition?
- **Identity Crisis Predictor** - How will this change affect you personally?
- **Reversion Risk Assessor** - Can you go back if it doesn't work?

### Major Purchases
- **Total Cost of Ownership** - Maintenance, insurance, taxes, repairs
- **Depreciation Doomsayer** - How fast does this lose value?
- **Lifestyle Fit Skeptic** - Does this actually match how you live?
- **Alternative Investigator** - What else could this money do?
- **Resale Reality Checker** - Can you get out if needed?
- **Impulse Purchase Detector** - Are you buying emotionally?

## Artifact Type Detection

The skill analyzes the artifact and matches against keywords:

| Keywords/Patterns | Category |
|-------------------|----------|
| architecture, design, system, API, database, schema, infrastructure | architecture |
| migration, migrate, upgrade, transition, cutover, rollout | migration |
| budget, cost, pricing, investment, spend, financial | budget |
| travel, trip, holiday, vacation, flight, hotel, itinerary | travel |
| presentation, announcement, email, message, communication | communication |
| project, plan, roadmap, timeline, milestones, deliverables | project |
| hiring, recruit, candidate, team, role, job, position | hiring |
| feature, product, MVP, launch, users, UX | product |
| legal, contract, compliance, regulation, policy, GDPR | legal |
| event, conference, party, wedding, meetup, workshop | events |
| career, job change, resignation, promotion, pivot | career |
| purchase, buy, house, car, investment, equipment | purchases |

- If no category matches: Only universal critics run
- If multiple match: All matching specialized critics load

## Execution Model

### Parallel Subagent Execution

Critics run as subagents using the Task tool:
- **Model:** sonnet (good analytical depth)
- **Concurrency:** Max 5 subagents at a time
- **Tools:** Read, Glob, Grep (read-only, to examine referenced files)
- **Output:** Structured JSON for easy consolidation

### Batching Example

For an architecture review (10 universal + 6 specialized = 16 critics):
1. Batch 1: 5 universal critics (parallel)
2. Batch 2: 5 universal critics (parallel)
3. Batch 3: 5 specialized critics (parallel)
4. Batch 4: 1 specialized critic
5. Consolidate all results

### Subagent Prompt Template

```
You are the [Critic Name]. Your obsession is [focus area].
Examine this artifact looking ONLY for [what this critic cares about].
Be paranoid. Assume the worst. Find what will fail.

For each issue found, provide:
- What could go wrong (concrete scenario)
- How bad (critical/high/medium/warning)
- Early warning signs (tripwires)
- How to avoid (plan changes)
- How to survive (mitigations)

Return JSON: { issues: [{ title, severity, scenario, tripwires, plan_changes, mitigations }] }
```

## Consolidation Logic

After all critics report:

1. **Group similar issues** - Multiple critics often find the same core problem from different angles. Merge them, noting which critics raised it.

2. **Take highest severity** - If different critics rate the same issue differently, use the highest.

3. **Merge recommendations** - Combine tripwires, plan changes, and mitigations from all critics for richer output.

4. **Determine verdict:**
   - Any unmitigatable critical → **KILL**
   - Criticals with clear mitigations or multiple highs → **PROCEED WITH CHANGES**
   - Only medium/warnings → **ACCEPTABLE RISK**

## Output Format

```markdown
# Challenge Report: [Artifact Name]

## Verdict: [KILL | PROCEED WITH CHANGES | ACCEPTABLE RISK]

One-sentence summary of overall assessment.

---

## Critical Issues (Stop and Rethink)

### 1. [Issue Title]
**Raised by:** Murphy's Law Pessimist, Rollback Skeptic
**What could happen:** [Concrete failure scenario]
**Tripwires:** [Early warning signs to watch for]
**Plan changes:** [How to avoid this entirely]
**Mitigations:** [How to reduce impact if it happens]

---

## High Priority Issues (Must Address Before Proceeding)

### 2. [Issue Title]
[Same structure as above]

---

## Medium Priority Issues (Should Address)

### 3. [Issue Title]
[Same structure as above]

---

## Warnings (Be Aware)

- [Brief warning with source critic]
- [Brief warning with source critic]

---

## What Looks Solid

[Brief acknowledgment of parts that survived scrutiny - keeps it balanced]
```

## Severity Definitions

- **Critical:** Could cause total failure, data loss, significant harm, or unrecoverable state
- **High:** Likely to cause significant problems, delays, or costs if not addressed
- **Medium:** Will cause friction or minor failures, but recoverable
- **Warning:** Worth knowing, but low probability or low impact

## Critical Rules for the Skill

- **BE PARANOID** - Assume everything will fail. Your job is not to be balanced.
- **NO SOFTENING** - Don't hedge with "might" or "could possibly". State failures directly.
- **CONCRETE SCENARIOS** - Vague concerns are useless. Describe exactly what goes wrong.
- **ACTIONABLE OUTPUT** - Every issue needs tripwires, plan changes, and mitigations.
