import AppShell
import HermesIslandCompanionCore
import Testing

struct CompanionDemoTests {
    @MainActor
    @Test func demoProducesApprovalIslandState() {
        let result = CompanionDemo().run()

        #expect(result.connectionState == .onlineIdle)
        #expect(result.islandTitle == "Approval required")
        #expect(result.taskCount == 1)
        #expect(result.notificationCount == 1)
    }
}
