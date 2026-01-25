# UI/UX Design System: [Project Name]

## Foundation

### Context
[Reference strategy and brand - user needs, brand personality, design principles]

### Platform Strategy

| Platform | Priority | Approach |
|----------|----------|----------|
| [Web/iOS/Android/Desktop] | Primary | [Native / PWA / Responsive] |
| [Platform 2] | Secondary | [Approach] |

**Cross-Platform Consistency:**
[How to maintain brand consistency while respecting platform conventions]

---

## Information Architecture

### Navigation Structure

**Primary Navigation:**
- [Section 1] - [Purpose]
- [Section 2] - [Purpose]
- [Section 3] - [Purpose]

**Secondary Navigation:**
- [Subsection patterns]

**Utility Navigation:**
- [Search, settings, profile, etc.]

**Navigation Pattern:**
- Web: [Header nav / Sidebar / etc.]
- Mobile: [Tab bar / Bottom nav / Drawer]

### Content Hierarchy

| Page Type | Purpose | Key Components |
|-----------|---------|----------------|
| [Landing] | [Purpose] | [Hero, features, CTA] |
| [Dashboard] | [Purpose] | [Stats, lists, actions] |
| [Detail] | [Purpose] | [Content, metadata, actions] |
| [Form] | [Purpose] | [Fields, validation, submit] |

---

## User Flows

### Primary Flow: [Main Task Name]

```
[Entry Point]
    │
    ▼
[Step 1: Description]
    │
    ├─── [Decision Point] ───┐
    │                        │
    ▼                        ▼
[Step 2a]               [Step 2b]
    │                        │
    └────────────┬───────────┘
                 │
                 ▼
[Completion / Success State]
```

**Key Interactions:**
- [Step]: [Interaction detail]
- [Step]: [Interaction detail]

**Error Handling:**
- [Error scenario]: [Recovery path]

### Secondary Flow: [Task Name]

[Similar flow diagram]

### Edge Cases

| Scenario | Handling |
|----------|----------|
| [Empty state] | [What to show, actions available] |
| [Error state] | [Error message, recovery options] |
| [Loading] | [Skeleton, spinner, progressive] |
| [Offline] | [Cached content, sync indication] |

---

## Design System Foundation

### Layout Grid

**Web (Desktop):**
- Columns: 12
- Gutter: 24px
- Margin: 48px (large) / 24px (medium)
- Max content width: 1200px

**Web (Tablet):**
- Columns: 8
- Gutter: 20px
- Margin: 24px

**Web (Mobile):**
- Columns: 4
- Gutter: 16px
- Margin: 16px

### Spacing Scale

Based on 4px base unit:

| Token | Value | Usage |
|-------|-------|-------|
| space-1 | 4px | Tight spacing, inline elements |
| space-2 | 8px | Related elements, compact lists |
| space-3 | 12px | Default padding |
| space-4 | 16px | Component padding, list gaps |
| space-6 | 24px | Section padding |
| space-8 | 32px | Large section gaps |
| space-12 | 48px | Page sections |
| space-16 | 64px | Major page divisions |

### Responsive Breakpoints

| Name | Min Width | Target |
|------|-----------|--------|
| mobile | 0 | Phones |
| tablet | 768px | Tablets, small laptops |
| desktop | 1024px | Laptops, desktops |
| wide | 1440px | Large monitors |

### Container Strategy

```css
/* Centered content container */
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 var(--space-4);
}

/* Full-bleed sections */
.full-width {
  width: 100%;
}
```

---

## Components

### Navigation

**Header (Web):**
- Height: 64px (desktop), 56px (mobile)
- Position: Fixed top
- Contents: Logo, nav links, utility actions
- Mobile: Hamburger menu

**Tab Bar (Mobile):**
- Height: 56px (iOS), 56-80px (Android with labels)
- Max items: 5
- Active indicator: [Color/style from brand]

### Form Elements

**Text Input:**
- Height: 44px (touch-friendly)
- Border radius: [From brand]
- States: Default, focus, error, disabled
- Label position: Above field

**Buttons:**

| Type | Usage | Style |
|------|-------|-------|
| Primary | Main CTAs | [Brand primary color], filled |
| Secondary | Alternative actions | Outlined or tinted |
| Tertiary | Low-emphasis | Text only |
| Destructive | Delete, remove | Red/error color |

- Min height: 44px
- Min width: 120px (or content + padding)
- Border radius: [From brand]

**Selectors:**
- Checkbox: [Style]
- Radio: [Style]
- Toggle/Switch: [Style]
- Dropdown: [Style]

### Content Components

**Cards:**
- Padding: space-4 to space-6
- Border radius: [From brand]
- Shadow: [If applicable]
- Hover state: [If interactive]

**Lists:**
- Item height: 48-72px depending on content
- Dividers: [1px gray-200 / none]
- Spacing between items: [space-2 / none]

**Tables:**
- Header: [Bold, background color]
- Row height: 48px minimum
- Alternating rows: [Yes/No]
- Responsive: [Scroll horizontal / Stack vertical]

### Feedback Components

**Alerts/Banners:**
- Types: Success, warning, error, info
- Placement: Top of content area
- Dismissible: [Yes/No]

**Toasts:**
- Duration: 4-6 seconds
- Position: Bottom center (mobile), bottom right (desktop)
- Max width: 400px

**Modals/Dialogs:**
- Overlay: Semi-transparent black (50-60%)
- Width: 400-600px (desktop), full-width minus margins (mobile)
- Animation: Fade + scale up

### State Patterns

**Loading:**
- Skeleton screens for content
- Spinner for actions
- Progress bar for long operations

**Empty:**
- Illustration (optional, match brand)
- Explanatory text
- Primary action to populate

**Error:**
- Clear error message
- Recovery action
- Consistent with error color

---

## Interaction Patterns

### Micro-interactions

| Action | Feedback |
|--------|----------|
| Button press | Subtle scale (0.98) + opacity change |
| Form submission | Button loading state → success/error |
| Toggle | Smooth transition (150-200ms) |
| Hover (desktop) | Color/shadow change |

### Transitions

- Duration: 150-300ms for UI, 300-500ms for page
- Easing: ease-out for entrances, ease-in for exits
- Properties: Transform and opacity preferred (GPU accelerated)

### Gesture Support (Mobile)

| Gesture | Action |
|---------|--------|
| Swipe left/right | [Navigate / Delete / etc.] |
| Pull to refresh | Reload content |
| Long press | Context menu |

### Keyboard Navigation

- Tab order follows visual order
- Focus visible on all interactive elements
- Escape closes modals/dropdowns
- Enter/Space activates buttons
- Arrow keys for menus/lists

---

## Platform-Specific Guidance

### Web

**Responsive Behavior:**
- [How layout adapts at each breakpoint]
- [Component changes mobile vs desktop]

**Browser Considerations:**
- Target browsers: [List]
- Fallbacks: [For older browsers if needed]

### iOS

**HIG Alignment:**
- [Which standard patterns to use]
- [Where to customize]

**Native Patterns:**
- Navigation: [UINavigationController / Tab bar]
- Modals: [Sheet presentation / Full screen]
- Safe areas: Respect notch, home indicator

### Android

**Material Alignment:**
- [Material 3 components to use]
- [Customization approach]

**Native Patterns:**
- Navigation: [Bottom nav / Navigation drawer]
- FAB: [If applicable]
- System back: Handle properly

### Desktop (if applicable)

**Window Management:**
- Min/max sizes
- Resizing behavior

**Keyboard-First:**
- Shortcuts for power users
- Menu bar (Mac) / File menu (Windows)

---

## Accessibility

### WCAG Compliance: [AA / AAA]

**Requirements:**

| Criterion | Requirement | Implementation |
|-----------|-------------|----------------|
| 1.4.3 Contrast | 4.5:1 (text), 3:1 (large) | [How colors meet this] |
| 2.1.1 Keyboard | All functions via keyboard | Tab navigation, focus management |
| 2.4.7 Focus Visible | Clear focus indicators | [Focus ring style] |
| 4.1.2 Name, Role, Value | ARIA labels | Semantic HTML + ARIA |

### Focus Management

- Focus ring: 2px [brand color], offset 2px
- Focus trap in modals
- Return focus after modal close
- Skip links for screen readers

### Screen Reader Support

- Semantic HTML structure
- ARIA labels for icons/graphics
- Live regions for dynamic content
- Proper heading hierarchy

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Touch Accessibility

- Tap targets: 44px × 44px minimum
- Spacing between targets: 8px minimum
- No hover-only interactions on touch

---

## Implementation Notes

### CSS Custom Properties

```css
:root {
  /* Colors - from brand */
  --color-primary: #XXXXXX;
  --color-secondary: #XXXXXX;
  /* ... */

  /* Spacing */
  --space-1: 4px;
  --space-2: 8px;
  /* ... */

  /* Typography */
  --font-heading: '[Heading font]', sans-serif;
  --font-body: '[Body font]', sans-serif;
  /* ... */

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.1);
  /* ... */

  /* Radii */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
}
```

### Component Library Recommendation

[If applicable - recommend Tailwind, shadcn/ui, Material UI, etc. based on platform and preferences]

---

## Next Steps

This UI/UX system provides the foundation for implementation. Consider:
- Creating a component library
- Building a Storybook or documentation site
- Establishing design-to-code workflow
