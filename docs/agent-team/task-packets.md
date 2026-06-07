# Agent Task Packets

## 1. 使用方式

每个任务包对应一个 worktree 和一个分支。Agent 不应跨任务包修改无关文件。Tech Lead 可以直接复制任务包内容作为 Agent 指令。

## 2. P0-001 Repository Bootstrap

Owner：A0 Tech Lead / Integrator

Branch：

```text
chore/repository-bootstrap
```

Worktree：

```text
.worktrees/a0-repository-bootstrap
```

Files：

```text
.gitignore
README.md
apps/.gitkeep
packages/.gitkeep
server/.gitkeep
scripts/.gitkeep
docs/architecture.md
docs/security.md
```

Tasks：

- Initialize Git if needed.
- Add `.worktrees/` to `.gitignore`.
- Create monorepo directories.
- Write README with current MVP scope and module commands.
- Add architecture and security placeholders with concrete MVP requirements from `ref.md`.

Verification：

```bash
git check-ignore -q .worktrees && echo "ignored"
git status --short
```

Expected：

```text
ignored
```

## 3. P1-001 Protocol Foundation

Owner：A1 Protocol Agent

Branch：

```text
feature/protocol-foundation
```

Worktree：

```text
.worktrees/a1-protocol-foundation
```

Files：

```text
packages/hermes-protocol/
docs/protocol.md
```

Tasks：

- Define `EventEnvelope`.
- Define client commands.
- Define message events.
- Define task events.
- Define approval events.
- Define notification and agent status events.
- Add JSON examples for every event.
- Add contract tests for required fields.

Acceptance：

- Every server event has `event_id`, `seq`, `type`, `created_at`, `payload`.
- `seq` is documented as user-scoped monotonic integer.
- `event_id` is documented as idempotency key for dedupe.
- `message.send` contains `client_msg_id`.

Verification：

```bash
npm test
```

If no package test runner exists yet, Agent must add one inside `packages/hermes-protocol/`.

## 4. P1-002 Gateway Mock Stream

Owner：A2 Gateway Agent

Branch：

```text
feature/gateway-mock-stream
```

Worktree：

```text
.worktrees/a2-gateway-mock-stream
```

Files：

```text
server/gateway/
docs/api.md
```

Tasks：

- Create Gateway service skeleton.
- Add `GET /healthz`.
- Add `POST /v1/auth/device/start` mock.
- Add `GET /v1/events?after_seq=<seq>`.
- Add `POST /v1/events/ack`.
- Add `WS /v1/realtime?after_seq=<seq>`.
- Add mock stream for one user message.

Acceptance：

- WebSocket emits `message.accepted`, at least 3 `message.delta`, then `message.completed`.
- `after_seq` controls replay.
- ACK updates an in-memory cursor.

Verification：

```bash
npm test
npm run dev
```

## 5. P2-001 macOS App Shell

Owner：A3 macOS Shell Agent

Branch：

```text
feature/macos-app-shell
```

Worktree：

```text
.worktrees/a3-macos-app-shell
```

Files：

```text
apps/macos/
apps/macos/MenuBar/
apps/macos/Settings/
```

Tasks：

- Create macOS App target.
- Add menu bar entry.
- Add routes for Chat, Tasks, Notifications, Settings.
- Add `AppConnectionState`.
- Add mock state controls for local previews.

Acceptance：

- App builds.
- Menu bar menu opens.
- Menu items open corresponding windows or panels.
- Connection status text can show offline, connecting, online, running, needs approval, error.

Verification：

```bash
xcodebuild -scheme HermesIsland -destination 'platform=macOS' build
```

## 6. P2-002 Swift Realtime SDK

Owner：A4 Realtime Client Agent

Branch：

```text
feature/swift-realtime-sdk
```

Worktree：

```text
.worktrees/a4-swift-realtime-sdk
```

Files：

```text
packages/hermes-swift-sdk/
apps/macos/Services/
```

Tasks：

- Create Swift SDK package or app service module.
- Implement REST client abstraction.
- Implement WebSocket connection abstraction.
- Implement reconnect policy.
- Implement event deduplicator.
- Implement `last_seq` tracking.
- Implement Keychain token store abstraction.

Acceptance：

- Duplicate `event_id` is ignored.
- `last_seq` advances only after accepted event processing.
- reconnect policy follows 1s, 2s, 5s, 10s, 30s, 60s cap.
- token storage interface does not use UserDefaults.

Verification：

```bash
swift test
```

## 7. P2-003 Chat UI

Owner：A5 UI Flow Agent

Branch：

```text
feature/chat-ui
```

Worktree：

```text
.worktrees/a5-chat-ui
```

Files：

```text
apps/macos/Chat/
```

Tasks：

- Build conversation list placeholder.
- Build message stream.
- Build input box.
- Add sending, accepted, streaming, completed, failed, cancelled visual states.
- Add mock streaming preview.

Acceptance：

- User message appears immediately as sending.
- Accepted state maps local `client_msg_id` to server `message_id`.
- Assistant response appends deltas without duplicating text.
- Failed message shows retry action.

Verification：

```bash
xcodebuild -scheme HermesIsland -destination 'platform=macOS' build
```

## 8. P3-001 Task Events Gateway

Owner：A2 Gateway Agent

Branch：

```text
feature/gateway-task-events
```

Worktree：

```text
.worktrees/a2-gateway-task-events
```

Files：

```text
server/gateway/
docs/api.md
```

Tasks：

- Add mock task run endpoint.
- Emit `task.started`.
- Emit `task.progress`.
- Emit `task.completed`.
- Emit `task.failed` for failure scenario.
- Add `GET /v1/tasks`.

Acceptance：

- Task event stream uses monotonically increasing `seq`.
- Task list reflects current mock task states.
- Failed task includes safe error summary.

Verification：

```bash
npm test
```

## 9. P3-002 Island And Task Center

Owner：A5 UI Flow Agent

Branch：

```text
feature/island-task-center
```

Worktree：

```text
.worktrees/a5-island-task-center
```

Files：

```text
apps/macos/Island/
apps/macos/Tasks/
apps/macos/Notifications/
```

Tasks：

- Build Island compact state.
- Build Island expanded state.
- Build Task Center list.
- Build Notification list.
- Map task events to UI state using mock view models.

Acceptance：

- `task.started` displays compact running Island.
- `task.progress` updates progress in Task Center.
- `task.completed` displays completion Island briefly.
- `task.failed` displays failure state and notification.

Verification：

```bash
xcodebuild -scheme HermesIsland -destination 'platform=macOS' build
```

## 10. P4-001 Approval API

Owner：A2 Gateway Agent

Branch：

```text
feature/gateway-approval-api
```

Worktree：

```text
.worktrees/a2-gateway-approval-api
```

Files：

```text
server/gateway/
docs/api.md
```

Tasks：

- Emit `task.requires_approval`.
- Add `POST /v1/approvals/:id/approve`.
- Add `POST /v1/approvals/:id/reject`.
- Store mock audit record.
- Emit follow-up task event after decision.

Acceptance：

- Approval cannot be resolved twice.
- Approve emits follow-up progress or completed event.
- Reject emits cancellation event.
- Audit record includes approval id, device id, decision, timestamp.

Verification：

```bash
npm test
```

## 11. P4-002 Approval Panel

Owner：A5 UI Flow Agent

Branch：

```text
feature/island-approval-panel
```

Worktree：

```text
.worktrees/a5-island-approval-panel
```

Files：

```text
apps/macos/Island/
apps/macos/Tasks/
```

Tasks：

- Add persistent Island state for `task.requires_approval`.
- Add approve/reject buttons.
- Add view details action.
- Add expired state.
- Wire callbacks to Realtime Client approval API.

Acceptance：

- Approval Island is not replaced by ordinary message events.
- Approve and reject show pending state while request is in flight.
- Failed approval action shows retryable error.
- Expired approval disables approve/reject.

Verification：

```bash
xcodebuild -scheme HermesIsland -destination 'platform=macOS' build
```

## 12. P4-003 E2E Smoke

Owner：A6 QA / Release Agent

Branch：

```text
test/e2e-smoke
```

Worktree：

```text
.worktrees/a6-e2e-smoke
```

Files：

```text
scripts/
docs/agent-team/acceptance-checklist.md
```

Tasks：

- Add script to start Gateway mock.
- Add smoke for message stream.
- Add smoke for task event stream.
- Add smoke for approval approve/reject.
- Add manual macOS checklist.

Acceptance：

- Smoke verifies event order.
- Smoke verifies `seq` increases.
- Smoke verifies duplicate event handling if SDK hook is available.
- Checklist covers menu bar, chat, Island, task center, notification center, settings.

Verification：

```bash
npm run smoke
```

