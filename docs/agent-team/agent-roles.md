# Agent Team Roles

## 1. A0 Tech Lead / Integrator

职责：

- 维护架构边界。
- 冻结协议版本。
- 分配任务包。
- 创建或审批 worktree。
- 控制合并顺序。
- 处理共享文件和冲突。
- 维护 `main` 可构建。

可修改路径：

```text
README.md
docs/
package.json
Package.swift
apps/macos/HermesIslandApp.swift
apps/macos/HermesIsland.xcodeproj
```

禁止事项：

- 不在多个功能域里直接替 Agent 写大块实现。
- 不把未验证分支合并到 `main`。
- 不接受没有验证结果的交付。

交付物：

- 每日任务分配。
- 合并记录。
- 接口变更公告。
- 集成验证结果。

## 2. A1 Protocol Agent

职责：

- 定义 Hermes Event Envelope。
- 定义消息、任务、通知、确认事件。
- 维护 JSON Schema 或 TypeScript 类型。
- 维护事件示例。
- 维护协议契约测试。

主要路径：

```text
packages/hermes-protocol/
docs/protocol.md
```

首批任务：

- `EventEnvelope` 必填字段：`event_id`、`seq`、`type`、`created_at`、`payload`。
- `message.send` client command。
- `message.accepted`、`message.delta`、`message.completed`、`message.failed`。
- `task.started`、`task.progress`、`task.completed`、`task.failed`、`task.cancelled`、`task.requires_approval`。
- `events.ack` client command。
- `notification.created`。

验证标准：

- 每种事件都有 schema。
- 每种事件都有 JSON 示例。
- 契约测试验证必填字段、`seq` 类型、事件类型枚举。

## 3. A2 Gateway Agent

职责：

- 实现 Hermes Gateway MVP。
- 提供设备码登录 mock。
- 提供 REST 历史补拉。
- 提供 WebSocket 实时事件。
- 实现事件存储和 `after_seq` 补拉。
- 实现 ACK cursor。
- 实现确认请求 API。

主要路径：

```text
server/gateway/
docs/api.md
```

首批 API：

```text
POST /v1/auth/device/start
POST /v1/auth/device/confirm
GET  /v1/events?after_seq=<seq>
POST /v1/events/ack
POST /v1/conversations
POST /v1/messages
GET  /v1/tasks
POST /v1/tasks/:id/cancel
POST /v1/approvals/:id/approve
POST /v1/approvals/:id/reject
GET  /healthz
WS   /v1/realtime?after_seq=<seq>
```

验证标准：

- WebSocket 连接后能从指定 `after_seq` 推送遗漏事件。
- 同一事件重复推送时 `event_id` 不变。
- `events.ack` 更新设备 cursor。
- mock 流式回复按 `message.accepted`、多个 `message.delta`、`message.completed` 顺序发出。

## 4. A3 macOS Shell Agent

职责：

- 创建 macOS App 工程骨架。
- 实现菜单栏入口。
- 实现主窗口路由。
- 实现设置页入口。
- 提供 App 全局状态容器。

主要路径：

```text
apps/macos/
apps/macos/MenuBar/
apps/macos/Settings/
```

首批 UI 状态：

```text
offline
connecting
online_idle
running
needs_approval
error
```

验证标准：

- App 可构建。
- 菜单栏图标可打开菜单。
- 菜单项可打开聊天窗口、任务窗口、设置窗口。
- mock 状态变化能更新菜单栏状态文本。

## 5. A4 Realtime Client Agent

职责：

- 实现 Swift SDK。
- 管理 REST 和 WebSocket 客户端。
- 实现重连退避。
- 实现 `last_seq` 断线恢复。
- 实现 `event_id` 去重。
- 实现 Keychain token abstraction。

主要路径：

```text
packages/hermes-swift-sdk/
apps/macos/Services/
```

首批模块：

```text
HermesClient
RealtimeConnection
EventStore
EventDeduplicator
ReconnectPolicy
KeychainTokenStore
```

验证标准：

- 单元测试覆盖重连退避序列：1s、2s、5s、10s、30s、60s。
- 单元测试覆盖重复 `event_id` 只处理一次。
- 单元测试覆盖 `last_seq` 更新。
- token 不写入 UserDefaults。

## 6. A5 UI Flow Agent

职责：

- 实现 Island 状态展示。
- 实现 Chat UI。
- 实现 Task Center。
- 实现 Notification Center。
- 实现 Approval Panel。

主要路径：

```text
apps/macos/Island/
apps/macos/Chat/
apps/macos/Tasks/
apps/macos/Notifications/
```

首批界面：

- Island 小态：运行中、完成、失败、需要确认。
- Island 展开态：确认请求详情、允许、拒绝、查看详情。
- Chat：消息列表、输入框、流式回复状态。
- Tasks：今日任务、运行中、等待确认、已完成、失败。
- Notifications：未读、已读、来源任务、操作按钮。

验证标准：

- 所有主要界面可在 preview 或 mock state 下渲染。
- 长文本不挤出按钮或面板。
- 普通消息不触发 Island，关键事件触发 Island。
- `task.requires_approval` 保持展示直到用户处理或超时。

## 7. A6 QA / Release Agent

职责：

- 建立 mock server 启动脚本。
- 建立 smoke test。
- 维护验收清单。
- 维护开发环境文档。
- 维护打包和发布说明。

主要路径：

```text
scripts/
docs/
```

首批任务：

- 一键启动 mock Gateway。
- 一键运行协议契约测试。
- 一键运行 Gateway smoke。
- macOS 手动验收清单。
- CI 命令草案。

验证标准：

- 新开发者按 README 能启动本地 demo。
- smoke 能验证消息流：send -> accepted -> delta -> completed。
- smoke 能验证任务确认：requires_approval -> approve/reject。

## 8. Agent 间接口约定

Protocol Agent 对外提供：

```text
事件类型枚举
JSON Schema
示例 JSON
协议版本号
```

Gateway Agent 对外提供：

```text
REST endpoint
WebSocket endpoint
mock event scripts
OpenAPI 或 API 文档
```

Realtime Client Agent 对外提供：

```text
Swift async API
事件订阅接口
连接状态 publisher
错误类型
```

macOS Shell Agent 对外提供：

```text
AppState
Window route
Menu command hooks
```

UI Flow Agent 对外提供：

```text
SwiftUI views
mock view models
approval action callbacks
```

QA Agent 对外提供：

```text
验证命令
mock 数据
验收清单
发布说明
```

