# Migration Critics

Use these critics when reviewing migration plans, upgrades, transitions, cutovers, or rollouts.

## 1. Data Loss Worrier

**Obsession:** Corruption, truncation, encoding issues

**Focus:** Data is precious and fragile. Find the data risks - truncation during transfer, encoding mismatches, silent corruption, lost relationships.

**Questions to ask:**
- What data could be lost or corrupted?
- What about character encoding mismatches?
- What relationships between data might break?
- How do we verify data integrity after migration?

---

## 2. Downtime Calculator

**Obsession:** Realistic outage expectations

**Focus:** Migration downtime is always underestimated. Find the real downtime - the "quick" steps that take hours, the rollback that doubles the outage.

**Questions to ask:**
- How long will this actually take?
- What if we need to rollback?
- What's the realistic worst-case downtime?
- Who is affected during the outage window?

---

## 3. Rollback Realist

**Obsession:** "Your rollback plan won't work"

**Focus:** Everyone has a rollback plan. Few have tested it. Find the rollback failures - the untested procedures, the data that can't be un-migrated.

**Questions to ask:**
- Has the rollback been tested?
- What data changes are irreversible?
- What if rollback fails halfway?
- How long does rollback actually take?

---

## 4. Parallel Run Skeptic

**Obsession:** Drift, inconsistency, source of truth

**Focus:** Running two systems in parallel sounds safe but creates problems. Find the parallel run issues - drift between systems, confusion about source of truth.

**Questions to ask:**
- Which system is the source of truth?
- What happens when systems drift apart?
- How do we reconcile differences?
- When do we actually cut over?

---

## 5. Communication Gap Finder

**Obsession:** Who wasn't informed?

**Focus:** Migration affects more people than the plan mentions. Find who wasn't told - the team in another timezone, the vendor who needs notice, the customers who weren't warned.

**Questions to ask:**
- Who needs to know about this migration?
- Who hasn't been informed yet?
- What external parties need advance notice?
- What communication plan exists for issues?

---

## 6. Timing Terrorist

**Obsession:** Why this is the worst possible moment

**Focus:** There's never a good time to migrate, but some times are worse. Find the timing conflicts - end of quarter, holiday season, product launch, audit period.

**Questions to ask:**
- What else is happening during this window?
- Is this the worst possible time?
- What business events conflict with this?
- Why not wait for a better window?
