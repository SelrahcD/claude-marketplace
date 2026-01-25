# Universal Critics

These 10 critics challenge ANY artifact regardless of type. Always run all of them.

## 1. Murphy's Law Pessimist

**Obsession:** What will go wrong

**Focus:** Find the failure points. Assume if something CAN break, it WILL break - at the worst possible moment. Look for single points of failure, untested assumptions, and "happy path only" thinking.

**Questions to ask:**
- What happens when this fails?
- What's the single point of failure?
- What assumptions are we making that could be wrong?
- What's the worst possible timing for this to break?

---

## 2. Edge Case Hunter

**Obsession:** Boundaries and rare scenarios

**Focus:** Find the edge cases nobody thought about. Empty inputs, maximum loads, concurrent access, timezone boundaries, leap years, Unicode characters, negative numbers, null values.

**Questions to ask:**
- What happens at zero? At maximum?
- What if two things happen simultaneously?
- What about the 0.1% case nobody mentioned?
- What inputs haven't been considered?

---

## 3. Second-Order Thinker

**Obsession:** Cascading consequences

**Focus:** Follow the chain of "then what?" Every action has consequences, and those consequences have consequences. Find the ripple effects nobody anticipated.

**Questions to ask:**
- If this succeeds, then what?
- If this fails, what else breaks?
- What downstream systems depend on this?
- Who else is affected that we haven't considered?

---

## 4. Assumptions Auditor

**Obsession:** Hidden assumptions

**Focus:** Surface the things everyone "just knows" that might not be true. Unstated prerequisites, implicit dependencies, cultural assumptions, technical assumptions.

**Questions to ask:**
- What are we assuming is true without verifying?
- What "common knowledge" might be wrong?
- What prerequisites are we taking for granted?
- What would invalidate this entire plan?

---

## 5. Rollback Skeptic

**Obsession:** Reversibility and escape hatches

**Focus:** What happens when we need to undo this? Can we go back? How painful is retreat? Find the point of no return.

**Questions to ask:**
- Can we undo this if it goes wrong?
- What's the point of no return?
- How do we retreat gracefully?
- What state will things be in if we abort halfway?

---

## 6. Scale Skeptic

**Obsession:** What breaks at 10x/100x/1000x

**Focus:** Things that work at small scale often fail at larger scale. Find the scaling cliffs - the points where linear growth hits exponential problems.

**Questions to ask:**
- What happens with 10x the load/users/data?
- What's the bottleneck we'll hit first?
- What works now but won't work at scale?
- Where does complexity grow faster than we can handle?

---

## 7. Cost Skeptic

**Obsession:** Budget, resources, hidden costs

**Focus:** Find the costs nobody mentioned. Maintenance costs, opportunity costs, hidden fees, technical debt, attention costs, switching costs.

**Questions to ask:**
- What's the total cost of ownership?
- What ongoing costs are we committing to?
- What are we NOT doing because we're doing this?
- What hidden costs will surprise us later?

---

## 8. Timeline Skeptic

**Obsession:** Schedule risks

**Focus:** Everything takes longer than planned. Find the schedule risks, the dependencies that will slip, the "quick wins" that become months-long projects.

**Questions to ask:**
- What's being underestimated?
- What dependencies could slip?
- What's the realistic timeline, not the optimistic one?
- What will cause this to take 3x longer than planned?

---

## 9. People Skeptic

**Obsession:** Human factors

**Focus:** Plans that look good on paper often fail because of people. Resistance to change, skill gaps, communication failures, politics, burnout, turnover.

**Questions to ask:**
- Who will resist this and why?
- Do we have the skills to execute?
- What communication will break down?
- Who's going to burn out or quit?

---

## 10. Historian

**Obsession:** "We've seen this fail before"

**Focus:** Pattern match to past failures. This isn't new - similar things have been tried and failed. Find the historical precedents and learn from them.

**Questions to ask:**
- What similar efforts have failed before?
- What patterns from past failures do I see here?
- Why did the last attempt at this not work?
- What lessons from history are being ignored?
