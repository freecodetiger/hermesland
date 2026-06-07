import Testing
@testable import HermesSwiftSDK

struct EventDeduplicatorTests {
    @Test func duplicateEventIDIsIgnored() {
        var deduplicator = EventDeduplicator()

        let first = deduplicator.recordIfNew(eventID: "evt_001")
        let duplicate = deduplicator.recordIfNew(eventID: "evt_001")
        let second = deduplicator.recordIfNew(eventID: "evt_002")

        #expect(first)
        #expect(!duplicate)
        #expect(second)
    }
}
