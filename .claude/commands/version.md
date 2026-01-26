---
name: version
description: Display versions of all plugins and marketplace
---

# Version - Display Plugin and Marketplace Versions

Show current versions of the marketplace and all plugins.

## Process

Read and display versions from:

1. **Marketplace**: `.claude-plugin/marketplace.json` → `metadata.version`
2. **Plugins**: For each plugin in the marketplace `plugins` array:
   - Read `<source>/.claude-plugin/plugin.json` → `version`

## Output Format

```
Marketplace: <version>

Plugins:
- <plugin-name>: <version>
- <plugin-name>: <version>
```
