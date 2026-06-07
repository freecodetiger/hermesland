import Testing
@testable import HermesSwiftSDK

struct LastSeqTrackerTests {
    @Test func advancesOnlyWhenSeqIsGreaterThanCurrent() {
        var tracker = LastSeqTracker()

        #expect(tracker.current == 0)
        let zeroAdvanced = tracker.advanceIfGreater(0)
        #expect(!zeroAdvanced)
        let twoAdvanced = tracker.advanceIfGreater(2)
        #expect(twoAdvanced)
        #expect(tracker.current == 2)
        let oneAdvanced = tracker.advanceIfGreater(1)
        #expect(!oneAdvanced)
        #expect(tracker.current == 2)
        let repeatedTwoAdvanced = tracker.advanceIfGreater(2)
        #expect(!repeatedTwoAdvanced)
        #expect(tracker.current == 2)
        let fiveAdvanced = tracker.advanceIfGreater(5)
        #expect(fiveAdvanced)
        #expect(tracker.current == 5)
    }
}
