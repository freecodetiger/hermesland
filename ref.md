下面给你一版比较完整的产品设计方案。这个产品可以暂定为：

> **Hermes Island：macOS 原生 Agent 通知与任务控制中心**

它不是单纯的“Mac 灵动岛”，而是一个让服务器上的 Hermes Agent 自然进入 macOS 桌面的原生客户端。

---

# 1. 产品定位

## 一句话定位

**一个运行在 macOS 菜单栏的 Agent Companion App，通过顶部 Island 面板、系统通知和实时对话，把 Hermes Agent 的任务执行、定时提醒、流式对话和确认请求带到桌面。**

## 产品不应该是什么

不建议把它做成：

```text
Open WebUI 套壳
ChatGPT 桌面版
纯聊天窗口
纯通知工具
仿 iPhone 灵动岛玩具
复杂 Agent 编排平台
```

它应该是：

```text
轻量
原生
常驻
可靠
低打扰
面向 Agent 任务流
```

核心价值不是“能聊天”，而是：

> **Agent 在服务器上工作，用户在 Mac 上被及时、自然、可控地通知和介入。**

---

# 2. 核心用户场景

## 场景一：流式对话

用户点击菜单栏 Hermes 图标，打开轻量聊天窗口，向 Hermes 提问：

```text
帮我总结今天 GitHub 项目的进展
```

Hermes Agent 在服务端执行任务，macOS 客户端实时流式显示回复。

体验接近 Telegram / ChatGPT：

```text
用户发出消息
↓
本地立即显示发送中
↓
服务端确认接收
↓
Hermes 开始流式回复
↓
消息持续追加
↓
任务完成
```

---

## 场景二：定时任务通知

用户提前在 Hermes 中配置任务：

```text
每天晚上 10 点总结今天的开发进展
```

到时间后：

```text
Hermes Agent 执行任务
↓
macOS Island 显示“正在生成今日总结”
↓
完成后弹出系统通知
↓
用户点击查看详情
```

---

## 场景三：需要用户确认的任务

例如 Hermes 要自动发送邮件：

```text
Hermes 已生成周报，是否发送给 team@example.com？
```

macOS Island 展开：

```text
是否发送本周周报？

[发送] [取消] [查看详情]
```

用户确认后，Hermes Agent 才继续执行。

这是这个产品最有价值的地方。

---

## 场景四：Agent 后台运行状态

用户不需要打开网页，也能知道：

```text
Hermes 在线
Hermes 正在执行任务
Hermes 需要确认
Hermes 离线
任务失败
有新消息
```

这些状态通过菜单栏图标、Island 小窗和系统通知展示。

---

# 3. 产品结构

整体可以分成四层：

```text
macOS 客户端
  ├─ 菜单栏入口
  ├─ 顶部 Island 面板
  ├─ 聊天 / 任务窗口
  └─ 系统通知

Hermes Gateway
  ├─ 登录鉴权
  ├─ WebSocket 实时事件
  ├─ REST API
  ├─ 通知服务
  └─ 事件存储

Hermes Agent
  ├─ 对话
  ├─ 工具调用
  ├─ 定时任务
  ├─ 长任务执行
  └─ 用户确认流程

基础设施
  ├─ 数据库
  ├─ 队列
  ├─ APNs
  ├─ 日志
  └─ 监控
```

---

# 4. macOS 客户端设计

## 4.1 菜单栏入口

菜单栏是主入口，不要让用户必须打开一个完整窗口。

菜单栏内容可以是：

```text
Hermes
────────────────
状态：在线
当前任务：无
────────────────
打开对话
查看任务
查看通知
快速触发任务
设置
退出
```

菜单栏图标状态：

| 状态   | 表现       |
| ---- | -------- |
| 在线空闲 | 普通图标     |
| 正在运行 | 小圆点 / 动画 |
| 有通知  | 红点       |
| 需要确认 | 高亮       |
| 离线   | 灰色       |
| 错误   | 警告标记     |

---

## 4.2 顶部 Island 面板

Island 面板只用于关键状态，不应该常驻打扰用户。

### 小态

```text
Hermes 正在生成今日总结...
```

```text
任务完成：日报已生成
```

```text
需要确认：是否发送邮件？
```

### 展开态

点击 Island 后展开：

```text
Hermes 请求确认

发送邮件给 team@example.com
主题：本周项目进展

[允许] [拒绝] [查看详情]
```

### 固定态

当 Agent 执行长任务时，可以固定显示：

```text
正在分析仓库...
72%

[查看日志] [取消]
```

---

## 4.3 聊天窗口

聊天窗口不需要做得像 Open WebUI 那么重。

第一版只需要：

```text
会话列表
消息流
输入框
附件入口
任务状态提示
流式回复
失败重试
```

消息状态：

```text
sending
accepted
streaming
completed
failed
cancelled
```

UI 重点是可靠，而不是花哨。

---

## 4.4 任务中心

任务中心展示 Hermes 的所有任务：

```text
今日任务
定时任务
正在运行
等待确认
已完成
失败任务
```

每个任务展示：

```text
任务名
执行状态
开始时间
耗时
触发来源
最近日志
操作按钮
```

操作包括：

```text
运行
暂停
取消
重试
查看日志
修改定时规则
```

---

## 4.5 通知中心

App 内部也需要一个通知列表，不能只依赖 macOS 系统通知。

通知类型：

```text
任务完成
任务失败
需要确认
Agent 离线
Agent 恢复在线
定时任务即将执行
消息回复完成
```

每条通知需要有：

```text
标题
正文
来源任务
时间
是否已读
操作按钮
```

---

# 5. 服务端接入设计

## 5.1 不让客户端直接连 Agent

客户端不应该直接连接 Hermes Agent Worker，而是连接 Hermes Gateway。

```text
macOS App
   ↓
Hermes Gateway
   ↓
Hermes Agent
```

原因：

```text
鉴权统一
协议稳定
方便多设备同步
方便断线恢复
方便做通知兜底
方便做审计
Agent 可以横向扩展
```

---

## 5.2 接入协议

推荐组合：

```text
REST API：登录、历史、任务管理、配置
WebSocket：实时消息、流式回复、任务事件、通知
APNs：离线通知
```

不要只用 REST。
也不要只用 WebSocket。

二者分工：

| 能力    | 推荐方式             |
| ----- | ---------------- |
| 登录    | REST             |
| 拉历史消息 | REST             |
| 创建会话  | REST             |
| 发送消息  | WebSocket 或 REST |
| 流式回复  | WebSocket        |
| 任务状态  | WebSocket        |
| 用户确认  | REST             |
| 断线补拉  | REST             |
| 离线通知  | APNs             |

---

# 6. 实时事件协议

整个产品的核心是统一事件流。

所有服务端主动推送的内容，都应该包装成 Event Envelope。

```json
{
  "event_id": "evt_01JABC",
  "seq": 1024,
  "type": "message.delta",
  "conversation_id": "conv_01JABC",
  "message_id": "msg_01JABC",
  "created_at": "2026-06-08T12:00:00Z",
  "payload": {
    "delta": "今天你的任务完成情况如下："
  }
}
```

核心字段：

| 字段                | 作用                |
| ----------------- | ----------------- |
| `event_id`        | 全局唯一 ID，用于去重      |
| `seq`             | 用户维度单调递增序号，用于断线恢复 |
| `type`            | 事件类型              |
| `conversation_id` | 所属会话              |
| `message_id`      | 所属消息              |
| `created_at`      | 服务端创建时间           |
| `payload`         | 事件内容              |

---

## 6.1 事件类型

第一版建议支持这些：

```text
message.accepted
message.delta
message.completed
message.failed

task.started
task.progress
task.completed
task.failed
task.cancelled
task.requires_approval

notification.created

agent.online
agent.offline

system.error
```

---

## 6.2 流式对话事件

用户发送：

```json
{
  "type": "message.send",
  "client_msg_id": "local_123",
  "conversation_id": "conv_01JABC",
  "payload": {
    "content": "帮我总结今天的任务"
  }
}
```

服务端确认：

```json
{
  "event_id": "evt_1001",
  "seq": 1001,
  "type": "message.accepted",
  "conversation_id": "conv_01JABC",
  "message_id": "msg_user_01JABC",
  "payload": {
    "client_msg_id": "local_123"
  }
}
```

服务端流式返回：

```json
{
  "event_id": "evt_1002",
  "seq": 1002,
  "type": "message.delta",
  "conversation_id": "conv_01JABC",
  "message_id": "msg_assistant_01JABC",
  "payload": {
    "delta": "今天"
  }
}
```

结束：

```json
{
  "event_id": "evt_1003",
  "seq": 1003,
  "type": "message.completed",
  "conversation_id": "conv_01JABC",
  "message_id": "msg_assistant_01JABC",
  "payload": {
    "finish_reason": "stop"
  }
}
```

---

# 7. 可靠性设计

这是能不能像 Telegram 一样好用的关键。

## 7.1 本地消息 ID

用户发消息时，客户端先生成：

```text
client_msg_id
```

本地立即显示消息，不等服务端返回。

服务端返回真实：

```text
message_id
```

客户端把二者关联起来。

这样用户体验会很顺滑。

---

## 7.2 单调递增 seq

每个用户的事件都要有一个递增序号：

```text
1001
1002
1003
1004
```

客户端保存最后处理到的：

```text
last_seq = 1004
```

断线重连时：

```http
GET /v1/events?after_seq=1004
```

服务端补发遗漏事件。

---

## 7.3 ACK 机制

客户端定期告诉服务端：

```json
{
  "type": "events.ack",
  "payload": {
    "last_seq": 1050
  }
}
```

不要每条事件都 ACK，可以批量 ACK。

推荐策略：

```text
每 5 秒 ACK 一次
或每处理 20 条事件 ACK 一次
或 App 退出前 ACK 一次
```

---

## 7.4 断线重连

WebSocket 必须有重连机制。

推荐退避：

```text
1s
2s
5s
10s
30s
60s
```

加随机抖动，避免服务端重启时所有客户端同时重连。

重连后：

```text
1. 重新鉴权
2. 带 last_seq 建立连接
3. 服务端补发事件
4. 客户端去重
5. 恢复 UI 状态
```

---

## 7.5 去重

客户端必须维护已处理事件 ID。

```text
event_id 已处理 → 丢弃
event_id 未处理 → 执行
```

防止：

```text
重连重复推送
APNs 和 WebSocket 同时到达
REST 补拉和实时流重复
```

---

# 8. 通知设计

## 8.1 在线时

App 在线：

```text
WebSocket 事件
↓
Island 提示
↓
必要时触发 macOS 本地通知
```

普通消息不一定要系统通知。

重要事件需要系统通知：

```text
任务失败
需要确认
长任务完成
Agent 离线
高优先级提醒
```

---

## 8.2 离线时

App 不在线：

```text
Hermes Gateway
↓
APNs
↓
macOS 系统通知
```

APNs 通知只发摘要，不发完整敏感内容。

例如：

```json
{
  "aps": {
    "alert": {
      "title": "Hermes 需要确认",
      "body": "一个定时任务正在等待你的操作"
    },
    "sound": "default"
  },
  "event_id": "evt_01JABC"
}
```

用户点击通知后，App 再通过 REST 拉取完整内容。

---

# 9. 权限与安全设计

## 9.1 登录方式

推荐设备码登录：

```text
1. Mac App 显示登录码
2. 用户在浏览器打开 Hermes Web
3. 输入或扫码确认
4. 服务端绑定设备
5. Mac App 获得 token
```

不要让用户手动复制长期 token。

---

## 9.2 Token 存储

macOS 客户端必须把 token 存在：

```text
Keychain
```

不要存：

```text
UserDefaults
本地 JSON
SQLite 明文字段
配置文件
日志
```

---

## 9.3 高危操作必须二次确认

以下操作不能自动执行：

```text
发送邮件
删除文件
执行 shell 命令
修改生产环境
发起支付
发布内容
访问敏感文件
调用外部 API 执行不可逆操作
```

必须进入：

```text
task.requires_approval
```

用户确认后才能继续。

---

## 9.4 审计日志

服务端要记录：

```text
谁发起的任务
哪个 Agent 执行
哪个设备确认
确认时间
执行结果
失败原因
```

这对 Agent 产品非常重要。

---

# 10. 数据模型设计

第一版服务端至少需要这些表：

```text
users
devices
conversations
messages
events
tasks
task_runs
approval_requests
notifications
device_event_cursors
```

## 10.1 messages

```text
id
conversation_id
role
content
status
created_at
updated_at
```

## 10.2 events

```text
id
seq
user_id
type
payload
created_at
```

## 10.3 devices

```text
id
user_id
device_name
platform
push_token
last_seen_at
created_at
```

## 10.4 device_event_cursors

```text
user_id
device_id
last_acked_seq
updated_at
```

## 10.5 approval_requests

```text
id
task_id
event_id
status
expires_at
approved_by_device_id
approved_at
created_at
```

---

# 11. macOS 技术选型

客户端建议：

```text
Swift
SwiftUI
AppKit
MenuBarExtra / NSStatusItem
NSPanel
UserNotifications
URLSessionWebSocketTask
Keychain
SMAppService
SQLite / SwiftData
```

各模块职责：

| 模块        | 技术                          |
| --------- | --------------------------- |
| 菜单栏       | MenuBarExtra / NSStatusItem |
| Island 面板 | NSPanel + SwiftUI           |
| 主窗口       | SwiftUI                     |
| WebSocket | URLSessionWebSocketTask     |
| 通知        | UserNotifications           |
| Token     | Keychain                    |
| 本地缓存      | SQLite / SwiftData          |
| 开机启动      | SMAppService                |

---

# 12. 关键约束

这是这类产品必须提前定好的边界。

## 12.1 macOS 平台约束

### 不能真正接管系统灵动岛

macOS 没有开放 iPhone Dynamic Island 那样的系统 API。

所以只能做：

```text
顶部悬浮面板
菜单栏状态
系统通知
```

不能做：

```text
真正嵌入系统刘海
修改菜单栏系统区域
伪装系统通知
拦截系统级事件
```

---

## 12.2 UI 约束

Island 不能过度打扰。

推荐规则：

```text
普通消息：不弹 Island
任务开始：短暂显示
任务完成：短暂显示
任务失败：显示 + 通知
需要确认：显示 + 通知 + 保持
长任务运行：允许固定
```

禁止：

```text
所有消息都弹出
频繁动画
遮挡用户输入
抢焦点
模仿系统权限弹窗
```

---

## 12.3 通信约束

必须满足：

```text
所有连接使用 HTTPS / WSS
所有事件有 event_id
所有事件有 seq
所有客户端请求支持幂等
断线后必须可恢复
消息必须可去重
```

不建议：

```text
客户端直连 Agent
没有事件存储
只靠 WebSocket 不落库
只靠 APNs 做状态同步
```

---

## 12.4 安全约束

必须满足：

```text
Token 只进 Keychain
高危操作必须确认
服务端保留审计日志
客户端不执行任意代码
通知不泄露敏感内容
默认最小权限
```

严禁：

```text
服务端下发 shell 给客户端执行
明文保存 token
日志打印 access token
通知中直接展示敏感文件内容
确认按钮绕过服务端权限校验
```

---

## 12.5 产品约束

第一版不要做太重。

不要第一版就做：

```text
知识库 RAG
插件市场
多模型管理
团队权限系统
复杂工作流编排
本地大模型
多端同步完整生态
Open WebUI 级别聊天平台
```

第一版只做：

```text
连接 Hermes
实时对话
流式回复
任务状态
定时任务通知
用户确认
断线恢复
系统通知
菜单栏入口
Island 展示
```

---

# 13. MVP 版本设计

## MVP 0.1：验证通信

目标：证明 macOS App 可以稳定连上 Hermes。

功能：

```text
设备码登录
WebSocket 连接
发送消息
流式回复
断线重连
基础菜单栏
```

---

## MVP 0.2：加入任务事件

目标：证明 Agent 状态能进入桌面。

功能：

```text
task.started
task.progress
task.completed
task.failed
Island 状态提示
本地通知
任务详情页
```

---

## MVP 0.3：加入用户确认

目标：形成核心差异化。

功能：

```text
task.requires_approval
Island 确认面板
允许 / 拒绝
确认审计
确认超时
失败重试
```

---

## MVP 1.0：可公开发布

目标：成为一个完整可用的开源产品。

功能：

```text
菜单栏 App
顶部 Island
实时聊天
流式回复
任务中心
通知中心
用户确认
本地缓存
断线恢复
Keychain
开机启动
基础设置
```

APNs 可以放在 1.1 或 1.2，不一定第一版就上。

---

# 14. 推荐的开源项目结构

```text
hermes-island/
├─ apps/
│  └─ macos/
│     ├─ HermesIslandApp.swift
│     ├─ MenuBar/
│     ├─ Island/
│     ├─ Chat/
│     ├─ Tasks/
│     ├─ Notifications/
│     ├─ Settings/
│     └─ Services/
│
├─ packages/
│  ├─ hermes-protocol/
│  ├─ hermes-swift-sdk/
│  └─ hermes-types/
│
├─ server/
│  ├─ gateway/
│  ├─ websocket/
│  ├─ scheduler/
│  ├─ notifications/
│  └─ agents/
│
├─ docs/
│  ├─ protocol.md
│  ├─ api.md
│  ├─ security.md
│  └─ architecture.md
│
└─ README.md
```

建议单独抽一个协议层：

```text
hermes-protocol
```

这样以后可以支持：

```text
macOS App
iOS App
Web App
CLI
Raycast Extension
VS Code Extension
```

---

# 15. 最终架构图

```text
┌──────────────────────────────┐
│        macOS Client           │
│                              │
│  Menu Bar                    │
│  Floating Island             │
│  Chat Window                 │
│  Task Center                 │
│  Notification Center         │
└───────────────┬──────────────┘
                │
                │ REST / WebSocket / APNs
                ▼
┌──────────────────────────────┐
│        Hermes Gateway         │
│                              │
│  Auth                         │
│  Event Store                  │
│  WebSocket Hub                │
│  REST API                     │
│  Notification Service         │
│  Device Sync                  │
└───────────────┬──────────────┘
                │
                ▼
┌──────────────────────────────┐
│        Hermes Agent Layer     │
│                              │
│  Conversation Agent           │
│  Scheduled Task Agent         │
│  Tool Executor                │
│  Approval Gate                │
│  Long-running Job Worker      │
└───────────────┬──────────────┘
                │
                ▼
┌──────────────────────────────┐
│        Infrastructure         │
│                              │
│  PostgreSQL / SQLite          │
│  Redis / Queue                │
│  Object Storage               │
│  APNs                         │
│  Logs / Metrics               │
└──────────────────────────────┘
```

---

# 16. 最重要的设计原则

这个产品要守住五个原则：

```text
1. 原生优先
2. 实时优先
3. 低打扰
4. 安全确认
5. 断线可恢复
```

一句话总结：

> **Hermes Island 的核心不是“做一个 Mac 灵动岛”，而是做一个 Agent 时代的 macOS 原生任务通知与确认中枢。**

第一版只要把 **实时对话、任务状态、用户确认、系统通知、断线恢复** 做稳，这个产品就成立。

