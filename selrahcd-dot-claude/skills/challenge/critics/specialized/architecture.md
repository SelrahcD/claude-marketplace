# Architecture Critics

Use these critics when reviewing technical designs, system architecture, APIs, databases, or infrastructure plans.

## 1. Security Paranoid

**Obsession:** Attack vectors, data exposure, auth bypasses

**Focus:** Every system is a target. Find the security holes - injection points, exposed data, weak authentication, missing authorization, unencrypted channels.

**Questions to ask:**
- Where can attackers inject malicious input?
- What data is exposed that shouldn't be?
- How can authentication be bypassed?
- What happens if credentials leak?

---

## 2. Integration Pessimist

**Obsession:** "What about system X?"

**Focus:** No system exists in isolation. Find the forgotten integrations - the legacy system nobody mentioned, the third-party API, the batch job that runs at midnight.

**Questions to ask:**
- What existing systems does this need to talk to?
- Which integrations haven't been mentioned?
- What APIs will break when this changes?
- Who else is reading/writing this data?

---

## 3. Dependency Doomsayer

**Obsession:** External dependencies that could break or disappear

**Focus:** Every external dependency is a risk. Libraries get abandoned, APIs get deprecated, services go down, vendors go bankrupt.

**Questions to ask:**
- What third-party dependencies are we taking on?
- What happens if this library is abandoned?
- What if this API is deprecated?
- Can we survive if this vendor disappears?

---

## 4. Tech Debt Prophet

**Obsession:** "You'll regret this in 2 years"

**Focus:** Today's shortcut is tomorrow's nightmare. Find the decisions that will haunt the team - the "temporary" hacks, the "we'll fix it later" patterns.

**Questions to ask:**
- What shortcuts will we regret?
- Where is complexity being hidden?
- What "temporary" solution will become permanent?
- How will this age in 2-5 years?

---

## 5. Ops Nightmare

**Obsession:** Deployment pain, monitoring gaps, debugging hell

**Focus:** Code that runs locally is different from code in production. Find the operational nightmares - deployment complexity, missing observability, impossible debugging.

**Questions to ask:**
- How do we deploy this safely?
- How do we know when it's broken?
- How do we debug production issues?
- What happens during a 3am incident?

---

## 6. Backwards Compatibility Breaker

**Obsession:** What existing stuff will this break

**Focus:** Changes don't happen in a vacuum. Find what breaks - existing clients, saved data, cached responses, bookmarked URLs, trained user habits.

**Questions to ask:**
- What existing clients will break?
- What about data that's already stored?
- What cached responses will become invalid?
- What user workflows will this disrupt?
