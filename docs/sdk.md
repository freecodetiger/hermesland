# Hermes Swift SDK

The Swift SDK foundation lives in `packages/hermes-swift-sdk` as a standalone
Swift Package. It is intentionally testable with Swift Package Manager and does
not require an Xcode project.

## Modules

- `EventEnvelope<Payload>` models the server event envelope from
  `docs/protocol.md`. It uses Swift-friendly property names while encoding and
  decoding protocol fields such as `event_id`, `created_at`, `message_id`, and
  `client_msg_id`.
- `EventType` contains the MVP server event type contract, including message,
  task, notification, agent presence, and system error events.
- Payload wrappers provide Codable structs for the current practical event
  shapes, including message payloads, task payloads, notifications, agent
  presence, and system errors. Message payloads include Gateway correlation
  fields such as `conversation_id`, `message_id`, and `client_msg_id` where the
  MVP stream emits them.
- Task payload wrappers decode Gateway-style `task.started`, `task.progress`,
  `task.completed`, `task.failed`, `task.cancelled`, and
  `task.requires_approval` envelopes. Approval requests expose `task_id`,
  `approval_id`, `prompt`, `actions`, and optional `expires_at`.
- `ApprovalDecisionRequest` is a lightweight Codable body for future approval
  approve/reject calls. It encodes `approval_id`, `task_id`, and `decision`
  using protocol field names; the SDK does not send it over the network yet.
- `EventDeduplicator` tracks processed `event_id` values and reports duplicate
  events as ignored.
- `LastSeqTracker` stores the last processed sequence number and only advances
  when a processed event has a greater `seq`.
- `ReconnectPolicy` returns retry delays `[1, 2, 5, 10, 30, 60]` and caps later
  attempts at 60 seconds.
- `KeychainTokenStore` is the token persistence abstraction for future secure
  storage implementations. `InMemoryTokenStore` is included for tests and local
  clients. The SDK does not use `UserDefaults`.
- `HermesEventProcessor` combines event deduplication and sequence tracking so
  callers can process envelopes through one lightweight stateful component.
- `HermesHTTPClient` is a small Foundation `URLSession` client for the mock
  Gateway REST API. It covers health checks, mock device auth start, message
  send, event replay, task run, and approval resolution. Event-returning
  methods decode `[EventEnvelope<JSONValue>]` so callers can inspect
  `event_id`, `seq`, `type`, `created_at`, and pragmatic JSON payload values
  without choosing a typed payload wrapper up front.

## HTTP Client Usage

Create the client with the Gateway base URL:

```swift
import Foundation
import HermesSwiftSDK

let client = HermesHTTPClient(baseURL: URL(string: "http://localhost:8787")!)

let health = try await client.health()
print(health.status) // "ok"

let auth = try await client.startDeviceAuth(
    deviceName: "Zoe's MacBook Pro",
    clientID: "macos-companion"
)
print(auth.deviceCode)
print(auth.token)
```

Send messages and replay events:

```swift
let messageEvents = try await client.sendMessage(
    conversationID: "conv-1",
    clientMessageID: UUID().uuidString,
    content: "Run the smoke test."
)

for event in messageEvents {
    print(event.eventID, event.seq, event.type, event.createdAt)
    if let messageID = event.payload.objectValue?["message_id"]?.stringValue {
        print(messageID)
    }
}

let replayedEvents = try await client.fetchEvents(afterSeq: 0)
```

Run mock tasks and resolve approval requests:

```swift
let taskEvents = try await client.runTask(mode: "approval")

let approvalEvents = try await client.resolveApproval(
    approvalID: "approval_000001",
    decision: .approve
)
```

Non-2xx responses throw `HermesHTTPError` with the HTTP status code and raw
UTF-8 response body. Custom transports can conform to `HermesHTTPTransport`,
which keeps tests and local clients independent from a live Gateway process.

## Current Limitations

- The package does not include WebSocket, SSE, or approval transport code yet.
- A platform Keychain-backed token store is not implemented yet; only the
  protocol and in-memory implementation exist.
- `HermesHTTPClient` does not attach authentication headers, refresh tokens, or
  persist the mock device auth token yet. Callers own token storage and request
  authorization policy for now.
- HTTP event payloads are decoded through `JSONValue` for inspection and replay.
  Use the typed payload wrappers when the event type is known and stricter
  payload shape is needed.
- Event payload wrappers cover the MVP contract and Gateway mock shape but do
  not validate semantic constraints such as non-negative progress or event type
  to payload matching.
- Event replay, acknowledgement command generation, and offline persistence are
  outside this foundation pass.

## Verification

Run the Swift package tests directly:

```sh
cd packages/hermes-swift-sdk
swift test
```
