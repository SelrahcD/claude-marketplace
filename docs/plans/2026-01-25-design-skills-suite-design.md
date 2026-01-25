# Design Skills Suite

## Overview

A coordinated suite of design skills that guide users through strategic design thinking:
1. **design-strategy** - Research and positioning
2. **design-brand** - Brand identity system
3. **design-uiux** - Interface design system
4. **design-orchestrator** - Coordinates all three phases

## Architecture

### File Structure

```
skills/
├── design-strategy/
│   └── SKILL.md
├── design-brand/
│   └── SKILL.md
├── design-uiux/
│   └── SKILL.md
└── design-orchestrator/
    └── SKILL.md
```

### Document Flow

```
Strategy → docs/design/strategy-brief.md
    ↓
Brand → docs/design/brand-identity.md (reads strategy)
    ↓
UI/UX → docs/design/uiux-system.md (reads strategy + brand)
```

---

## Skill 1: design-strategy

### Purpose

Understand the business, users, competitors, and market to establish strategic foundations that inform all design decisions.

### Guided Discovery Questions

1. What's the business/project? (name, brief description)
2. What existing materials do you have? (website, docs, analytics - analyze if provided)
3. Who are your users? (demographics, behaviors, or "help me figure this out")
4. What jobs are users trying to accomplish?
5. Who are your main competitors? (or ask to research)
6. What makes you different from competitors?
7. What business goals should design support?
8. Any constraints? (budget, timeline, technical, regulatory)

### Research Capabilities

- Analyze competitor websites via WebFetch (visual patterns, messaging, positioning)
- Web search for market trends and user expectations
- Review existing materials user provides

### Deliverable: `docs/design/strategy-brief.md`

```markdown
# Design Strategy Brief: [Project Name]

## Business Context
[What they do, goals, constraints]

## User Understanding
- Primary personas
- Jobs-to-be-done
- Pain points and unmet needs

## Competitive Landscape
- Key competitors analyzed
- Visual positioning map
- Differentiation opportunities

## Strategic Positioning
- Where you fit in the market
- What makes you different
- Emotional territory to own

## Design Principles
[3-5 principles derived from research that guide all decisions]
```

---

## Skill 2: design-brand

### Purpose

Create a complete brand identity system building on strategic foundations.

### Inputs

- Reads `docs/design/strategy-brief.md` from previous phase
- References design principles, positioning, user understanding

### Guided Discovery Questions

1. Any existing brand elements to preserve or evolve? (logo, colors, fonts)
2. Brand personality - which archetypes resonate? (present 3-4 options based on strategy)
3. Voice tone - formal to casual spectrum? Technical to accessible?
4. Color direction - what emotions should colors evoke? Any industry considerations?
5. Typography direction - modern/classic? Geometric/humanist? Display needs?
6. Visual style - minimal/rich? Illustration/photography? Abstract/concrete?

### Research Capabilities

- Analyze competitor brand systems (colors, typography, voice)
- Research color psychology and industry conventions
- Find typography pairing recommendations

### Deliverable: `docs/design/brand-identity.md`

```markdown
# Brand Identity: [Project Name]

## Brand Positioning
[From strategy, refined]

## Brand Personality
- Archetype(s)
- Personality traits
- How we show up vs. competitors

## Visual Identity

### Color Palette
- Primary: [hex, rationale]
- Secondary: [hex, rationale]
- Neutrals: [scale]
- Semantic: [success, warning, error]
- Accessibility notes

### Typography System
- Headings: [font, weights, rationale]
- Body: [font, weights, rationale]
- Accent/Display: [if applicable]
- Pairing rationale

### Visual Style
- Imagery direction
- Iconography style
- Illustration approach (if applicable)
- Graphic elements

## Verbal Identity

### Voice & Tone
- Voice characteristics (consistent)
- Tone variations by context
- Example phrases

### Messaging Hierarchy
- Tagline/positioning statement
- Value propositions
- Key messages by audience

## Usage Guidelines
- Do's and don'ts
- Minimum sizes, clear space (conceptual)
- Color combinations to use/avoid
```

---

## Skill 3: design-uiux

### Purpose

Translate brand identity into interface design systems, user flows, and platform-specific guidance.

### Inputs

- Reads `docs/design/strategy-brief.md` (user understanding, goals)
- Reads `docs/design/brand-identity.md` (visual language, voice)

### Guided Discovery Questions

1. What platforms are you building for? (Web, iOS, Android, Desktop - can select multiple)
2. What's the primary user journey? (main task users accomplish)
3. What are secondary flows? (other key tasks)
4. Navigation complexity - how many sections/features?
5. Content density - data-heavy or minimal?
6. Interaction style - conventional/familiar or innovative/unique?
7. Accessibility requirements - WCAG level? (AA recommended, AAA for some)
8. Any existing design system or component library to integrate with?

### Research Capabilities

- Analyze competitor interfaces (patterns, flows, conventions)
- Reference platform guidelines (Apple HIG, Material Design)
- Research accessibility best practices

### Deliverable: `docs/design/uiux-system.md`

```markdown
# UI/UX Design System: [Project Name]

## Platform Strategy
- Primary platform(s)
- Platform-specific considerations
- Cross-platform consistency approach

## Information Architecture

### Navigation Structure
- Primary navigation pattern
- Secondary navigation
- Deep linking approach

### Content Hierarchy
- Page types and templates
- Content prioritization principles

## User Flows

### Primary Flow: [Main Task]
[Step-by-step with decision points]

### Secondary Flows
[Key alternative journeys]

## Design System Foundation

### Layout
- Grid system (columns, gutters, margins)
- Spacing scale
- Responsive breakpoints
- Container widths

### Components
- Navigation components
- Form elements (inputs, buttons, selectors)
- Content components (cards, lists, tables)
- Feedback components (alerts, toasts, modals)
- State patterns (loading, empty, error)

### Interaction Patterns
- Micro-interactions
- Transitions and animations
- Gesture support (mobile)
- Keyboard navigation

## Platform-Specific Guidance

### Web
[Responsive behavior, browser considerations]

### iOS (if applicable)
[HIG alignment, native patterns, safe areas]

### Android (if applicable)
[Material alignment, native patterns]

### Desktop (if applicable)
[Window management, keyboard shortcuts]

## Accessibility

### WCAG Compliance
- Target level and rationale
- Color contrast requirements
- Focus management
- Screen reader considerations

### Inclusive Design
- Motor accessibility
- Cognitive load management
- Error prevention and recovery
```

---

## Skill 4: design-orchestrator

### Purpose

Coordinate the three design skills in sequence, managing handoffs, documents, and user checkpoints.

### Invocation

`/design` or `/design-orchestrator`

### Flow

```
1. INTAKE
   - Ask: project name + brief description
   - Ask: any existing materials? (analyze if provided)
   - Confirm ready to begin

2. STRATEGY PHASE
   - Invoke design-strategy skill
   - Skill produces docs/design/strategy-brief.md
   - Orchestrator summarizes key findings
   - Checkpoint: "Strategy complete. Key insights: [summary]. Ready for Brand phase?"

3. BRAND PHASE
   - Invoke design-brand skill (reads strategy doc)
   - Skill produces docs/design/brand-identity.md
   - Orchestrator summarizes brand decisions
   - Checkpoint: "Brand complete. Identity summary: [summary]. Ready for UI/UX phase?"

4. UI/UX PHASE
   - Invoke design-uiux skill (reads both docs)
   - Skill produces docs/design/uiux-system.md
   - Orchestrator summarizes system decisions
   - Final checkpoint: "Design system complete."

5. COMPLETION
   - Summary of all three documents
   - Commit all docs to git
   - "Ready for implementation? A separate skill can help translate these into code."
```

### Checkpoint Behavior

At each checkpoint, user can:
- Proceed to next phase
- Ask questions about current phase
- Request adjustments before moving on
- Stop and resume later

### Partial Entry

- If `docs/design/strategy-brief.md` exists, offer to skip to Brand phase
- If both strategy and brand docs exist, offer to skip to UI/UX phase
- Always confirm before skipping

### Ultra-thin Orchestration

The orchestrator itself contains minimal logic—just the flow and checkpoints. All domain expertise lives in the individual skills.

---

## Shared Principles

### Guided Discovery Pattern

All skills follow:
- One question at a time
- Prefer multiple choice when possible
- Research before asking (don't ask what you can look up)
- Analyze existing materials when provided

### Research Protocol

- Use WebFetch to analyze competitor websites
- Use WebSearch for market trends, best practices
- Read user-provided documents/URLs

### Document Format

- Markdown with clear sections
- Actionable recommendations (not vague guidance)
- Rationale for each decision
- Cross-references between documents

### Tone

- Expert but collaborative
- Explains reasoning, not just conclusions
- Acknowledges trade-offs
- Respects user's domain knowledge

### Context Awareness

- B2B vs B2C implications
- Industry conventions (fintech needs trust, healthcare needs compliance, etc.)
- Startup vs enterprise considerations
- Budget/resource constraints

---

## Implementation Notes

- Each skill is self-contained with full instructions
- Orchestrator uses Skill tool to invoke each phase
- Documents are committed to git after each phase
- Skills can be used standalone or through orchestrator
