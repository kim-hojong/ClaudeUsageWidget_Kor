# ClaudeUsageWidget

A macOS desktop widget (WidgetKit) that monitors your Claude AI usage limits in real-time.

![macOS](https://img.shields.io/badge/macOS-15.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

[한국어](README_KO.md) | [中文](README_CN.md)

## Screenshots

![ClaudeUsageWidget Preview](screenshots/widget-preview.png)

## Features

- **5-hour session usage** with progress bar
- **Weekly usage** with progress bar
- **Reset countdown** for both windows
- **Color-coded** green → yellow → orange → red
- **Three widget sizes** — small, medium, large
- **Dual auth** — OAuth token or session key
- **Auto-refresh** every 5 minutes

---

## Quick Install with Claude Code

Paste this into your Claude Code session:

```
Clone https://github.com/dependentsign/ClaudeUsageWidget and build it for me.

Steps:
1. git clone https://github.com/dependentsign/ClaudeUsageWidget.git ~/Documents/ClaudeUsageWidget
2. Open the .xcodeproj and set your Development Team in Xcode, or update DEVELOPMENT_TEAM in project.pbxproj
3. Build: xcodebuild -project ~/Documents/ClaudeUsageWidget/ClaudeUsageWidget.xcodeproj -scheme ClaudeUsageWidget -destination 'platform=macOS' build
4. Install: ditto the built .app from DerivedData to /Applications/ClaudeUsageWidget.app, then codesign --force --deep --sign - /Applications/ClaudeUsageWidget.app
5. Create config at ~/.claude/claude-usage-widget.json with my Claude session key (get it from claude.ai cookies) and org ID (curl https://claude.ai/api/organizations with the session key cookie)
6. Open the app: open /Applications/ClaudeUsageWidget.app
7. Tell me to right-click desktop → Edit Widgets → search "Claude" to add it
```

---

## Manual Setup

### 1. Build

```bash
git clone https://github.com/dependentsign/ClaudeUsageWidget.git
cd ClaudeUsageWidget
open ClaudeUsageWidget.xcodeproj
```

In Xcode:
- Select your **Development Team** in both targets (ClaudeUsageWidget + ClaudeUsageWidgetExtension)
- Update **Bundle Identifier** if needed
- Build & Run (⌘R)

### 2. Configure Credentials

Create `~/.claude/claude-usage-widget.json`:

**Option A: OAuth Token (recommended)**
```json
{
  "oauthToken": "your-oauth-bearer-token"
}
```

**Option B: Session Key**
```json
{
  "sessionKey": "sk-ant-sid01-...",
  "organizationId": "your-org-uuid"
}
```

<details>
<summary>How to get session key</summary>

1. Open [claude.ai](https://claude.ai) and log in
2. DevTools (F12) → Application → Cookies → copy `sessionKey`
3. Get org ID:
```bash
curl -s https://claude.ai/api/organizations \
  -H "Cookie: sessionKey=YOUR_KEY" | python3 -m json.tool
```
Copy the `uuid` field.

</details>

### 3. Add Widget

1. Right-click desktop → **Edit Widgets...**
2. Search **"Claude"**
3. Choose size and add

---

## How It Works

The widget calls Claude's usage API:

| Method | Endpoint |
|--------|----------|
| OAuth | `GET https://api.anthropic.com/api/oauth/usage` |
| Session Key | `GET https://claude.ai/api/organizations/{orgId}/usage` |

Returns:
- `five_hour.utilization` — 5-hour window usage %
- `five_hour.resets_at` — reset timestamp
- `seven_day.utilization` — weekly usage %
- `seven_day.resets_at` — weekly reset timestamp

---

## Development

### Project Structure

```
ClaudeUsageWidget/
├── ClaudeUsageWidget/                    # Host app (config UI)
│   ├── ClaudeUsageWidgetApp.swift
│   ├── ContentView.swift                 # Credential config form
│   └── Info.plist
├── ClaudeUsageWidgetExtension/           # Widget extension
│   ├── ClaudeUsageWidget.swift           # Views + API logic
│   ├── ClaudeUsageWidgetBundle.swift     # Entry point
│   ├── ClaudeUsageWidgetExtension.entitlements
│   └── Info.plist
└── screenshots/
```

> **Note:** Widget extensions run in App Sandbox. We use `getpwuid(getuid())` to resolve the real home directory instead of `FileManager.default.homeDirectoryForCurrentUser` (which returns the sandbox container path).

## Requirements

- macOS 15.0+
- Xcode 16.0+
- Claude Pro / Team / Enterprise subscription

## License

MIT — see [LICENSE](LICENSE)
