import Testing
@testable import HermesSwiftSDK

struct ReconnectPolicyTests {
    @Test func delaysFollowBackoffSequenceAndCapAtSixtySeconds() {
        let policy = ReconnectPolicy()

        let delays = (0...8).map { policy.delay(forAttempt: $0) }

        #expect(delays == [1, 2, 5, 10, 30, 60, 60, 60, 60])
    }
}
