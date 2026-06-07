# Hermes Island Agent Team Development Plan

> 基于 `ref.md`。目标是用多个 Agent 在不同 git worktree 中并行开发 Hermes Island，并让每个分支都能独立构建、测试、评审、合并。

## 1. 结论

Hermes Island 应按“协议先行、客户端体验、Gateway 能力、可靠性验证”拆成多个互不抢文件的开发流。每个 Agent 绑定一个长期职责域和一个短周期任务包，通过独立 worktree 开发，按集成顺序合并到 `main`。

第一轮建议不要把所有 MVP 1.0 功能同时开工。先做 MVP 0.1 的端到端通信骨架，再并行推进任务事件、Island UI、任务中心、确认流程。

## 2. 产品 MVP 边界

来自 `ref.md` 的首批落地目标：

- macOS 菜单栏 App。
- 顶部 Island 悬浮面板。
- 实时聊天与流式回复。
- Hermes Gateway 的 REST + WebSocket 接入。
- 统一事件协议：`event_id`、`seq`、`type`、`payload`。
- 任务状态事件：开始、进度、完成、失败、取消。
- 用户确认事件：`task.requires_approval`。
- 断线重连、事件补拉、去重、ACK。
- Keychain token 存储。
- 本地通知与 App 内通知列表。

暂缓到 MVP 1.1+：

- APNs。
- 插件市场。
- 团队权限系统。
- 知识库 RAG。
- 多模型管理。
- 复杂工作流编排。
- 本地大模型。

## 3. 推荐仓库结构

第一轮落地建议采用 monorepo，方便 Agent Team 在一个仓库内通过路径边界协作。

```text
hermesiland/
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
├─ packages/
│  ├─ hermes-protocol/
│  └─ hermes-swift-sdk/
├─ server/
│  └─ gateway/
├─ docs/
│  ├─ architecture.md
│  ├─ protocol.md
│  ├─ api.md
│  ├─ security.md
│  └─ agent-team/
├─ scripts/
└─ README.md
```

推荐技术栈：

- macOS：Swift、SwiftUI、AppKit、MenuBarExtra 或 NSStatusItem、NSPanel、URLSessionWebSocketTask、UserNotifications、Keychain、SQLite 或 SwiftData。
- Gateway：TypeScript + Node.js + Fastify/NestJS，或 Swift/Vapor。若目标是快速并行开发和 mock，优先 TypeScript。
- 协议包：TypeScript JSON Schema 作为源，生成或手写 Swift Codable 类型。
- 测试：Swift XCTest、Node test runner/Vitest、协议契约测试。

## 4. 并行开发原则

这里的“并行”不是同一个任务内的并发编码，而是多个 Agent 在不同 worktree 里各自推进可合并的垂直任务。

核心规则：

- 一个 Agent 一次只拥有一个 worktree。
- 一个 worktree 一次只解决一个任务包。
- 每个任务包必须有清晰文件边界，避免多个 Agent 同时改同一文件。
- 协议变更必须先走 `packages/hermes-protocol`，再让客户端和服务端消费。
- `main` 始终保持可构建。
- 合并顺序由 Tech Lead 控制，不允许多个 Agent 同时直接合并。
- 每个 PR 或分支必须附带验证命令和结果。

## 5. Agent Team 拆分

建议第一阶段配置 7 个角色：

| Agent | 职责域 | 主要路径 |
| --- | --- | --- |
| A0 Tech Lead / Integrator | 架构、接口冻结、合并、冲突处理 | 全仓库，只在集成时修改 |
| A1 Protocol Agent | 事件协议、JSON Schema、示例事件、契约测试 | `packages/hermes-protocol/`, `docs/protocol.md` |
| A2 Gateway Agent | REST、WebSocket、事件存储、ACK、补拉 | `server/gateway/`, `docs/api.md` |
| A3 macOS Shell Agent | App 骨架、菜单栏、窗口路由、设置入口 | `apps/macos/HermesIslandApp.swift`, `apps/macos/MenuBar/`, `apps/macos/Settings/` |
| A4 Realtime Client Agent | Swift SDK、WebSocket、重连、去重、Keychain | `packages/hermes-swift-sdk/`, `apps/macos/Services/` |
| A5 UI Flow Agent | Island、Chat、Tasks、Notifications UI | `apps/macos/Island/`, `apps/macos/Chat/`, `apps/macos/Tasks/`, `apps/macos/Notifications/` |
| A6 QA / Release Agent | E2E 脚本、mock server、验收清单、打包说明 | `scripts/`, `docs/`, test paths |

详见 [agent-roles.md](./agent-roles.md)。

## 6. Worktree 策略

本项目当前只有 `ref.md`，还不是 Git 仓库。开始 Agent Team 开发前，先执行一次初始化：

```bash
git init
printf ".worktrees/\n.DS_Store\n" >> .gitignore
git add ref.md docs .gitignore
git commit -m "docs: add hermes island planning docs"
```

之后所有 Agent 使用 `.worktrees/<branch>`：

```bash
git worktree add .worktrees/agent-protocol -b feature/protocol-foundation
git worktree add .worktrees/agent-gateway -b feature/gateway-mvp
git worktree add .worktrees/agent-macos-shell -b feature/macos-shell
```

详见 [worktree-playbook.md](./worktree-playbook.md)。

## 7. 第一轮执行顺序

推荐 5 个阶段：

1. Bootstrap：仓库初始化、基础目录、README、构建脚本、CI 占位。
2. Protocol First：事件 envelope、消息事件、任务事件、确认事件、JSON 示例。
3. MVP 0.1：Gateway mock + macOS 发送消息 + WebSocket 流式回复 + 重连。
4. MVP 0.2：任务事件、Island 状态、本地通知、任务详情。
5. MVP 0.3：确认请求、允许/拒绝、审计记录、超时与重试。

详见 [mvp-parallel-roadmap.md](./mvp-parallel-roadmap.md) 和 [task-packets.md](./task-packets.md)。

## 8. 每日协作节奏

每个开发日建议按固定节奏运行：

```text
09:30  Tech Lead 更新接口冻结状态和当日任务包
10:00  各 Agent 从 main rebase 自己 worktree
10:15  Agent 独立开发
15:30  Agent 提交验证结果和 PR 摘要
16:00  Tech Lead 集成顺序评审
17:00  合并可通过验证的分支
17:30  QA Agent 跑端到端 smoke
```

每个 Agent 的交付信息必须包含：

- 分支名。
- 改动路径。
- 完成功能。
- 验证命令。
- 已知限制。
- 是否修改协议。

## 9. 合并顺序

一个功能波次中，合并顺序固定：

1. 协议与文档。
2. Gateway mock 或服务端契约实现。
3. Swift SDK。
4. macOS App 壳和状态管理。
5. UI 页面。
6. E2E 验证脚本。

这样可以减少冲突，并避免 UI 或客户端先绑定未稳定协议。

## 10. 成功标准

第一轮 Agent Team 开发完成时，应满足：

- 从 `main` clone 后能按 README 启动 mock Gateway 和 macOS App。
- macOS App 可以完成设备码 mock 登录。
- 用户输入消息后，本地立即显示，服务端返回 `message.accepted`，随后流式显示 `message.delta`，最终 `message.completed`。
- WebSocket 断开后自动重连，并通过 `last_seq` 补拉事件。
- 至少支持一个 `task.requires_approval` mock 场景，Island 展示允许/拒绝。
- 所有事件处理具备 `event_id` 去重。
- 所有 token 类数据通过 Keychain abstraction，不落明文配置。

