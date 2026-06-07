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
  presence, and system errors.
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

## Current Limitations

- The package does not include WebSocket or SSE transport code yet.
- A platform Keychain-backed token store is not implemented yet; only the
  protocol and in-memory implementation exist.
- Event payload wrappers cover the MVP contract but do not validate semantic
  constraints such as non-negative progress or event type to payload matching.
- Event replay, acknowledgement command generation, and offline persistence are
  outside this foundation pass.

## Verification

Run the Swift package tests directly:

```sh
cd packages/hermes-swift-sdk
swift test
```
