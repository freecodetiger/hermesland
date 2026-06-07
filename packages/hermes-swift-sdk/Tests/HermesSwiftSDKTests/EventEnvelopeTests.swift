import Foundation
import Testing
@testable import HermesSwiftSDK

struct EventEnvelopeTests {
    @Test func decodesMessageAcceptedEnvelope() throws {
        let json = """
        {
          "event_id": "evt_001",
          "seq": 1,
          "type": "message.accepted",
          "created_at": "2026-01-01T00:00:00.000Z",
          "payload": {
            "message_id": "msg_001",
            "client_msg_id": "client_msg_001"
          }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(EventEnvelope<MessageAcceptedPayload>.self, from: json)

        #expect(envelope.eventID == "evt_001")
        #expect(envelope.seq == 1)
        #expect(envelope.type == .messageAccepted)
        #expect(envelope.createdAt == "2026-01-01T00:00:00.000Z")
        #expect(envelope.payload.messageID == "msg_001")
        #expect(envelope.payload.clientMessageID == "client_msg_001")
    }

    @Test func encodesEnvelopeUsingProtocolFieldNames() throws {
        let envelope = EventEnvelope(
            eventID: "evt_002",
            seq: 2,
            type: .messageDelta,
            createdAt: "2026-01-01T00:00:00.000Z",
            payload: MessageDeltaPayload(
                conversationID: "conv_001",
                messageID: "msg_001",
                clientMessageID: "client_msg_001",
                delta: "Hello"
            )
        )

        let data = try JSONEncoder().encode(envelope)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let payload = object?["payload"] as? [String: Any]

        #expect(object?["event_id"] as? String == "evt_002")
        #expect(object?["seq"] as? Int == 2)
        #expect(object?["type"] as? String == "message.delta")
        #expect(object?["created_at"] as? String == "2026-01-01T00:00:00.000Z")
        #expect(payload?["conversation_id"] as? String == "conv_001")
        #expect(payload?["message_id"] as? String == "msg_001")
        #expect(payload?["client_msg_id"] as? String == "client_msg_001")
        #expect(payload?["delta"] as? String == "Hello")
    }

    @Test func decodesGatewayMessageDeltaPayload() throws {
        let json = """
        {
          "event_id": "evt_000002",
          "seq": 2,
          "type": "message.delta",
          "created_at": "2026-06-08T00:00:00.000Z",
          "payload": {
            "conversation_id": "conv-smoke",
            "message_id": "msg_smoke-1",
            "client_msg_id": "smoke-1",
            "delta": "Mock response part 1"
          }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(EventEnvelope<MessageDeltaPayload>.self, from: json)

        #expect(envelope.payload.conversationID == "conv-smoke")
        #expect(envelope.payload.messageID == "msg_smoke-1")
        #expect(envelope.payload.clientMessageID == "smoke-1")
        #expect(envelope.payload.delta == "Mock response part 1")
    }

    @Test func decodesGatewayTaskStartedEnvelope() throws {
        let json = """
        {
          "event_id": "evt_005",
          "seq": 5,
          "type": "task.started",
          "created_at": "2026-01-01T00:00:00.000Z",
          "payload": {
            "task_id": "task_001",
            "title": "Run smoke test"
          }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(EventEnvelope<TaskStartedPayload>.self, from: json)

        #expect(envelope.type == .taskStarted)
        #expect(envelope.payload.taskID == "task_001")
        #expect(envelope.payload.title == "Run smoke test")
    }

    @Test func decodesGatewayTaskProgressEnvelope() throws {
        let json = """
        {
          "event_id": "evt_006",
          "seq": 6,
          "type": "task.progress",
          "created_at": "2026-01-01T00:00:00.000Z",
          "payload": {
            "task_id": "task_001",
            "progress": 0.5,
            "message": "Gateway stream connected."
          }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(EventEnvelope<TaskProgressPayload>.self, from: json)

        #expect(envelope.type == .taskProgress)
        #expect(envelope.payload.taskID == "task_001")
        #expect(envelope.payload.progress == 0.5)
        #expect(envelope.payload.message == "Gateway stream connected.")
    }

    @Test func decodesGatewayTaskCompletedEnvelope() throws {
        let json = """
        {
          "event_id": "evt_007",
          "seq": 7,
          "type": "task.completed",
          "created_at": "2026-01-01T00:00:00.000Z",
          "payload": {
            "task_id": "task_001",
            "result": "Smoke test passed."
          }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(EventEnvelope<TaskCompletedPayload>.self, from: json)

        #expect(envelope.type == .taskCompleted)
        #expect(envelope.payload.taskID == "task_001")
        #expect(envelope.payload.result == "Smoke test passed.")
    }

    @Test func decodesGatewayTaskFailedEnvelope() throws {
        let json = """
        {
          "event_id": "evt_008",
          "seq": 8,
          "type": "task.failed",
          "created_at": "2026-01-01T00:00:00.000Z",
          "payload": {
            "task_id": "task_002",
            "error": {
              "code": "COMMAND_FAILED",
              "message": "npm test exited non-zero."
            }
          }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(EventEnvelope<TaskFailedPayload>.self, from: json)

        #expect(envelope.type == .taskFailed)
        #expect(envelope.payload.taskID == "task_002")
        #expect(envelope.payload.error.code == "COMMAND_FAILED")
        #expect(envelope.payload.error.message == "npm test exited non-zero.")
    }

    @Test func decodesGatewayTaskCancelledEnvelope() throws {
        let json = """
        {
          "event_id": "evt_009",
          "seq": 9,
          "type": "task.cancelled",
          "created_at": "2026-01-01T00:00:00.000Z",
          "payload": {
            "task_id": "task_003",
            "reason": "User cancelled from Island."
          }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(EventEnvelope<TaskCancelledPayload>.self, from: json)

        #expect(envelope.type == .taskCancelled)
        #expect(envelope.payload.taskID == "task_003")
        #expect(envelope.payload.reason == "User cancelled from Island.")
    }

    @Test func decodesGatewayTaskRequiresApprovalEnvelope() throws {
        let json = """
        {
          "event_id": "evt_010",
          "seq": 10,
          "type": "task.requires_approval",
          "created_at": "2026-01-01T00:00:00.000Z",
          "payload": {
            "task_id": "task_004",
            "approval_id": "approval_001",
            "prompt": "Allow file write?",
            "actions": ["approve", "deny"],
            "expires_at": "2026-01-01T00:05:00.000Z"
          }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(EventEnvelope<TaskRequiresApprovalPayload>.self, from: json)

        #expect(envelope.type == .taskRequiresApproval)
        #expect(envelope.payload.taskID == "task_004")
        #expect(envelope.payload.approvalID == "approval_001")
        #expect(envelope.payload.prompt == "Allow file write?")
        #expect(envelope.payload.actions == ["approve", "deny"])
        #expect(envelope.payload.expiresAt == "2026-01-01T00:05:00.000Z")
    }

    @Test func encodesApprovalDecisionRequestUsingProtocolFieldNames() throws {
        let request = ApprovalDecisionRequest(
            approvalID: "approval_001",
            taskID: "task_004",
            decision: .approve
        )

        let data = try JSONEncoder().encode(request)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(object?["approval_id"] as? String == "approval_001")
        #expect(object?["task_id"] as? String == "task_004")
        #expect(object?["decision"] as? String == "approve")
    }
}
