# ClaudeUsageWidget

macOS 桌面小组件（WidgetKit），实时监控你的 Claude AI 用量限制。

![macOS](https://img.shields.io/badge/macOS-15.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

[English](README.md)

## 截图

![ClaudeUsageWidget 预览](screenshots/widget-preview.png)

## 功能

- **5 小时会话用量** + 进度条
- **每周用量** + 进度条
- **重置倒计时**
- **颜色随用量变化** 绿 → 黄 → 橙 → 红
- **三种尺寸** small、medium、large
- **双重认证** OAuth token 或 session key
- **自动刷新** 每 5 分钟

---

## 用 Claude Code 快速安装

把下面这段话粘贴给你的 Claude Code：

```
帮我克隆并构建 ClaudeUsageWidget 桌面小组件。

步骤：
1. git clone https://github.com/dependentsign/ClaudeUsageWidget.git ~/Documents/ClaudeUsageWidget
2. 打开 .xcodeproj，在 Xcode 里设置你的 Development Team，或者直接修改 project.pbxproj 里的 DEVELOPMENT_TEAM
3. 构建：xcodebuild -project ~/Documents/ClaudeUsageWidget/ClaudeUsageWidget.xcodeproj -scheme ClaudeUsageWidget -destination 'platform=macOS' build
4. 安装：用 ditto 把 DerivedData 里构建好的 .app 复制到 /Applications/ClaudeUsageWidget.app，然后 codesign --force --deep --sign - /Applications/ClaudeUsageWidget.app
5. 创建配置文件 ~/.claude/claude-usage-widget.json，填入我的 Claude session key（从 claude.ai 的 cookies 获取）和 org ID（用 curl https://claude.ai/api/organizations 加 session key cookie 获取）
6. 打开应用：open /Applications/ClaudeUsageWidget.app
7. 告诉我右键桌面 → 编辑小组件 → 搜索 "Claude" 添加
```

---

## 手动安装

### 1. 构建

```bash
git clone https://github.com/dependentsign/ClaudeUsageWidget.git
cd ClaudeUsageWidget
open ClaudeUsageWidget.xcodeproj
```

在 Xcode 中：
- 在两个 target（ClaudeUsageWidget + ClaudeUsageWidgetExtension）中选择你的**开发者团队**
- 按需修改 **Bundle Identifier**
- 构建运行（⌘R）

### 2. 配置凭证

创建配置文件 `~/.claude/claude-usage-widget.json`：

**方式 A：OAuth Token（推荐）**
```json
{
  "oauthToken": "你的-oauth-bearer-token"
}
```

**方式 B：Session Key**
```json
{
  "sessionKey": "sk-ant-sid01-...",
  "organizationId": "你的-org-uuid"
}
```

<details>
<summary>如何获取 session key</summary>

1. 打开 [claude.ai](https://claude.ai) 并登录
2. 开发者工具（F12）→ Application → Cookies → 复制 `sessionKey`
3. 获取组织 ID：
```bash
curl -s https://claude.ai/api/organizations \
  -H "Cookie: sessionKey=你的KEY" | python3 -m json.tool
```
复制 `uuid` 字段。

</details>

### 3. 添加小组件

1. 右键桌面 → **编辑小组件**
2. 搜索 **"Claude"**
3. 选择尺寸并添加

---

## 工作原理

小组件调用 Claude 的用量 API：

| 方式 | 接口 |
|------|------|
| OAuth | `GET https://api.anthropic.com/api/oauth/usage` |
| Session Key | `GET https://claude.ai/api/organizations/{orgId}/usage` |

返回数据：
- `five_hour.utilization` — 5 小时窗口用量百分比
- `five_hour.resets_at` — 重置时间戳
- `seven_day.utilization` — 每周用量百分比
- `seven_day.resets_at` — 每周重置时间戳

---

## 二次开发

### 项目结构

```
ClaudeUsageWidget/
├── ClaudeUsageWidget/                    # 宿主应用（配置界面）
│   ├── ClaudeUsageWidgetApp.swift
│   ├── ContentView.swift                 # 凭证配置表单
│   └── Info.plist
├── ClaudeUsageWidgetExtension/           # 小组件扩展
│   ├── ClaudeUsageWidget.swift           # 视图 + API 逻辑
│   ├── ClaudeUsageWidgetBundle.swift     # 入口
│   ├── ClaudeUsageWidgetExtension.entitlements
│   └── Info.plist
└── screenshots/
```

> **注意：** 小组件扩展运行在 App Sandbox 中。代码使用 `getpwuid(getuid())` 获取真实 home 目录路径，因为 `FileManager.default.homeDirectoryForCurrentUser` 在沙盒中返回的是容器路径。

## 系统要求

- macOS 15.0+
- Xcode 16.0+
- Claude Pro / Team / Enterprise 付费订阅

## 许可

MIT — 详见 [LICENSE](LICENSE)
