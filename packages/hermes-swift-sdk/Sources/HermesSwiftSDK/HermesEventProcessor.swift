public struct EventProcessingResult: Equatable {
    public let isNewEvent: Bool
    public let didAdvanceSeq: Bool
    public let lastSeq: Int64

    public init(isNewEvent: Bool, didAdvanceSeq: Bool, lastSeq: Int64) {
        self.isNewEvent = isNewEvent
        self.didAdvanceSeq = didAdvanceSeq
        self.lastSeq = lastSeq
    }
}

public struct HermesEventProcessor {
    private var deduplicator: EventDeduplicator
    private var seqTracker: LastSeqTracker

    public init(
        deduplicator: EventDeduplicator = EventDeduplicator(),
        seqTracker: LastSeqTracker = LastSeqTracker()
    ) {
        self.deduplicator = deduplicator
        self.seqTracker = seqTracker
    }

    public var lastSeq: Int64 {
        seqTracker.current
    }

    public mutating func process<Payload>(_ envelope: EventEnvelope<Payload>) -> EventProcessingResult {
        guard deduplicator.recordIfNew(eventID: envelope.eventID) else {
            return EventProcessingResult(
                isNewEvent: false,
                didAdvanceSeq: false,
                lastSeq: seqTracker.current
            )
        }

        let didAdvanceSeq = seqTracker.advanceIfGreater(envelope.seq)
        return EventProcessingResult(
            isNewEvent: true,
            didAdvanceSeq: didAdvanceSeq,
            lastSeq: seqTracker.current
        )
    }
}
