# Hermes Agent API Server Adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect Hermes Island to the deployed Hermes Agent `api_server` gateway while preserving the existing UI event model and mock Gateway test surface.

**Architecture:** Add a separate Swift SDK client for Hermes Agent's OpenAI-compatible API server, then normalize `/v1/runs` and SSE lifecycle events into the existing `EventEnvelope<JSONValue>` / `HermesUIEvent` pipeline. Keep the current `HermesHTTPClient` for the local mock Gateway so mock contract tests remain stable.

**Tech Stack:** Swift 6, SwiftPM, Foundation `URLSession`, existing `HermesSwiftSDK`, existing `HermesIslandCompanionCore`, Hermes Agent `api_server` endpoints over HTTP plus SSE.

---

## Current Facts

Verified in `docs/hermes-agent-gateway-integration.md`:

- The deployed Hermes Agent server exposes Python `api_server`, not the Hermes Island mock Gateway.
- Development access should use SSH tunnel:

```bash
SSHPASS='706nb' sshpass -e ssh -N \
  -L 8650:172.17.0.1:8650 \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/hermesland_known_hosts \
  -o ExitOnForwardFailure=yes \
  nb706@1.95.80.155
```

- Local tunneled base URL: `http://127.0.0.1:8650`
- Health route: `GET /health`
- Model route: `GET /v1/models`
- Capabilities route: `GET /v1/capabilities`
- Run route: `POST /v1/runs`
- Run status route: `GET /v1/runs/{run_id}`
- Run event stream: `GET /v1/runs/{run_id}/events`
- Stop route: `POST /v1/runs/{run_id}/stop`
- `/v1/*` routes require `Authorization: Bearer <API_SERVER_KEY>`.

The existing Hermes Island mock Gateway client targets:

- `GET /healthz`
- `POST /v1/auth/device/start`
- `POST /v1/messages`
- `GET /v1/events`
- `POST /v1/tasks/run`
- `POST /v1/approvals/{id}/approve`

Do not repoint the existing mock Gateway client directly at Hermes Agent. The contracts are different.

## Target Runtime Flow

```text
macOS companion or menu bar
  -> HermesAgentLiveDemo / future app service
  -> HermesAgentAPIClient
  -> POST /v1/runs
  -> GET /v1/runs/{run_id}/events SSE
  -> HermesAgentEventNormalizer
  -> EventEnvelope<JSONValue>
  -> HermesUIStateReducer
```

For development:

```text
macOS localhost:8650
  -> SSH tunnel
  -> server 172.17.0.1:8650
  -> Hermes Agent api_server
```

For production later:

```text
macOS HTTPS URL
  -> Caddy TLS reverse proxy
  -> server 172.17.0.1:8650
  -> Hermes Agent api_server
```

## Event Mapping

Hermes Agent `/v1/runs` starts an asynchronous run:

```json
{
  "run_id": "run_abc",
  "status": "started"
}
```

Hermes Agent `/v1/runs/{run_id}/events` streams SSE lines where each `data:` payload is a JSON object. Known payloads from source inspection:

```json
{
  "event": "message.delta",
  "run_id": "run_abc",
  "timestamp": 1780882986.0,
  "delta": "partial text"
}
```

```json
{
  "event": "run.completed",
  "run_id": "run_abc",
  "timestamp": 1780882986.0,
  "output": "final response",
  "usage": {
    "input_tokens": 1,
    "output_tokens": 2,
    "total_tokens": 3
  }
}
```

Normalize to Hermes Island events:

| Hermes Agent event | Hermes Island event | Payload |
| --- | --- | --- |
| POST `/v1/runs` accepted | `task.started` | `task_id = run_id`, title from prompt |
| POST `/v1/runs` accepted | `message.accepted` | `message_id = run_id`, `client_msg_id` from caller |
| `message.delta` | `message.delta` | `message_id = run_id`, `delta` |
| `run.completed` | `message.completed` | `message_id = run_id`, `text = output` |
| `run.completed` | `task.completed` | `task_id = run_id`, `result = output` |
| `run.completed` | `notification.created` | title `Task completed`, body summary |
| `run.failed` | `task.failed` | `task_id = run_id`, `error.message` |
| `run.failed` | `system.error` | `error.code = HERMES_AGENT_RUN_FAILED` |
| `run.cancelled` | `task.cancelled` | `task_id = run_id`, reason |
| tool progress event | `task.progress` | `task_id = run_id`, message from tool label/status |

Approval support is a follow-up after inspecting real approval-shaped events from Hermes Agent. The first adapter milestone must not invent approval endpoints because the deployed API server exposes stop/status/events, not the mock Gateway approval API.

## Environment Contract

Add these environment variables for local live runs:

```bash
export HERMES_AGENT_GATEWAY_URL="http://127.0.0.1:8650"
export HERMES_AGENT_API_KEY="<loaded from server .env, never committed>"
export HERMES_AGENT_MODEL="hermes-zpc"
export HERMES_AGENT_SESSION_ID="hermes-island-dev"
```

Recommended helper to load the API key without printing it:

```bash
export HERMES_AGENT_API_KEY="$(
  SSHPASS='706nb' sshpass -e ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/tmp/hermesland_known_hosts \
    nb706@1.95.80.155 \
    'bash -lc '"'"'source /home/nb706/zpc/.hermes/.env; printf %s "$API_SERVER_KEY"'"'"''
)"
```

## File Structure

Create:

- `packages/hermes-swift-sdk/Sources/HermesSwiftSDK/HermesAgentAPIClient.swift`
  - Real Hermes Agent API server client.
  - Owns Bearer auth, `/health`, `/v1/models`, `/v1/capabilities`, `/v1/runs`, run status, stop.

- `packages/hermes-swift-sdk/Sources/HermesSwiftSDK/HermesAgentSSEParser.swift`
  - Converts raw SSE bytes/text chunks into JSON payload objects.
  - Ignores comments such as `: keepalive`.

- `packages/hermes-swift-sdk/Sources/HermesSwiftSDK/HermesAgentEventNormalizer.swift`
  - Converts Hermes Agent run responses and SSE payloads into `EventEnvelope<JSONValue>`.
  - Owns local sequence allocation for a single live stream.

- `packages/hermes-swift-sdk/Tests/HermesSwiftSDKTests/HermesAgentAPIClientTests.swift`
  - Request path, auth header, body, error handling.

- `packages/hermes-swift-sdk/Tests/HermesSwiftSDKTests/HermesAgentSSEParserTests.swift`
  - SSE data/comment/multi-event parsing.

- `packages/hermes-swift-sdk/Tests/HermesSwiftSDKTests/HermesAgentEventNormalizerTests.swift`
  - Mapping table coverage.

- `apps/macos/Sources/HermesIslandCompanionCore/HermesAgentLiveDemo.swift`
  - Companion demo flow against real Hermes Agent API server.

- `apps/macos/Tests/HermesIslandCompanionTests/HermesAgentLiveDemoTests.swift`
  - End-to-end mocked transport test for UI state reduction.

Modify:

- `apps/macos/Sources/HermesIslandCompanion/main.swift`
  - Add `agent-live` command.

- `apps/macos/README.md`
  - Document SSH tunnel and `agent-live`.

- `docs/hermes-agent-gateway-integration.md`
  - Link back to this plan after implementation starts.

Do not modify in the first milestone:

- `server/gateway/src/server.mjs`
- `docs/api.md`
- Existing mock Gateway tests
- Existing `HermesHTTPClient` mock Gateway methods

## Task 1: Hermes Agent API Models And Request Auth

**Files:**

- Create: `packages/hermes-swift-sdk/Sources/HermesSwiftSDK/HermesAgentAPIClient.swift`
- Test: `packages/hermes-swift-sdk/Tests/HermesSwiftSDKTests/HermesAgentAPIClientTests.swift`

- [ ] **Step 1: Write failing client tests**

Create `HermesAgentAPIClientTests.swift` with tests equivalent to:

```swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import HermesSwiftSDK

struct HermesAgentAPIClientTests {
    @Test func healthUsesAgentHealthPathWithoutAuthRequirement() async throws {
        let transport = TestHTTPTransport { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/health")
            return TestHTTPResponse(body: #"{"status":"ok","platform":"hermes-agent"}"#)
        }
        let client = HermesAgentAPIClient(
            baseURL: URL(string: "http://agent.test")!,
            apiKey: "secret",
            transport: transport
        )

        let health = try await client.health()

        #expect(health.status == "ok")
        #expect(health.platform == "hermes-agent")
    }

    @Test func modelsSendsBearerTokenAndDecodesModelID() async throws {
        let transport = TestHTTPTransport { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/v1/models")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
            return TestHTTPResponse(body: """
            {"object":"list","data":[{"id":"hermes-zpc","object":"model","created":1,"owned_by":"hermes","permission":[],"root":"hermes-zpc","parent":null}]}
            """)
        }
        let client = HermesAgentAPIClient(
            baseURL: URL(string: "http://agent.test")!,
            apiKey: "secret",
            transport: transport
        )

        let models = try await client.models()

        #expect(models.data.map(\\.id) == ["hermes-zpc"])
    }

    @Test func startRunPostsInputAndSessionHeader() async throws {
        let transport = TestHTTPTransport { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/runs")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
            #expect(request.value(forHTTPHeaderField: "X-Hermes-Session-Id") == "session-1")
            let body = try request.jsonBody()
            #expect(body["model"] as? String == "hermes-zpc")
            #expect(body["input"] as? String == "hello")
            return TestHTTPResponse(body: #"{"run_id":"run_123","status":"started"}"#, statusCode: 202)
        }
        let client = HermesAgentAPIClient(
            baseURL: URL(string: "http://agent.test")!,
            apiKey: "secret",
            transport: transport
        )

        let run = try await client.startRun(
            input: "hello",
            model: "hermes-zpc",
            sessionID: "session-1"
        )

        #expect(run.runID == "run_123")
        #expect(run.status == "started")
    }
}
```

Reuse the existing private `TestHTTPTransport` pattern from `HermesHTTPClientTests.swift`.

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
cd packages/hermes-swift-sdk
swift test --filter HermesAgentAPIClientTests
```

Expected: compile fails because `HermesAgentAPIClient` and response models do not exist.

- [ ] **Step 3: Implement minimal client**

Create `HermesAgentAPIClient.swift` with public response models:

```swift
public struct HermesAgentHealthResponse: Codable, Equatable {
    public let status: String
    public let platform: String?
}

public struct HermesAgentModelsResponse: Codable, Equatable {
    public let object: String
    public let data: [HermesAgentModel]
}

public struct HermesAgentModel: Codable, Equatable {
    public let id: String
    public let object: String
    public let created: Int64?
    public let ownedBy: String?
    public let root: String?
    public let parent: String?

    private enum CodingKeys: String, CodingKey {
        case id, object, created, root, parent
        case ownedBy = "owned_by"
    }
}

public struct HermesAgentRunResponse: Codable, Equatable {
    public let runID: String
    public let status: String

    private enum CodingKeys: String, CodingKey {
        case runID = "run_id"
        case status
    }
}
```

Implement methods:

```swift
public final class HermesAgentAPIClient {
    public init(baseURL: URL, apiKey: String, transport: HermesHTTPTransport = URLSession.shared)
    public func health() async throws -> HermesAgentHealthResponse
    public func models() async throws -> HermesAgentModelsResponse
    public func capabilities() async throws -> JSONValue
    public func startRun(input: String, model: String, sessionID: String?) async throws -> HermesAgentRunResponse
    public func runStatus(runID: String) async throws -> JSONValue
    public func stopRun(runID: String) async throws -> HermesAgentRunResponse
}
```

Request rules:

- `GET /health` does not require auth but may include no auth header.
- `/v1/*` requests must include `Authorization: Bearer <apiKey>`.
- `startRun` must include JSON `{"input":"...","model":"..."}`.
- If `sessionID` is non-empty, set `X-Hermes-Session-Id`.
- Non-2xx responses throw existing `HermesHTTPError`.

- [ ] **Step 4: Run tests to verify pass**

Run:

```bash
cd packages/hermes-swift-sdk
swift test --filter HermesAgentAPIClientTests
```

Expected: all `HermesAgentAPIClientTests` pass.

- [ ] **Step 5: Commit**

```bash
git add packages/hermes-swift-sdk/Sources/HermesSwiftSDK/HermesAgentAPIClient.swift \
  packages/hermes-swift-sdk/Tests/HermesSwiftSDKTests/HermesAgentAPIClientTests.swift
git commit -m "feat: add hermes agent api client"
```

## Task 2: SSE Parser

**Files:**

- Create: `packages/hermes-swift-sdk/Sources/HermesSwiftSDK/HermesAgentSSEParser.swift`
- Test: `packages/hermes-swift-sdk/Tests/HermesSwiftSDKTests/HermesAgentSSEParserTests.swift`

- [ ] **Step 1: Write failing parser tests**

Create tests covering:

```swift
@Test func parserIgnoresCommentsAndParsesDataEvents() throws {
    let parser = HermesAgentSSEParser()
    let events = try parser.parse("""
    : keepalive

    data: {"event":"message.delta","run_id":"run_1","delta":"hello"}

    data: {"event":"run.completed","run_id":"run_1","output":"done"}

    """)

    #expect(events.count == 2)
    #expect(events[0].objectValue?["event"]?.stringValue == "message.delta")
    #expect(events[0].objectValue?["delta"]?.stringValue == "hello")
    #expect(events[1].objectValue?["event"]?.stringValue == "run.completed")
}

@Test func parserCombinesMultilineDataFields() throws {
    let parser = HermesAgentSSEParser()
    let events = try parser.parse("""
    data: {"event":"message.delta",
    data: "run_id":"run_1",
    data: "delta":"hello"}

    """)

    #expect(events.first?.objectValue?["delta"]?.stringValue == "hello")
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
cd packages/hermes-swift-sdk
swift test --filter HermesAgentSSEParserTests
```

Expected: compile fails because `HermesAgentSSEParser` does not exist.

- [ ] **Step 3: Implement parser**

Create a stateless parser:

```swift
public struct HermesAgentSSEParser {
    public init() {}

    public func parse(_ text: String) throws -> [JSONValue] {
        let blocks = text.components(separatedBy: "\n\n")
        let decoder = JSONDecoder()
        return try blocks.compactMap { block in
            let dataLines = block
                .split(separator: "\n", omittingEmptySubsequences: false)
                .compactMap { line -> String? in
                    guard line.hasPrefix("data:") else { return nil }
                    return String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                }
            guard !dataLines.isEmpty else { return nil }
            let json = dataLines.joined()
            return try decoder.decode(JSONValue.self, from: Data(json.utf8))
        }
    }
}
```

- [ ] **Step 4: Run parser tests**

Run:

```bash
cd packages/hermes-swift-sdk
swift test --filter HermesAgentSSEParserTests
```

Expected: parser tests pass.

- [ ] **Step 5: Commit**

```bash
git add packages/hermes-swift-sdk/Sources/HermesSwiftSDK/HermesAgentSSEParser.swift \
  packages/hermes-swift-sdk/Tests/HermesSwiftSDKTests/HermesAgentSSEParserTests.swift
git commit -m "feat: parse hermes agent sse events"
```

## Task 3: Event Normalizer

**Files:**

- Create: `packages/hermes-swift-sdk/Sources/HermesSwiftSDK/HermesAgentEventNormalizer.swift`
- Test: `packages/hermes-swift-sdk/Tests/HermesSwiftSDKTests/HermesAgentEventNormalizerTests.swift`

- [ ] **Step 1: Write failing normalizer tests**

Cover run accepted, message delta, completed, failed, and cancelled:

```swift
@Test func normalizesRunAcceptedIntoTaskStartedAndMessageAccepted() {
    var normalizer = HermesAgentEventNormalizer(now: { "2026-06-08T00:00:00.000Z" })

    let events = normalizer.normalizeRunAccepted(
        runID: "run_1",
        clientMessageID: "client_1",
        title: "Ask Hermes"
    )

    #expect(events.map(\\.type) == [.taskStarted, .messageAccepted])
    #expect(events[0].payload.objectValue?["task_id"]?.stringValue == "run_1")
    #expect(events[1].payload.objectValue?["client_msg_id"]?.stringValue == "client_1")
}

@Test func normalizesDeltaAndCompleted() {
    var normalizer = HermesAgentEventNormalizer(now: { "2026-06-08T00:00:00.000Z" })
    let delta = JSONValue.object([
        "event": .string("message.delta"),
        "run_id": .string("run_1"),
        "delta": .string("hello")
    ])
    let completed = JSONValue.object([
        "event": .string("run.completed"),
        "run_id": .string("run_1"),
        "output": .string("done")
    ])

    let events = normalizer.normalize(streamEvent: delta) + normalizer.normalize(streamEvent: completed)

    #expect(events.map(\\.type) == [.messageDelta, .messageCompleted, .taskCompleted, .notificationCreated])
    #expect(events[0].payload.objectValue?["delta"]?.stringValue == "hello")
    #expect(events[2].payload.objectValue?["result"]?.stringValue == "done")
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
cd packages/hermes-swift-sdk
swift test --filter HermesAgentEventNormalizerTests
```

Expected: compile fails because `HermesAgentEventNormalizer` does not exist.

- [ ] **Step 3: Implement normalizer**

Create a small stateful struct:

```swift
public struct HermesAgentEventNormalizer {
    public typealias GenericEventEnvelope = EventEnvelope<JSONValue>

    private var nextSeq: Int64
    private let now: () -> String

    public init(startSeq: Int64 = 1, now: @escaping () -> String = HermesAgentEventNormalizer.defaultNow) {
        self.nextSeq = startSeq
        self.now = now
    }

    public mutating func normalizeRunAccepted(
        runID: String,
        clientMessageID: String,
        title: String
    ) -> [GenericEventEnvelope]

    public mutating func normalize(streamEvent: JSONValue) -> [GenericEventEnvelope]
}
```

Implementation details:

- Allocate stable local event IDs as `agent_evt_<seq>`.
- Use local monotonic `seq` starting at `1`.
- Preserve `run_id` as both `task_id` and `message_id`.
- For unknown stream event names, emit one `task.progress` with the raw event name in `message`.
- For malformed stream events without `run_id`, emit `system.error`.

- [ ] **Step 4: Run normalizer tests**

Run:

```bash
cd packages/hermes-swift-sdk
swift test --filter HermesAgentEventNormalizerTests
```

Expected: normalizer tests pass.

- [ ] **Step 5: Commit**

```bash
git add packages/hermes-swift-sdk/Sources/HermesSwiftSDK/HermesAgentEventNormalizer.swift \
  packages/hermes-swift-sdk/Tests/HermesSwiftSDKTests/HermesAgentEventNormalizerTests.swift
git commit -m "feat: normalize hermes agent events"
```

## Task 4: Agent Live Companion Flow

**Files:**

- Create: `apps/macos/Sources/HermesIslandCompanionCore/HermesAgentLiveDemo.swift`
- Test: `apps/macos/Tests/HermesIslandCompanionTests/HermesAgentLiveDemoTests.swift`
- Modify: `apps/macos/Sources/HermesIslandCompanion/main.swift`

- [ ] **Step 1: Write failing companion flow test**

Create a mocked flow that:

- Returns health `ok`.
- Returns models containing `hermes-zpc`.
- Returns `POST /v1/runs` with `run_1`.
- Returns SSE text containing `message.delta` and `run.completed`.
- Verifies UI final state is `Task completed`.

Expected request paths:

```swift
#expect(await transport.paths == [
    "/health",
    "/v1/models",
    "/v1/runs",
    "/v1/runs/run_1/events"
])
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
cd apps/macos
swift test --filter HermesAgentLiveDemoTests
```

Expected: compile fails because `HermesAgentLiveDemo` does not exist.

- [ ] **Step 3: Implement `HermesAgentLiveDemo`**

Public API:

```swift
public struct HermesAgentLiveDemoResult: Equatable, Sendable {
    public let healthStatus: String
    public let modelID: String
    public let runID: String
    public let eventCount: Int
    public let finalIslandTitle: String
    public let taskCount: Int
    public let notificationCount: Int
}

public struct HermesAgentLiveDemo {
    public init(client: HermesAgentAPIClient, model: String, sessionID: String?)
    public func run(prompt: String) async throws -> HermesAgentLiveDemoResult
}
```

Flow:

1. `health()`
2. `models()`
3. `startRun(input:model:sessionID:)`
4. Fetch/parse run events.
5. Normalize to `EventEnvelope<JSONValue>`.
6. Reduce through existing `HermesUIStateReducer`.

If streaming over `URLSession.bytes(for:)` is too large for this milestone, implement an internal `fetchRunEventsText(runID:)` in `HermesAgentAPIClient` using `transport.data(for:)`. This keeps tests simple and still works for completed short smoke runs. Streaming incremental UI can be a later task.

- [ ] **Step 4: Add `agent-live` command**

Modify `main.swift`:

```swift
case "agent-live":
    let env = ProcessInfo.processInfo.environment
    let baseURL = URL(string: env["HERMES_AGENT_GATEWAY_URL"] ?? "http://127.0.0.1:8650")!
    guard let apiKey = env["HERMES_AGENT_API_KEY"], !apiKey.isEmpty else {
        fputs("Missing HERMES_AGENT_API_KEY\n", stderr)
        Foundation.exit(78)
    }
    let model = env["HERMES_AGENT_MODEL"] ?? "hermes-zpc"
    let sessionID = env["HERMES_AGENT_SESSION_ID"]
    let prompt = CommandLine.arguments.dropFirst(2).joined(separator: " ")
    let effectivePrompt = prompt.isEmpty ? "Reply with a short Hermes Island connectivity check." : prompt
    let client = HermesAgentAPIClient(baseURL: baseURL, apiKey: apiKey)
    let result = try await HermesAgentLiveDemo(client: client, model: model, sessionID: sessionID).run(prompt: effectivePrompt)
    print("Hermes Island Agent Live")
    print("gateway=\\(baseURL.absoluteString)")
    print("health=\\(result.healthStatus)")
    print("model=\\(result.modelID)")
    print("run=\\(result.runID)")
    print("events=\\(result.eventCount)")
    print("island=\\(result.finalIslandTitle)")
```

Update help text:

```swift
print("Usage: hermes-island-companion [demo|live|agent-live|help]")
```

- [ ] **Step 5: Run companion tests**

Run:

```bash
cd apps/macos
swift test
```

Expected: all macOS SwiftPM tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/macos/Sources/HermesIslandCompanionCore/HermesAgentLiveDemo.swift \
  apps/macos/Tests/HermesIslandCompanionTests/HermesAgentLiveDemoTests.swift \
  apps/macos/Sources/HermesIslandCompanion/main.swift
git commit -m "feat: add hermes agent live companion flow"
```

## Task 5: Documentation And Developer Commands

**Files:**

- Modify: `apps/macos/README.md`
- Modify: `docs/hermes-agent-gateway-integration.md`
- Modify: `package.json`

- [ ] **Step 1: Add npm script**

Add:

```json
"run:macos-agent-live": "cd apps/macos && swift run hermes-island-companion agent-live"
```

- [ ] **Step 2: Document local live flow**

Add to `apps/macos/README.md`:

```markdown
## Hermes Agent Live Flow

Start the SSH tunnel:

```bash
SSHPASS='706nb' sshpass -e ssh -N \
  -L 8650:172.17.0.1:8650 \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/hermesland_known_hosts \
  -o ExitOnForwardFailure=yes \
  nb706@1.95.80.155
```

Load the API key into shell state without printing it:

```bash
export HERMES_AGENT_API_KEY="$(...)"
export HERMES_AGENT_GATEWAY_URL="http://127.0.0.1:8650"
export HERMES_AGENT_MODEL="hermes-zpc"
export HERMES_AGENT_SESSION_ID="hermes-island-dev"
```

Run:

```bash
npm run run:macos-agent-live -- "Reply with a short connectivity check."
```
```

- [ ] **Step 3: Link docs**

Add a link from `docs/hermes-agent-gateway-integration.md` to this plan:

```markdown
Implementation plan: `docs/superpowers/plans/2026-06-08-hermes-agent-api-server-adapter.md`
```

- [ ] **Step 4: Run docs-adjacent verification**

Run:

```bash
npm test
npm run test:swift-sdk
npm run test:macos
```

Expected: Node tests, Swift SDK tests, and macOS SwiftPM tests pass.

- [ ] **Step 5: Commit**

```bash
git add package.json apps/macos/README.md docs/hermes-agent-gateway-integration.md
git commit -m "docs: document hermes agent live integration"
```

## Task 6: Real Server Smoke Check

**Files:**

- No source files required unless Task 4 discovers a real response mismatch.

- [ ] **Step 1: Start SSH tunnel**

Run in a dedicated terminal:

```bash
SSHPASS='706nb' sshpass -e ssh -N \
  -L 8650:172.17.0.1:8650 \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/hermesland_known_hosts \
  -o ExitOnForwardFailure=yes \
  nb706@1.95.80.155
```

- [ ] **Step 2: Load API key**

Run:

```bash
export HERMES_AGENT_API_KEY="$(
  SSHPASS='706nb' sshpass -e ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/tmp/hermesland_known_hosts \
    nb706@1.95.80.155 \
    'bash -lc '"'"'source /home/nb706/zpc/.hermes/.env; printf %s "$API_SERVER_KEY"'"'"''
)"
export HERMES_AGENT_GATEWAY_URL="http://127.0.0.1:8650"
export HERMES_AGENT_MODEL="hermes-zpc"
export HERMES_AGENT_SESSION_ID="hermes-island-dev"
```

- [ ] **Step 3: Verify metadata endpoints**

Run:

```bash
curl -sS -i http://127.0.0.1:8650/health
curl -sS -i -H "Authorization: Bearer ${HERMES_AGENT_API_KEY}" http://127.0.0.1:8650/v1/models
```

Expected:

- `/health` returns HTTP 200.
- `/v1/models` returns model ID `hermes-zpc`.

- [ ] **Step 4: Run macOS agent live check**

Run:

```bash
npm run run:macos-agent-live -- "Reply with exactly one short sentence confirming Hermes Island connectivity."
```

Expected:

- Command prints `Hermes Island Agent Live`.
- `health=ok`.
- `model=hermes-zpc`.
- `run=run_...`.
- `island=Task completed`.

- [ ] **Step 5: Capture mismatch if real SSE differs**

If the command fails because the real SSE payload shape differs from tests, capture:

```bash
curl -sS -N \
  -H "Authorization: Bearer ${HERMES_AGENT_API_KEY}" \
  http://127.0.0.1:8650/v1/runs/<run_id>/events
```

Then add a normalizer test with the exact observed event payload and update only `HermesAgentEventNormalizer.swift`.

## Multi-Agent Parallelization

Use worktrees so tasks do not overwrite each other:

```bash
git worktree add ../hermesiland-agent-sdk -b feat/hermes-agent-sdk
git worktree add ../hermesiland-agent-demo -b feat/hermes-agent-demo
git worktree add ../hermesiland-agent-docs -b docs/hermes-agent-live
```

Recommended Agent Team split:

- **SDK Agent:** Tasks 1, 2, 3. Owns `packages/hermes-swift-sdk`.
- **macOS Agent:** Task 4. Owns `apps/macos`.
- **Docs/Smoke Agent:** Tasks 5, 6. Owns docs, `package.json`, real server smoke evidence.

Merge order:

1. SDK Agent branch.
2. macOS Agent branch rebased onto SDK.
3. Docs/Smoke Agent branch last.

Review gate for every branch:

```bash
npm test
npm run test:swift-sdk
npm run test:macos
```

## Acceptance Criteria

- Existing mock Gateway smoke and tests still pass.
- New Swift SDK tests cover auth, routes, SSE parser, and event normalization.
- `hermes-island-companion agent-live` can talk to the real Hermes Agent through SSH tunnel.
- No API key is committed.
- UI state reducer remains unchanged for the first milestone.
- The integration can be switched by command/env, not by editing source code.

## Known Follow-Ups

- Incremental streaming UI with `URLSession.AsyncBytes` instead of collecting completed SSE text.
- Production Caddy route with TLS and restricted access.
- Real approval event support after observing Hermes Agent approval payloads from live tool execution.
- Persisted cursor/replay for real Hermes Agent runs if the server adds replayable event history.
