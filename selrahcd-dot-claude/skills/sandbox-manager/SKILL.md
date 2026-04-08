---
name: sandbox-manager
description: Use when the user wants to reduce permission prompts, configure sandbox settings, add allowed domains or filesystem paths, troubleshoot sandbox restrictions, or optimize their Claude Code sandbox configuration
---

# Sandbox Manager

## Overview

Interactively audit and tune Claude Code sandbox settings to minimize permission prompts while maintaining security. Every change must cite its source and explain the trade-off.

## When to Use

- User is getting too many permission prompts
- User wants to allow a specific command, domain, or filesystem path
- User wants to understand why a command was blocked
- User needs to configure sandbox for a new tool (docker, kubectl, terraform, gh, etc.)
- User says "fix my sandbox", "reduce prompts", "allow X"

## Process

### 1. Read Current Settings

Read all relevant settings files:

```
~/.claude/settings.json                  # User-global settings
.claude/settings.json                    # Project-shared settings
.claude/settings.local.json              # Project-local settings (gitignored)
```

Present a summary of current sandbox state:
- Is sandbox enabled?
- Is autoAllowBashIfSandboxed on?
- What filesystem paths are allowed/denied?
- What network domains are allowed?
- What commands are excluded from sandbox?
- What unix sockets are allowed?
- What permission allow/deny rules exist?

### 2. Identify Permission Friction

Ask the user what's causing friction:
- Frequent prompts for specific commands?
- Network access being blocked?
- Filesystem writes outside project dir?
- Unix socket access (SSH, Docker, tmux)?

### 3. Propose Changes with Sources

For EVERY change proposed, include:

1. **What**: The exact JSON to add/modify
2. **Why**: What permission friction it resolves
3. **Source**: Which documentation or guide recommends this
4. **Trade-off**: What security boundary is being relaxed
5. **Where**: Which settings file to put it in (user vs project vs local)

### 4. Apply Changes

After user approval, apply changes to the correct settings file.

## Reference: Common Configurations

### Enable Sandbox (Foundation)

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true
  }
}
```

- **Source**: [Anthropic sandboxing docs](https://code.claude.com/docs/en/sandboxing) - "Auto-allow mode: Bash commands will attempt to run inside the sandbox and are automatically allowed without requiring permission."
- **Trade-off**: Commands inside sandbox boundaries run without prompts. This is the recommended starting point.

### Additional Directories

```json
{
  "additionalDirectories": ["/Users/<USERNAME>/Workspace"]
}
```

- **Source**: [TestDouble guide](https://testdouble.com/insights/get-in-the-box-illustrated-permissions-guide-to-make-claude-chill) - "Consolidate all projects into a single directory so Claude can reference dependencies, clone repositories, and work across services without constant permission requests."
- **Trade-off**: Claude gets read/write access to the entire directory tree.

### Filesystem Write Access

```json
{
  "sandbox": {
    "filesystem": {
      "allowWrite": ["/tmp/build", "~/.kube", "~/.npm"]
    }
  }
}
```

- **Source**: [Anthropic settings docs](https://code.claude.com/docs/en/settings#sandbox-settings) - "Additional paths where sandboxed commands can write. Arrays are merged across all settings scopes."
- **Path prefixes**: `/` = absolute, `~/` = home-relative, `./` or bare = project-relative in project settings, `~/.claude`-relative in user settings.
- **Trade-off**: OS-level write access to these paths for ALL sandboxed subprocesses.

### Filesystem Read Deny

```json
{
  "sandbox": {
    "filesystem": {
      "denyRead": ["~/.aws/credentials", "~/.ssh/id_*"]
    }
  }
}
```

- **Source**: [Anthropic sandboxing docs](https://code.claude.com/docs/en/sandboxing) - "Protection against prompt injection: Cannot read files that are denied."
- **Trade-off**: Blocks subprocess reads at OS level. More secure than permission deny rules alone (which only block Claude's built-in tools, not `cat` via Bash).

### Network: Allowed Domains

```json
{
  "sandbox": {
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org", "registry.yarnpkg.com", "pypi.org"]
    }
  }
}
```

- **Source**: [Anthropic settings docs](https://code.claude.com/docs/en/settings#sandbox-settings) - "Array of domains to allow for outbound network traffic. Supports wildcards."
- **Important**: `allowedDomains` permits `curl`/`wget` but NOT the WebFetch tool. For WebFetch, use `permissions.allow` with `WebFetch(domain:example.com)`.
  - **Source**: [TestDouble guide](https://testdouble.com/insights/get-in-the-box-illustrated-permissions-guide-to-make-claude-chill) - "`sandbox.network.allowedDomains` permits curl commands but NOT the WebFetch tool."
- **Trade-off**: Sandboxed processes can reach these hosts. Be cautious with broad domains like `github.com` which could enable data exfiltration.

### Network: Unix Sockets

```json
{
  "sandbox": {
    "network": {
      "allowUnixSockets": [
        "/private/tmp/com.apple.launchd.*/Listeners",
        "/private/tmp/tmux-*/default"
      ]
    }
  }
}
```

Common sockets (macOS):
| Socket | Path |
|--------|------|
| SSH agent | `/private/tmp/com.apple.launchd.*/Listeners` |
| tmux | `/private/tmp/tmux-*/default` |
| Nix | `/nix/var/nix/daemon-socket/socket` |
| Rails parallel | `/tmp/Claude/druby*` |

- **Source**: [TestDouble guide](https://testdouble.com/insights/get-in-the-box-illustrated-permissions-guide-to-make-claude-chill) - lists common sockets needed.
- **Warning**: Docker sockets (`/var/run/docker.sock`) allow escaping the sandbox via volume mounts.
  - **Source**: [Anthropic sandboxing docs](https://code.claude.com/docs/en/sandboxing) - "allowUnixSockets can inadvertently grant access to powerful system services that could lead to sandbox bypasses."
- **Trade-off**: Process-to-process communication through these sockets.

### Network: Local Port Binding

```json
{
  "sandbox": {
    "network": {
      "allowLocalBinding": true
    }
  }
}
```

- **Source**: [Anthropic settings docs](https://code.claude.com/docs/en/settings#sandbox-settings) - "Allow binding to localhost ports (macOS only)."
- **Trade-off**: Sandboxed commands can start local servers. Needed for dev servers, test runners, etc.

### Excluded Commands (Escape Hatch)

```json
{
  "sandbox": {
    "excludedCommands": ["docker *"]
  }
}
```

- **Source**: [Anthropic sandboxing docs](https://code.claude.com/docs/en/sandboxing) - "docker is incompatible with running in the sandbox. Consider specifying `docker *` in `excludedCommands`."
- **Warning**: [TestDouble guide](https://testdouble.com/insights/get-in-the-box-illustrated-permissions-guide-to-make-claude-chill) cautions that Claude develops "unsandboxed momentum" - once running commands outside the sandbox, it continues doing so even when unnecessary.
- **Trade-off**: These commands bypass ALL sandbox restrictions. Prefer `allowWrite`/`allowedDomains` when possible.
- Pair with `permissions.allow` to also skip the permission prompt: `"Bash(docker *)"`.

### Permission Allow Rules (for tools)

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git commit *)",
      "WebFetch(domain:docs.example.com)"
    ]
  }
}
```

- **Source**: [Anthropic permissions docs](https://code.claude.com/docs/en/permissions) - "Add a specifier in parentheses to match specific tool uses."
- **Wildcard note**: Space before `*` matters. `Bash(ls *)` matches `ls -la` but not `lsof`. `Bash(ls*)` matches both.
- `WebFetch(domain:X)` in permissions.allow permits BOTH scripts and the WebFetch tool, unlike `allowedDomains` which only permits scripts.
  - **Source**: [TestDouble guide](https://testdouble.com/insights/get-in-the-box-illustrated-permissions-guide-to-make-claude-chill) - "`permissions.allow` supports wildcards, making it superior to `allowedDomains`."

### TLS Trust for Go-based Tools

```json
{
  "sandbox": {
    "enableWeakerNetworkIsolation": true
  }
}
```

- **Source**: [Anthropic settings docs](https://code.claude.com/docs/en/settings#sandbox-settings) - "Required for Go-based tools like `gh`, `gcloud`, and `terraform` to verify TLS certificates."
- **Trade-off**: Opens access to macOS TLS trust service, creating a potential data exfiltration path.

## Decision Framework

When a user reports permission friction, use this priority:

1. **Can the sandbox handle it?** Add to `allowWrite`, `allowedDomains`, or `allowUnixSockets`. Keeps OS-level enforcement.
2. **Is it a permission rule issue?** Add to `permissions.allow`. Less strict than sandbox but still controlled.
3. **Is the tool incompatible with sandbox?** Add to `excludedCommands` as last resort. Pair with `permissions.allow` to avoid double-prompting.

This follows the [TestDouble guide](https://testdouble.com/insights/get-in-the-box-illustrated-permissions-guide-to-make-claude-chill)'s "Allow, Kill, Push" framework:
- **Allow**: Add to global allow list permanently
- **Kill**: Provide alternative workflow (e.g., clone dependencies locally instead of fetching)
- **Push**: Move permission request to task start/end instead of middle

## Where to Put Settings

| Setting type | File | When |
|---|---|---|
| Personal tools/domains | `~/.claude/settings.json` | Applies to all your projects |
| Team sandbox config | `.claude/settings.json` | Shared via git |
| Personal project overrides | `.claude/settings.local.json` | Gitignored, just for you |

- **Source**: [Anthropic settings docs](https://code.claude.com/docs/en/settings#settings-precedence) - Precedence: Managed > CLI args > Local > Project > User.

## Security: What to Never Auto-Allow

Per the [TestDouble guide](https://testdouble.com/insights/get-in-the-box-illustrated-permissions-guide-to-make-claude-chill), manually approve operations that:
- Read untrusted data (prompt injection risk)
- Affect reputation (uploading code to client repos)
- Modify unversioned files (deletions, edits outside git)
- Modify sandbox configuration itself

Per [Anthropic sandboxing docs](https://code.claude.com/docs/en/sandboxing):
- Never allow writes to directories containing executables in `$PATH`
- Never allow writes to system config dirs or shell configs (`.bashrc`, `.zshrc`)
- Be cautious with Docker socket access (enables sandbox escape)
- Be cautious with broad domain allowlists (enables data exfiltration)
