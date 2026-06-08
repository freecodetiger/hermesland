import Foundation

public struct HermesAgentEventNormalizer {
    public typealias GenericEventEnvelope = EventEnvelope<JSONValue>

    private var nextSeq: Int64
    private let now: () -> String

    public init(
        startSeq: Int64 = 1,
        now: @escaping () -> String = HermesAgentEventNormalizer.defaultNow
    ) {
        self.nextSeq = startSeq
        self.now = now
    }

    public mutating func normalizeRunAccepted(
        runID: String,
        clientMessageID: String,
        title: String
    ) -> [GenericEventEnvelope] {
        [
            makeEvent(
                type: .taskStarted,
                payload: [
                    "task_id": .string(runID),
                    "title": .string(title),
                ]
            ),
            makeEvent(
                type: .messageAccepted,
                payload: [
                    "message_id": .string(runID),
                    "client_msg_id": .string(clientMessageID),
                ]
            ),
        ]
    }

    public mutating func normalize(streamEvent: JSONValue) -> [GenericEventEnvelope] {
        guard let object = streamEvent.objectValue else {
            return [systemError(code: "HERMES_AGENT_EVENT_MALFORMED", message: "SSE event was not a JSON object.")]
        }
        guard let eventName = object["event"]?.stringValue else {
            return [systemError(code: "HERMES_AGENT_EVENT_MALFORMED", message: "SSE event missing event name.")]
        }
        guard let runID = object["run_id"]?.stringValue else {
            return [systemError(code: "HERMES_AGENT_EVENT_MALFORMED", message: "SSE event missing run_id.")]
        }

        switch eventName {
        case "message.delta":
            return [
                makeEvent(
                    type: .messageDelta,
                    payload: [
                        "message_id": .string(runID),
                        "delta": .string(object["delta"]?.stringValue ?? ""),
                    ]
                ),
            ]
        case "run.completed":
            let output = object["output"]?.stringValue ?? ""
            return [
                makeEvent(
                    type: .messageCompleted,
                    payload: [
                        "message_id": .string(runID),
                        "text": .string(output),
                    ]
                ),
                makeEvent(
                    type: .taskCompleted,
                    payload: [
                        "task_id": .string(runID),
                        "result": .string(output),
                    ]
                ),
                makeEvent(
                    type: .notificationCreated,
                    payload: [
                        "notification_id": .string("notification_\(runID)"),
                        "title": .string("Task completed"),
                        "body": .string(output),
                    ]
                ),
            ]
        case "run.failed":
            let message = object["error"]?.stringValue ?? "Hermes Agent run failed."
            return [
                makeEvent(
                    type: .taskFailed,
                    payload: [
                        "task_id": .string(runID),
                        "error": errorPayload(code: "HERMES_AGENT_RUN_FAILED", message: message),
                    ]
                ),
                systemError(code: "HERMES_AGENT_RUN_FAILED", message: message),
            ]
        case "run.cancelled":
            return [
                makeEvent(
                    type: .taskCancelled,
                    payload: [
                        "task_id": .string(runID),
                        "reason": .string(object["reason"]?.stringValue ?? "Run cancelled."),
                    ]
                ),
            ]
        default:
            return [
                makeEvent(
                    type: .taskProgress,
                    payload: [
                        "task_id": .string(runID),
                        "progress": .number(0),
                        "message": .string(eventName),
                    ]
                ),
            ]
        }
    }

    public static func defaultNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private mutating func makeEvent(
        type: EventType,
        payload: [String: JSONValue]
    ) -> GenericEventEnvelope {
        let seq = nextSeq
        nextSeq += 1
        return GenericEventEnvelope(
            eventID: "agent_evt_\(seq)",
            seq: seq,
            type: type,
            createdAt: now(),
            payload: .object(payload)
        )
    }

    private mutating func systemError(code: String, message: String) -> GenericEventEnvelope {
        makeEvent(
            type: .systemError,
            payload: [
                "error": errorPayload(code: code, message: message),
            ]
        )
    }

    private func errorPayload(code: String, message: String) -> JSONValue {
        .object([
            "code": .string(code),
            "message": .string(message),
        ])
    }
}
