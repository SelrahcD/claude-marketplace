---
name: note
description: Capture an observation for later retrospective review
---
Read the `improve` skill for the observation format.

Create `~/.claude/retro/` directory if it doesn't exist.

Append a new observation to `~/.claude/retro/observations.md` using the observation format from the skill:

- **Timestamp:** current date and time
- **Title:** summarize `$ARGUMENTS` into a concise title
- **Status:** `pending`
- **Project:** infer from the current working directory name
- **Context:** infer from the current conversation — what was happening when this was noted
- **Details:** `$ARGUMENTS` as the full observation text
- **Root cause:** leave empty (that's for `/review`)
- **Resolution:** leave empty (that's for `/retro`)

Respond only: "Noted."
