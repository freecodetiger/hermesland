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
            payload: MessageDeltaPayload(messageID: "msg_001", delta: "Hello")
        )

        let data = try JSONEncoder().encode(envelope)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let payload = object?["payload"] as? [String: Any]

        #expect(object?["event_id"] as? String == "evt_002")
        #expect(object?["seq"] as? Int == 2)
        #expect(object?["type"] as? String == "message.delta")
        #expect(object?["created_at"] as? String == "2026-01-01T00:00:00.000Z")
        #expect(payload?["message_id"] as? String == "msg_001")
        #expect(payload?["delta"] as? String == "Hello")
    }
}
