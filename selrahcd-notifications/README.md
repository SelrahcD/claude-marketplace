# Claude Code Notifications Plugin

A lightweight Claude Code plugin that displays system notifications for important events during your Claude Code sessions.

## Overview

This plugin provides real-time desktop notifications when Claude Code triggers specific events, helping you stay informed even when Claude Code is running in the background.

## Features

### Supported Events

The plugin listens to and notifies you about the following events:

- **SessionStart** - When a new Claude Code session begins (🚀)
- **SessionEnd** - When a Claude Code session completes (✅)
- **Stop** - When Claude finishes responding to your request (🏁)
- **Notification** - Custom notifications from Claude with specific messages

### Cross-Platform Support

The notification script automatically detects your operating system and uses the appropriate notification system:

- **macOS**: Uses `terminal-notifier` for native notifications with sound
- **Linux**: Uses `notify-send` (requires `libnotify-bin` package)
- **Windows**: Uses PowerShell toast notifications
- **Fallback**: Prints to terminal if no notification system is available

## Installation

### Prerequisites

**macOS:**
```bash
brew install terminal-notifier
```

**Linux:**
```bash
sudo apt-get install libnotify-bin  # Debian/Ubuntu
# or
sudo yum install libnotify           # RHEL/CentOS
```

**Windows:**
No additional installation required (uses built-in PowerShell notifications)

### Plugin Installation

1. Ensure you have Claude Code installed
2. Add this marketplace to your Claude Code configuration:
   ```
   /plugin marketplace add SelrahcD/claude-marketplace
   ```
3. Install the notifications plugin:
   ```
   /plugin install notifications@Selrahcd-marketplace
   ```

That's it! The plugin uses `${CLAUDE_PLUGIN_ROOT}` to reference the notification script directly in the plugin directory, so no manual file copying is required.

## Usage

Once installed, the plugin works automatically. You'll receive notifications for:

- Starting a new Claude Code session
- Completing a session
- When Claude finishes each response
- Any custom notifications Claude sends

No manual intervention is required - notifications appear automatically based on Claude Code events.

## Customization

### Modifying Messages

Edit `scripts/claude-code-notifier.sh` to customize notification messages. The script includes a case statement where you can modify messages for each event type:

```bash
case "$hook_event" in
  "SessionStart")
    message="Your custom start message"
    ;;
  # ... etc
esac
```

### Changing Hook Configuration

Edit `hooks/hooks.json` to:
- Add or remove event types
- Change the notification script path
- Add additional hook commands

## How It Works

1. Claude Code triggers an event (SessionStart, Stop, etc.)
2. The hook system resolves `${CLAUDE_PLUGIN_ROOT}/scripts/claude-code-notifier.sh` and calls the notification script
3. The script receives JSON input with event details via stdin
4. It parses the event type and message using `jq`
5. Based on the OS, it sends a notification using the appropriate tool

## Troubleshooting

**No notifications appearing:**
- Ensure platform-specific tools are installed (see Prerequisites)
- Check that `jq` is installed and available in your PATH
- Verify the plugin is properly installed: `/plugin list`
- Check Claude Code logs for hook execution errors

**jq errors:**
Install jq if not already available:
```bash
brew install jq        # macOS
sudo apt-get install jq  # Linux
```

**Linux notifications not working:**
Ensure `notify-send` is installed and your desktop environment supports notifications.

## Project Structure

```
selrahcd-notifications/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── hooks/
│   └── hooks.json               # Hook configuration for events
├── scripts/
│   └── claude-code-notifier.sh  # Notification script
└── README.md                    # This file
```

## Credits

Based on [claude-code-notifier](https://github.com/hta218/claude-code-notifier) by [@hta218](https://github.com/hta218)

## License

This plugin is provided as-is for use with Claude Code.
