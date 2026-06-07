# MVP Parallel Roadmap

## 1. 总体阶段

Hermes Island 的第一轮开发分为 5 个阶段。每个阶段都允许多个 Agent 并行推进，但必须按协议和集成顺序合并。

```text
Phase 0: Bootstrap
Phase 1: Protocol Foundation
Phase 2: MVP 0.1 Realtime Chat
Phase 3: MVP 0.2 Task Events
Phase 4: MVP 0.3 Approval Flow
```

## 2. Phase 0: Bootstrap

目标：

建立可协作的仓库骨架。

并行方式：

- A0 创建仓库基础、`.gitignore`、README、目录结构。
- A1 准备协议包目录和测试框架。
- A2 准备 Gateway 目录和本地启动脚本。
- A3 准备 macOS App 工程。
- A6 准备开发环境文档。

合并顺序：

1. A0 Bootstrap。
2. A1/A2/A3 各自骨架。
3. A6 文档和脚本。

验收：

- `main` 有推荐目录结构。
- `.worktrees/` 已被 git ignore。
- README 写明本地启动方式，即使部分命令标注为“对应模块完成后可用”。

## 3. Phase 1: Protocol Foundation

目标：

冻结 MVP 0.1-0.3 的事件协议，减少后续 Agent 反复改接口。

并行方式：

- A1 主导协议 schema 和示例。
- A2 基于草案实现 mock event producer。
- A4 基于草案准备 Swift Codable 类型。
- A6 准备契约测试输入样本。

关键交付：

- `EventEnvelope`。
- Client commands：`message.send`、`events.ack`。
- Message events。
- Task events。
- Approval events。
- Notification events。
- Agent status events。

验收：

- Gateway mock 和 Swift SDK 使用同一份示例事件。
- 事件样本能通过 schema 校验。
- 文档明确 `seq` 是用户维度单调递增序号。

## 4. Phase 2: MVP 0.1 Realtime Chat

目标：

证明 macOS App 可以稳定连接 Hermes Gateway 并完成流式对话。

并行方式：

- A2 实现 Gateway mock 登录、WebSocket、消息流。
- A4 实现 Swift SDK 连接、重连、去重、`last_seq`。
- A3 实现菜单栏和聊天窗口入口。
- A5 实现 Chat UI。
- A6 实现 smoke test。

端到端流程：

```text
用户打开菜单栏
↓
打开聊天窗口
↓
输入消息
↓
本地显示 sending
↓
Gateway 返回 message.accepted
↓
Gateway 流式推送 message.delta
↓
Gateway 返回 message.completed
↓
客户端显示 completed
```

验收：

- WebSocket 断开后自动重连。
- 重连后通过 `after_seq` 补拉遗漏事件。
- 重复事件不会重复追加消息。
- 发送消息有 `client_msg_id`，服务端确认后关联真实 `message_id`。

## 5. Phase 3: MVP 0.2 Task Events

目标：

证明 Agent 状态可以进入桌面。

并行方式：

- A1 补齐任务事件示例。
- A2 实现 mock task run。
- A4 将任务事件映射为本地状态。
- A5 实现 Island 任务状态和 Task Center。
- A6 补充任务事件 smoke。

端到端流程：

```text
Gateway 触发 task.started
↓
Island 短暂显示正在执行
↓
Gateway 推送 task.progress
↓
Task Center 更新进度
↓
Gateway 推送 task.completed 或 task.failed
↓
Island 显示结果
↓
必要时触发本地通知
```

验收：

- 普通消息不弹 Island。
- 任务开始、完成、失败能驱动 Island。
- 失败任务有重试入口，但第一版可只接 mock callback。
- Task Center 展示运行中、等待确认、已完成、失败。

## 6. Phase 4: MVP 0.3 Approval Flow

目标：

形成产品核心差异化：高危操作必须用户确认。

并行方式：

- A1 定义 approval schema。
- A2 实现 approval approve/reject API 和审计 mock。
- A4 实现 approval action client。
- A5 实现 Island Approval Panel。
- A6 补充确认流程验收。

端到端流程：

```text
Gateway 推送 task.requires_approval
↓
Island 保持展示确认请求
↓
用户点击允许或拒绝
↓
客户端调用 approval API
↓
Gateway 记录 device_id、decision、time
↓
Gateway 推送 task.progress 或 task.cancelled
```

验收：

- 确认请求不会因为普通消息被覆盖。
- 允许/拒绝按钮都走服务端 API。
- 超时后 UI 显示 expired。
- 审计字段至少包含 approval id、device id、decision、timestamp。

## 7. 推荐并行矩阵

| Phase | A1 Protocol | A2 Gateway | A3 Shell | A4 Realtime | A5 UI | A6 QA |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | package skeleton | server skeleton | app skeleton | sdk skeleton | mock views skeleton | scripts docs |
| 1 | schemas | mock producer | app state hooks | Codable models | mock state previews | contract fixtures |
| 2 | message refinements | websocket stream | chat route | reconnect/dedupe | chat UI | message smoke |
| 3 | task schemas | task mock | menu status | task state mapper | island/tasks UI | task smoke |
| 4 | approval schemas | approval APIs | command hooks | approval client | approval panel | approval smoke |

## 8. 不建议并行的事项

这些事项应由 Tech Lead 串行处理：

- 修改根目录构建系统。
- 修改 Xcode project 共享配置。
- 调整事件协议字段名。
- 重命名公共模块。
- 合并多个分支。
- 发布版本号。

## 9. MVP 1.0 收口任务

MVP 0.1-0.3 通过后，再安排一轮收口：

- 本地缓存。
- Notification Center 完整列表。
- 设置页。
- 开机启动。
- 错误状态与恢复。
- README 和安全文档。
- 打包签名说明。

