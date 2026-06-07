# Acceptance Checklist

## 1. Repository

- [ ] `.worktrees/` is ignored by Git.
- [ ] `main` builds after every merge.
- [ ] README explains local setup.
- [ ] Each module has an owner.
- [ ] Shared files are only modified by A0 Tech Lead / Integrator.

## 2. Protocol

- [ ] Every server event has `event_id`.
- [ ] Every server event has monotonically increasing user-scoped `seq`.
- [ ] Every server event has `type`.
- [ ] Every server event has `created_at`.
- [ ] Every server event has `payload`.
- [ ] `message.send` has `client_msg_id`.
- [ ] `events.ack` supports batched ACK by `last_seq`.
- [ ] `task.requires_approval` has approval id and expiry.

## 3. Gateway

- [ ] `GET /healthz` returns success.
- [ ] Device login mock returns a short-lived token.
- [ ] WebSocket accepts `after_seq`.
- [ ] REST event replay accepts `after_seq`.
- [ ] Gateway can emit message stream events in order.
- [ ] Gateway can emit task progress events in order.
- [ ] Gateway can emit approval request events.
- [ ] Approval approve/reject cannot be applied twice.
- [ ] ACK updates device cursor.

## 4. macOS App Shell

- [ ] App launches as a menu bar app.
- [ ] Menu shows connection status.
- [ ] Menu can open Chat.
- [ ] Menu can open Tasks.
- [ ] Menu can open Notifications.
- [ ] Menu can open Settings.
- [ ] App can show offline, connecting, online, running, needs approval, error.

## 5. Realtime Client

- [ ] WebSocket connects to Gateway.
- [ ] WebSocket reconnects with backoff.
- [ ] Reconnect sends or uses `last_seq`.
- [ ] Duplicate `event_id` is ignored.
- [ ] `last_seq` persists across reconnect in the current app session.
- [ ] Token storage uses Keychain abstraction.
- [ ] Access token is not logged.

## 6. Chat

- [ ] User message appears immediately.
- [ ] `message.accepted` maps `client_msg_id` to `message_id`.
- [ ] `message.delta` appends text.
- [ ] `message.completed` marks response complete.
- [ ] `message.failed` shows error and retry.
- [ ] Duplicate delta event does not duplicate visible text.

## 7. Island

- [ ] Normal chat messages do not open Island.
- [ ] `task.started` opens compact running state.
- [ ] `task.progress` updates progress.
- [ ] `task.completed` shows short completion state.
- [ ] `task.failed` shows failure state and notification.
- [ ] `task.requires_approval` stays visible until handled or expired.
- [ ] Island does not steal keyboard focus unexpectedly.

## 8. Task Center

- [ ] Shows running tasks.
- [ ] Shows waiting approval tasks.
- [ ] Shows completed tasks.
- [ ] Shows failed tasks.
- [ ] Task detail shows latest log summary.
- [ ] Cancel and retry actions are visible where supported.

## 9. Notifications

- [ ] App has internal notification list.
- [ ] Task failure creates notification.
- [ ] Approval request creates notification.
- [ ] Long task completion creates notification.
- [ ] Notification marks read state.
- [ ] Sensitive content is not shown in system notification body by default.

## 10. Approval Flow

- [ ] Approval panel shows action title and summary.
- [ ] Approve calls service API.
- [ ] Reject calls service API.
- [ ] Pending state prevents double click.
- [ ] Expired approval disables action buttons.
- [ ] Audit record contains device id, decision, timestamp.

## 11. Release Readiness

- [ ] Local mock demo can be run from README.
- [ ] Smoke test covers message stream.
- [ ] Smoke test covers task stream.
- [ ] Smoke test covers approval flow.
- [ ] Known limitations are documented.
- [ ] APNs is explicitly marked as post-MVP if not implemented.

