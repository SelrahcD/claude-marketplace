# Tech-layer organization

## What it is

Code organised by technical layer (`controllers/`, `services/`, `repositories/`, `models/`) rather than by feature or bounded context. Changing one feature requires touching every layer folder; reading one feature requires opening every layer folder. Agents pay this cost in tokens; humans pay it in shotgun surgery.

Citation: [Welcome to Code for Humans and Machines — Adam Tornhill](https://adamtornhill.substack.com/p/welcome-to-code-for-humans-and-machines); see also vertical-slice guidance in [AI-Ready Codebase Guide](https://llmx.tech/blog/ai-ready-codebase-claude-cursor-integration-guide/).

## AST detection

| Ecosystem | Command | Signal |
|---|---|---|
| Polyglot | `find <root> -type d -maxdepth 3 \( -iname controllers -o -iname services -o -iname repositories -o -iname dao -o -iname dtos -o -iname mappers \)` | Layer folder names exist near the root |
| Polyglot | `ls <layer-folder> \| wc -l` | Layer folder has ≥ 5 entries |
| Polyglot | `git log --since=3.months --format= --name-only \| grep -E '(controllers\|services\|repositories)/' \| awk -F/ '{print $NF}' \| sort \| uniq -c \| sort -rn` | Same feature name appears in commits touching multiple layer folders |

The last command is the most diagnostic: if commits routinely touch `controllers/OrderController.java` + `services/OrderService.java` + `repositories/OrderRepository.java` together, the feature is fragmented across layers.

## LM-fallback detection

Read the top-level folder structure and ask:

- Do folder names describe layers (`controllers`, `services`, `repositories`, `models`, `dtos`) or features (`billing`, `shipping`, `auth`, `inventory`)?
- For a representative feature: how many distinct folders must you open to read it end to end?
- Is there a 1:1:1 pattern of `XController` + `XService` + `XRepository` for each feature?

If the answers point to layers: the codebase is layer-organised.

## Refactor recipe

**This smell is REPORT-ONLY in the apply phase.** Restructuring a codebase into vertical slices is a major architectural move with cascading effects on builds, deployments, imports, code ownership, and team mental models. It is not a Fowler-style mechanical refactor and must not be applied automatically.

What the report should contain:

1. The layer folders detected.
2. A list of the top 5 features (by churn) that span all layer folders — these are the easiest wins for slice extraction.
3. A pointer to vertical-slice resources for a human to plan the move:
   - [AI-Ready Codebase Guide](https://llmx.tech/blog/ai-ready-codebase-claude-cursor-integration-guide/)
   - [Your codebase is the new prompt](https://guibesdev.medium.com/your-codebase-is-the-new-prompt-architecture-for-the-ai-era-8ad33d319489)

## When not to apply

Always. The apply phase must refuse to act on this smell. The command should mark it explicitly: *"Report only — slice extraction requires a human-led architectural decision."*
