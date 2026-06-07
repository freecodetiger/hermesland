public struct EventDeduplicator {
    private var seenEventIDs: Set<String>

    public init(seenEventIDs: Set<String> = []) {
        self.seenEventIDs = seenEventIDs
    }

    @discardableResult
    public mutating func recordIfNew(eventID: String) -> Bool {
        seenEventIDs.insert(eventID).inserted
    }
}
