import AppShell
import Foundation
import UIState

public struct CompanionDemoResult: Equatable, Sendable {
    public let connectionState: AppConnectionState
    public let islandTitle: String
    public let taskCount: Int
    public let notificationCount: Int

    public init(
        connectionState: AppConnectionState,
        islandTitle: String,
        taskCount: Int,
        notificationCount: Int
    ) {
        self.connectionState = connectionState
        self.islandTitle = islandTitle
        self.taskCount = taskCount
        self.notificationCount = notificationCount
    }
}

public struct CompanionDemo {
    public init() {}

    @MainActor
    public func run() -> CompanionDemoResult {
        let shell = AppShellModel()
        let reducer = HermesUIStateReducer()
        var uiState = HermesUIState()

        shell.send(.connect)
        shell.updateConnectionState(.onlineIdle)
        uiState = reducer.reduce(uiState, event: .taskStarted(taskID: "task-demo", title: "Demo task"))
        uiState = reducer.reduce(uiState, event: .taskRequiresApproval(
            taskID: "task-demo",
            approvalID: "approval-demo",
            prompt: "Approve demo task?"
        ))

        return CompanionDemoResult(
            connectionState: shell.connectionState,
            islandTitle: uiState.island.title,
            taskCount: uiState.tasks.count,
            notificationCount: uiState.notifications.count
        )
    }
}
