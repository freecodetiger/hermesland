# Hermes Island Gateway API

Gateway MVP 0.1 exposes mock auth, in-memory event replay, ACK cursors, message stream generation, and SSE replay. The implementation is intentionally local-memory only: data resets when the process restarts.

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

## GET /v1/realtime?after_seq=N

Streams replay events after `after_seq` as Server-Sent Events. For MVP 0.1 this endpoint replays currently stored events and closes the response; it does not hold the connection open for future events.

SSE event format:

```text
event: message.delta
data: {"event_id":"evt_000002","seq":2,"type":"message.delta","created_at":"2026-06-08T00:00:00.000Z","payload":{"conversation_id":"conv-1","message_id":"msg_msg-1","client_msg_id":"msg-1","delta":"Mock response part 1"}}
```
