# Worktree Playbook

## 1. 目的

用 git worktree 让多个 Agent 同时开发同一项目，但每个 Agent 都在独立目录和独立分支中工作。这样能避免频繁切分支、减少本地状态互相污染，并让 Tech Lead 统一控制合并顺序。

## 2. 前置条件

当前项目目录还不是 Git 仓库。开始前先完成一次仓库初始化：

```bash
git init
printf ".worktrees/\n.DS_Store\n" >> .gitignore
git add ref.md docs .gitignore
git commit -m "docs: add hermes island planning docs"
```

确认 `.worktrees/` 被忽略：

```bash
git check-ignore -q .worktrees && echo "ignored"
```

预期输出：

```text
ignored
```

## 3. 目录约定

统一使用项目内隐藏目录：

```text
.worktrees/
```

命名格式：

```text
.worktrees/<agent-name>-<task-short-name>
```

示例：

```text
.worktrees/a1-protocol-foundation
.worktrees/a2-gateway-mvp
.worktrees/a3-macos-shell
.worktrees/a4-realtime-sdk
.worktrees/a5-island-ui
.worktrees/a6-e2e-smoke
```

## 4. 分支命名

格式：

```text
feature/<area>-<short-name>
fix/<area>-<short-name>
docs/<area>-<short-name>
test/<area>-<short-name>
```

示例：

```text
feature/protocol-foundation
feature/gateway-event-stream
feature/macos-menu-bar-shell
feature/swift-sdk-reconnect
feature/island-approval-panel
test/e2e-message-stream
```

## 5. 创建 worktree

从主仓库根目录执行：

```bash
git worktree add .worktrees/a1-protocol-foundation -b feature/protocol-foundation
```

进入 worktree：

```bash
cd .worktrees/a1-protocol-foundation
```

检查状态：

```bash
git status --short
git branch --show-current
```

预期：

```text
feature/protocol-foundation
```

## 6. Agent 开始任务前检查

每个 Agent 在开始前必须执行：

```bash
git status --short
git fetch --all --prune
git rebase main
```

如果还没有远程仓库，则跳过 `fetch`，但仍要从本地 `main` rebase：

```bash
git rebase main
```

## 7. 依赖安装策略

每个 worktree 独立安装依赖，避免共享构建产物造成隐性状态。

Node/TypeScript：

```bash
npm install
npm test
```

Swift Package：

```bash
swift test
```

Xcode/macOS App：

```bash
xcodebuild -scheme HermesIsland -destination 'platform=macOS' build
```

如果第一阶段还没有完整工程，Agent 必须在交付摘要中写明：

```text
验证限制：当前任务只创建文档/协议/骨架，尚无可运行 build target。
```

## 8. 文件所有权

为了并行开发，默认文件所有权如下：

| 路径 | Owner |
| --- | --- |
| `packages/hermes-protocol/` | A1 Protocol Agent |
| `docs/protocol.md` | A1 Protocol Agent |
| `server/gateway/` | A2 Gateway Agent |
| `docs/api.md` | A2 Gateway Agent |
| `apps/macos/MenuBar/` | A3 macOS Shell Agent |
| `apps/macos/Settings/` | A3 macOS Shell Agent |
| `apps/macos/Services/` | A4 Realtime Client Agent |
| `packages/hermes-swift-sdk/` | A4 Realtime Client Agent |
| `apps/macos/Island/` | A5 UI Flow Agent |
| `apps/macos/Chat/` | A5 UI Flow Agent |
| `apps/macos/Tasks/` | A5 UI Flow Agent |
| `apps/macos/Notifications/` | A5 UI Flow Agent |
| `scripts/` | A6 QA / Release Agent |
| `docs/agent-team/` | A0 Tech Lead / Integrator |

共享文件只能由 Tech Lead 改：

```text
README.md
package.json
Package.swift
apps/macos/HermesIslandApp.swift
apps/macos/HermesIsland.xcodeproj
```

如果 Agent 必须修改共享文件，先在交付摘要里标记：

```text
需要 Integrator 代改共享文件：<path>，原因：<reason>
```

## 9. 提交流程

每个 Agent 在 worktree 内完成任务后：

```bash
git status --short
git add <changed-files>
git commit -m "<type>: <short summary>"
```

提交信息类型：

```text
feat
fix
docs
test
refactor
build
chore
```

示例：

```bash
git commit -m "feat: add protocol event envelope schemas"
```

## 10. Agent 交付摘要模板

每个 Agent 完成后必须提交这段摘要：

```markdown
## Agent Delivery

Branch: `feature/protocol-foundation`
Worktree: `.worktrees/a1-protocol-foundation`
Owner: A1 Protocol Agent

Changed paths:
- `packages/hermes-protocol/`
- `docs/protocol.md`

Completed:
- Added event envelope schema.
- Added message/task/approval event examples.
- Added contract tests for required fields.

Verification:
- `npm test` PASS

Protocol changes:
- Added `message.accepted`, `message.delta`, `message.completed`.

Known limits:
- Swift Codable generation is not included in this branch.
```

## 11. 集成流程

Tech Lead 在主仓库执行：

```bash
git status --short
git checkout main
git merge --no-ff feature/protocol-foundation
```

合并后运行对应验证：

```bash
npm test
swift test
xcodebuild -scheme HermesIsland -destination 'platform=macOS' build
```

只运行已存在的验证命令。不存在的命令不要伪造通过结果。

## 12. 清理 worktree

分支合并后：

```bash
git worktree remove .worktrees/a1-protocol-foundation
git branch -d feature/protocol-foundation
```

如果分支还没合并，不要删除。

## 13. 冲突处理规则

冲突由 Tech Lead 处理，不让功能 Agent 自己猜。

优先级：

1. 保留已合并到 `main` 的协议与公共接口。
2. 保留通过验证的实现。
3. 对 UI 文案和样式冲突，优先保持一致性，不做新设计。
4. 对共享构建文件冲突，Tech Lead 手动整合后重新跑完整验证。

