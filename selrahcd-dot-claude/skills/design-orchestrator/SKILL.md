---
name: design-orchestrator
shortcut: design
description: "Coordinates the full design process: strategy, brand, then UI/UX. Use when starting a complete design engagement from scratch. Manages handoffs and checkpoints between phases."
---

# Design Process Orchestrator

Coordinate a complete design engagement through three phases: Strategy → Brand → UI/UX.

## Flow

### 1. Intake

Ask: "What's the project name and a brief description?"

Ask: "Do you have any existing materials? (website, docs, brand assets)"

Confirm: "Ready to start with the Strategy phase?"

### 2. Strategy Phase

Use the **design-strategy** skill to conduct research and positioning.

**Produces:** `docs/design/strategy-brief.md`

After completion, summarize:
> "Strategy complete. Key insights: [2-3 bullet summary]"
>
> "Ready to move to Brand Identity phase?"

Wait for confirmation before proceeding.

### 3. Brand Phase

Use the **design-brand** skill to create the brand identity system.

**Reads:** `docs/design/strategy-brief.md`
**Produces:** `docs/design/brand-identity.md`

After completion, summarize:
> "Brand identity complete. Summary: [2-3 bullet summary]"
>
> "Ready to move to UI/UX phase?"

Wait for confirmation before proceeding.

### 4. UI/UX Phase

Use the **design-uiux** skill to create the interface design system.

**Reads:** `docs/design/strategy-brief.md`, `docs/design/brand-identity.md`
**Produces:** `docs/design/uiux-system.md`

After completion, summarize:
> "UI/UX system complete. Summary: [2-3 bullet summary]"

### 5. Completion

Commit all documents:
```
docs(design): complete design system for [project name]

- Strategy brief: positioning, user insights, design principles
- Brand identity: visual language, voice, guidelines
- UI/UX system: components, patterns, accessibility
```

Final message:
> "Design system complete. Three documents created:
> - `docs/design/strategy-brief.md`
> - `docs/design/brand-identity.md`
> - `docs/design/uiux-system.md`
>
> Ready for implementation. A separate skill can help translate these into code."

## Partial Entry

Check for existing documents:

- If `docs/design/strategy-brief.md` exists:
  > "Found existing strategy brief. Skip to Brand phase, or review strategy first?"

- If both strategy and brand docs exist:
  > "Found existing strategy and brand docs. Skip to UI/UX phase, or review earlier phases?"

Always confirm before skipping.

## Checkpoint Behavior

At each checkpoint, user can:
- **Proceed** - Continue to next phase
- **Questions** - Ask about current phase outputs
- **Adjust** - Request changes before moving on
- **Stop** - Pause and resume later (documents are saved)

## Important

- Each skill handles its own guided discovery
- Orchestrator only manages flow and checkpoints
- All domain expertise lives in the individual skills
- Commit documents after each phase (not just at the end)
