---
name: adr
description: Manage Architecture Decision Records (ADRs) for documenting technical decisions. Use when discussing architecture, design decisions, trade-offs, or when the user mentions ADRs, architectural decisions, or wants to document a technical choice.
---

# ADR Management

Manage Architecture Decision Records (ADRs) for this project.

## Usage

This skill is invoked with `/adr <command> [arguments]`

Commands:

- `/adr new <title>` - Create a new ADR
- `/adr list` - List all existing ADRs
- `/adr show <number>` - Display a specific ADR
- `/adr supersede <number> <new-title>` - Create a new ADR that supersedes an existing one
- `/adr deprecate <number>` - Mark an ADR as deprecated

## Instructions

When this skill is invoked, follow these instructions based on the command:

### Directory Structure

ADRs are stored in `docs/adr/` with the naming convention `NNNN-kebab-case-title.md` where NNNN is a zero-padded sequential number starting from 0001.

### For `/adr new <title>`

1. Check if `docs/adr/` directory exists, create it if not
2. Find the next available ADR number by listing existing ADRs
3. **Ask the user about decision context** before writing content:
   - "Were other options actually considered, or is this the only option you evaluated?"
   - If only one option: use a simplified template without "Considered Options" and "Pros and Cons" sections
   - If multiple options were considered: ask what they were before filling in the template
   - Never fabricate alternatives or rationale the user didn't provide
4. Create a new ADR file using this template:

```markdown
# ADR-NNNN: <Title>

**Status:** Proposed
**Date:** <YYYY-MM-DD>
**Deciders:** <list of involved people>
**Technical Story:** <description or ticket/issue URL>

## Context

<Describe the context and problem statement. What is the issue that is motivating this decision?>

## Decision Drivers

- <Driver 1>
- <Driver 2>
- <Driver 3>

## Considered Options

1. <Option 1>
2. <Option 2>
3. <Option 3>

## Decision Outcome

**Chosen option:** "<Option N>", because <justification>.

### Positive Consequences

- <Positive consequence 1>
- <Positive consequence 2>

### Negative Consequences

- <Negative consequence 1>
- <Negative consequence 2>

## Pros and Cons of the Options

### Option 1: <Title>

<Description>

- Good, because <argument>
- Bad, because <argument>

### Option 2: <Title>

<Description>

- Good, because <argument>
- Bad, because <argument>

### Option 3: <Title>

<Description>

- Good, because <argument>
- Bad, because <argument>

## Related Decisions

- <Link to related ADR or N/A>

## Notes

<Additional notes, if any>
```

4. Fill in the date with today's date
5. Leave placeholder text for the user to fill in
6. Report the created file path

### For `/adr list`

1. List all ADR files in `docs/adr/`
2. For each ADR, extract:
   - Number and title from filename
   - Status from the file content
   - Date from the file content
3. Display as a formatted table:

```
| ADR | Title | Status | Date |
|-----|-------|--------|------|
| 0001 | Example Decision | Accepted | 2024-01-15 |
```

If no ADRs exist, inform the user and suggest using `/adr new <title>` to create one.

### For `/adr show <number>`

1. Find the ADR file matching the number (handle both "1" and "0001" formats)
2. Read and display the full content
3. If not found, list available ADRs and suggest the correct number

### For `/adr supersede <number> <new-title>`

1. Find the existing ADR by number
2. Create a new ADR with the new title (following `/adr new` process)
3. Add to the new ADR under "Related Decisions": `Supersedes ADR-NNNN: <old title>`
4. Update the old ADR:
   - Change status to `Superseded by ADR-MMMM`
   - Add note at the top: `> **Note:** This ADR has been superseded by [ADR-MMMM](./MMMM-new-title.md)`
5. Report both files that were modified

### For `/adr deprecate <number>`

1. Find the ADR file by number
2. Update the status to `Deprecated`
3. Add a note at the top: `> **Note:** This ADR has been deprecated on <date>.`
4. Ask the user for the deprecation reason and add it to the Notes section
5. Report the modified file

## Valid Status Values

- **Proposed** - Initial state, decision is being discussed
- **Accepted** - Decision has been accepted and should be followed
- **Deprecated** - Decision is no longer relevant but kept for historical reference
- **Superseded by ADR-NNNN** - Replaced by a newer decision

## Examples

### Creating a new ADR

**Input:** `/adr new Use PostgreSQL for primary database`

**Output:**

```
Created: docs/adr/0001-use-postgresql-for-primary-database.md

The ADR has been created with placeholder content. Please fill in:
- Deciders
- Technical Story
- Context
- Decision Drivers
- Considered Options
- Decision Outcome
```

### Listing ADRs

**Input:** `/adr list`

**Output:**

```
| ADR  | Title                              | Status   | Date       |
|------|------------------------------------|----------|------------|
| 0001 | Use PostgreSQL for primary database | Accepted | 2024-01-15 |
| 0002 | Adopt React for frontend           | Proposed | 2024-01-20 |
| 0003 | Use REST over GraphQL              | Accepted | 2024-02-01 |
```

### Superseding an ADR

**Input:** `/adr supersede 1 Use MongoDB for primary database`

**Output:**

```
Created: docs/adr/0004-use-mongodb-for-primary-database.md
Updated: docs/adr/0001-use-postgresql-for-primary-database.md
  - Status changed to: Superseded by ADR-0004
  - Added supersession note at top

The new ADR references the superseded decision.
```

## Best Practices

When helping users write ADRs:

1. **Be specific** - Avoid vague language; state exactly what was decided
2. **Capture context** - Future readers need to understand why this decision was made
3. **Only document actual alternatives** - If the user only considered one option, don't fabricate others. It's valid to choose something because "it's what we know" or "it's the standard"
4. **Be honest about trade-offs** - Every decision has downsides; document them
5. **Keep it concise** - ADRs should be readable in a few minutes
6. **Link related decisions** - Help readers understand the decision landscape
7. **Never fabricate rationale** - Ask the user for the actual reasons behind the decision; don't invent plausible-sounding justifications
