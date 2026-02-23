# Obsidian Bridge — Entry Format Redesign

## Context

The current daily note and project note entries produced by the obsidian-doc-writer agent feel too mechanical. The "Claude session —" title prefix and rigid bullet-only format make entries stand out as machine-generated rather than blending naturally with hand-written notes.

## Changes

### Daily Note Entry (Phase 2)

**Before:**
```markdown
### Claude session — Brief descriptive title
- What was accomplished #tag1 #tag2
- Key details with [[wiki-links]]
  - Sub-details indented as needed
```

**After:**
```markdown
### Brief descriptive title
#ai-assisted/claude #project-tag1 #project-tag2

A freeform paragraph summarizing what happened — context, decisions, outcomes.

- Key detail or artifact
- Another detail with [[wiki-links]]
```

- No "Claude session —" prefix in the title
- Tags on their own line: always `#ai-assisted/claude`, plus project tags from config
- Freeform paragraph first, then bullet points for specifics

### Project Note Entry (Phase 3)

**Before:**
```markdown
- **YYYY-MM-DD**: Brief summary — see [[🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD]]
```

**After:**
```markdown
### YYYY-MM-DD — Brief descriptive title

A freeform paragraph summarizing what happened. See [[🗓️ DailyNotes/YYYY/MM/YYYY-MM-DD]] for details.

- Key detail
- Another detail
```

- Date in the title, no tags
- Same freeform-then-bullets structure as daily notes
- Wiki-link to daily note woven into the text

## File to modify

Only `selrahcd-obsidian-bridge/agents/obsidian-doc-writer.md` — Phase 2 entry format, Phase 3 entry format, and associated guidelines.

## Version bump

- `selrahcd-obsidian-bridge/.claude-plugin/plugin.json`: 1.3.0 → 1.4.0
- `.claude-plugin/marketplace.json`: 1.3.0 → 1.4.0
