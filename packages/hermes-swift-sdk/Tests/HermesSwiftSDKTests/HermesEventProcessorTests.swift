import Testing
@testable import HermesSwiftSDK

struct HermesEventProcessorTests {
    @Test func processesNewEventsAndIgnoresDuplicateEventIDs() {
        var processor = HermesEventProcessor()
        let first = makeEnvelope(eventID: "evt_001", seq: 1)
        let duplicateHigherSeq = makeEnvelope(eventID: "evt_001", seq: 3)
        let second = makeEnvelope(eventID: "evt_002", seq: 2)

        let firstResult = processor.process(first)
        let duplicateResult = processor.process(duplicateHigherSeq)
        let secondResult = processor.process(second)

        #expect(firstResult.isNewEvent)
        #expect(firstResult.didAdvanceSeq)
        #expect(firstResult.lastSeq == 1)

        #expect(!duplicateResult.isNewEvent)
        #expect(!duplicateResult.didAdvanceSeq)
        #expect(duplicateResult.lastSeq == 1)

        #expect(secondResult.isNewEvent)
        #expect(secondResult.didAdvanceSeq)
        #expect(secondResult.lastSeq == 2)
    }

    @Test func doesNotDecreaseLastSeqForOlderNewEvents() {
        var processor = HermesEventProcessor()

        _ = processor.process(makeEnvelope(eventID: "evt_010", seq: 10))
        let result = processor.process(makeEnvelope(eventID: "evt_004", seq: 4))

        #expect(result.isNewEvent)
        #expect(!result.didAdvanceSeq)
        #expect(result.lastSeq == 10)
    }

    private func makeEnvelope(eventID: String, seq: Int64) -> EventEnvelope<MessageDeltaPayload> {
        EventEnvelope(
            eventID: eventID,
            seq: seq,
            type: .messageDelta,
            createdAt: "2026-01-01T00:00:00.000Z",
            payload: MessageDeltaPayload(messageID: "msg_001", delta: "Hello")
        )
    }
}
