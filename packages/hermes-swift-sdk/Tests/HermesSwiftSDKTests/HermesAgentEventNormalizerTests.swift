import Testing
@testable import HermesSwiftSDK

struct HermesAgentEventNormalizerTests {
    @Test func normalizesRunAcceptedIntoTaskStartedAndMessageAccepted() {
        var normalizer = HermesAgentEventNormalizer(now: { "2026-06-08T00:00:00.000Z" })

        let events = normalizer.normalizeRunAccepted(
            runID: "run_1",
            clientMessageID: "client_1",
            title: "Ask Hermes"
        )

        #expect(events.map(\.type) == [.taskStarted, .messageAccepted])
        #expect(events.map(\.seq) == [1, 2])
        #expect(events[0].payload.objectValue?["task_id"]?.stringValue == "run_1")
        #expect(events[0].payload.objectValue?["title"]?.stringValue == "Ask Hermes")
        #expect(events[1].payload.objectValue?["message_id"]?.stringValue == "run_1")
        #expect(events[1].payload.objectValue?["client_msg_id"]?.stringValue == "client_1")
    }

    @Test func normalizesDeltaAndCompleted() {
        var normalizer = HermesAgentEventNormalizer(now: { "2026-06-08T00:00:00.000Z" })
        let delta = JSONValue.object([
            "event": .string("message.delta"),
            "run_id": .string("run_1"),
            "delta": .string("hello"),
        ])
        let completed = JSONValue.object([
            "event": .string("run.completed"),
            "run_id": .string("run_1"),
            "output": .string("done"),
        ])

        let events = normalizer.normalize(streamEvent: delta) + normalizer.normalize(streamEvent: completed)

        #expect(events.map(\.type) == [.messageDelta, .messageCompleted, .taskCompleted, .notificationCreated])
        #expect(events[0].payload.objectValue?["delta"]?.stringValue == "hello")
        #expect(events[1].payload.objectValue?["text"]?.stringValue == "done")
        #expect(events[2].payload.objectValue?["result"]?.stringValue == "done")
    }

    @Test func normalizesFailedAndCancelled() {
        var normalizer = HermesAgentEventNormalizer(now: { "2026-06-08T00:00:00.000Z" })
        let failed = JSONValue.object([
            "event": .string("run.failed"),
            "run_id": .string("run_1"),
            "error": .string("boom"),
        ])
        let cancelled = JSONValue.object([
            "event": .string("run.cancelled"),
            "run_id": .string("run_2"),
        ])

        let events = normalizer.normalize(streamEvent: failed) + normalizer.normalize(streamEvent: cancelled)

        #expect(events.map(\.type) == [.taskFailed, .systemError, .taskCancelled])
        #expect(events[0].payload.objectValue?["error"]?.objectValue?["message"]?.stringValue == "boom")
        #expect(events[2].payload.objectValue?["reason"]?.stringValue == "Run cancelled.")
    }

    @Test func malformedEventWithoutRunIDEmitsSystemError() {
        var normalizer = HermesAgentEventNormalizer(now: { "2026-06-08T00:00:00.000Z" })

        let events = normalizer.normalize(streamEvent: .object(["event": .string("message.delta")]))

        #expect(events.map(\.type) == [.systemError])
        #expect(events[0].payload.objectValue?["error"]?.objectValue?["code"]?.stringValue == "HERMES_AGENT_EVENT_MALFORMED")
    }
}
