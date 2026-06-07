# Architecture

## Product Position

Hermes Island is a lightweight macOS companion for Hermes Agent. The client should not directly connect to Agent workers. It connects to Hermes Gateway, which owns authentication, realtime events, replay, ACK, notifications, and audit records.

## Layers

```text
macOS Client
  Menu Bar
  Floating Island
  Chat Window
  Task Center
  Notification Center
  Realtime Services

Hermes Gateway
  Auth
  Event Store
  WebSocket Hub
  REST API
  Device Cursor
  Approval API

Hermes Agent Layer
  Conversation Agent
  Scheduled Task Agent
  Tool Executor
  Approval Gate

Infrastructure
  Database
  Queue
  Logs
  Metrics
  APNs later
```

## MVP Architecture Decisions

- Protocol-first development: Gateway, SDK, UI, and smoke tests consume the same event definitions.
- WebSocket handles realtime message and task events.
- REST handles login, event replay, ACK, task list, and approval decisions.
- Events are replayable by `after_seq`.
- Client dedupes by `event_id`.
- User approvals are server-side decisions; client buttons never bypass Gateway.

## Integration Order

1. Protocol.
2. Gateway mock.
3. Swift realtime SDK.
4. macOS shell.
5. UI flows.
6. Smoke tests and release docs.

