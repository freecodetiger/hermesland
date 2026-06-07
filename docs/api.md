# Hermes Island Gateway API

Gateway MVP 0.1 exposes mock auth, in-memory event replay, ACK cursors, message stream generation, mock task runs, approval resolution, and SSE replay. The implementation is intentionally local-memory only: data resets when the process restarts.

## GET /healthz

Returns service health.

Response:

```json
{
  "status": "ok"
}
```

## POST /v1/auth/device/start

Starts a mock device login flow. This endpoint does not perform production authentication.

Response:

```json
{
  "device_code": "mock-device-code",
  "token": "mock-token"
}
```

## GET /v1/events?after_seq=N

Returns events with `seq` greater than `after_seq`. If `after_seq` is omitted, replay starts after `0`.

Response:

```json
{
  "events": [
    {
      "seq": 1,
      "event_id": "evt_000001",
      "type": "message.accepted",
      "created_at": "2026-06-08T00:00:00.000Z",
      "payload": {
        "conversation_id": "conv-1",
        "message_id": "msg_msg-1",
        "client_msg_id": "msg-1"
      }
    }
  ]
}
```

## POST /v1/events/ack

Stores the last event sequence acknowledged by a device.

Request:

```json
{
  "device_id": "device-a",
  "last_seq": 5
}
```

Response:

```json
{
  "device_id": "device-a",
  "last_seq": 5
}
```

## POST /v1/messages

Accepts a message and appends a mock stream of gateway events in this order:

1. `message.accepted`
2. At least three `message.delta` events
3. `message.completed`

Request:

```json
{
  "conversation_id": "conv-1",
  "client_msg_id": "msg-1",
  "content": "hello"
}
```

Response:

```json
{
  "accepted": true,
  "events": [
    {
      "seq": 1,
      "event_id": "evt_000001",
      "type": "message.accepted",
      "created_at": "2026-06-08T00:00:00.000Z",
      "payload": {
        "conversation_id": "conv-1",
        "message_id": "msg_msg-1",
        "client_msg_id": "msg-1"
      }
    }
  ]
}
```

## POST /v1/tasks/run

Starts a mock task run and appends protocol `EventEnvelope` events. The request `mode` controls the mocked outcome.

Request:

```json
{
  "mode": "success"
}
```

Success mode appends:

1. `task.started`
2. `task.progress`
3. `task.completed`

Response:

```json
{
  "task": {
    "task_id": "task_000001",
    "mode": "success",
    "status": "completed",
    "title": "Mock success task"
  },
  "events": [
    {
      "seq": 1,
      "event_id": "evt_000001",
      "type": "task.started",
      "created_at": "2026-06-08T00:00:00.000Z",
      "payload": {
        "task_id": "task_000001",
        "title": "Mock success task"
      }
    }
  ]
}
```

Failure mode appends `task.started` and `task.failed` with a safe error payload:

```json
{
  "mode": "failure"
}
```

```json
{
  "task": {
    "task_id": "task_000002",
    "mode": "failure",
    "status": "failed",
    "title": "Mock failure task"
  },
  "events": [
    {
      "seq": 2,
      "event_id": "evt_000002",
      "type": "task.failed",
      "created_at": "2026-06-08T00:00:00.000Z",
      "payload": {
        "task_id": "task_000002",
        "error": {
          "code": "MOCK_TASK_FAILED",
          "message": "Mock task failed safely."
        }
      }
    }
  ]
}
```

Approval mode appends `task.started` and `task.requires_approval`, then creates a pending approval record:

```json
{
  "mode": "approval"
}
```

```json
{
  "task": {
    "task_id": "task_000003",
    "mode": "approval",
    "status": "requires_approval",
    "title": "Mock approval task"
  },
  "approval": {
    "approval_id": "approval_000001",
    "task_id": "task_000003",
    "status": "pending",
    "prompt": "Approve mock task?",
    "actions": ["approve", "reject"]
  },
  "events": [
    {
      "seq": 3,
      "event_id": "evt_000003",
      "type": "task.requires_approval",
      "created_at": "2026-06-08T00:00:00.000Z",
      "payload": {
        "task_id": "task_000003",
        "approval_id": "approval_000001",
        "prompt": "Approve mock task?",
        "actions": ["approve", "reject"]
      }
    }
  ]
}
```

## GET /v1/tasks

Returns the current in-memory mock task state list.

Response:

```json
{
  "tasks": [
    {
      "task_id": "task_000001",
      "mode": "success",
      "status": "completed",
      "title": "Mock success task"
    },
    {
      "task_id": "task_000003",
      "mode": "approval",
      "status": "requires_approval",
      "title": "Mock approval task"
    }
  ]
}
```

## POST /v1/approvals/:id/approve

Approves a pending approval once. Approval appends `task.progress` and `task.completed`.

Response:

```json
{
  "approval": {
    "approval_id": "approval_000001",
    "task_id": "task_000003",
    "status": "approved",
    "prompt": "Approve mock task?",
    "actions": ["approve", "reject"]
  },
  "task": {
    "task_id": "task_000003",
    "mode": "approval",
    "status": "completed",
    "title": "Mock approval task"
  },
  "events": [
    {
      "seq": 4,
      "event_id": "evt_000004",
      "type": "task.progress",
      "created_at": "2026-06-08T00:00:00.000Z",
      "payload": {
        "task_id": "task_000003",
        "progress": 1,
        "message": "Approval granted."
      }
    },
    {
      "seq": 5,
      "event_id": "evt_000005",
      "type": "task.completed",
      "created_at": "2026-06-08T00:00:00.000Z",
      "payload": {
        "task_id": "task_000003",
        "result": "Mock task approved and completed."
      }
    }
  ]
}
```

If an approval has already been approved or rejected, the endpoint returns `409`:

```json
{
  "error": "approval_already_resolved",
  "approval_id": "approval_000001",
  "status": "approved"
}
```

## POST /v1/approvals/:id/reject

Rejects a pending approval once. Rejection appends `task.cancelled`.

Response:

```json
{
  "approval": {
    "approval_id": "approval_000002",
    "task_id": "task_000004",
    "status": "rejected",
    "prompt": "Approve mock task?",
    "actions": ["approve", "reject"]
  },
  "task": {
    "task_id": "task_000004",
    "mode": "approval",
    "status": "cancelled",
    "title": "Mock approval task"
  },
  "events": [
    {
      "seq": 6,
      "event_id": "evt_000006",
      "type": "task.cancelled",
      "created_at": "2026-06-08T00:00:00.000Z",
      "payload": {
        "task_id": "task_000004",
        "reason": "Approval rejected."
      }
    }
  ]
}
```

## GET /v1/realtime?after_seq=N

Streams replay events after `after_seq` as Server-Sent Events. For MVP 0.1 this endpoint replays currently stored events and closes the response; it does not hold the connection open for future events.

SSE event format:

```text
event: message.delta
data: {"event_id":"evt_000002","seq":2,"type":"message.delta","created_at":"2026-06-08T00:00:00.000Z","payload":{"conversation_id":"conv-1","message_id":"msg_msg-1","client_msg_id":"msg-1","delta":"Mock response part 1"}}
```
