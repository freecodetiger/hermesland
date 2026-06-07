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
}
