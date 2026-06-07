import AppShell
import Foundation
import HermesSwiftSDK
import UIState

public struct LiveGatewayDemoResult: Equatable, Sendable {
    public let healthStatus: String
    public let token: String
    public let messageEventCount: Int
    public let approvalEventCount: Int
    public let finalIslandTitle: String
    public let taskCount: Int
    public let notificationCount: Int

    public init(
        healthStatus: String,
        token: String,
        messageEventCount: Int,
        approvalEventCount: Int,
        finalIslandTitle: String,
        taskCount: Int,
        notificationCount: Int
    ) {
        self.healthStatus = healthStatus
        self.token = token
        self.messageEventCount = messageEventCount
        self.approvalEventCount = approvalEventCount
        self.finalIslandTitle = finalIslandTitle
        self.taskCount = taskCount
        self.notificationCount = notificationCount
    }
}

public struct LiveGatewayDemo {
    private let client: HermesHTTPClient

    public init(client: HermesHTTPClient) {
        self.client = client
    }

    public func run() async throws -> LiveGatewayDemoResult {
        let health = try await client.health()
        let auth = try await client.startDeviceAuth(
            deviceName: "Hermes Island SwiftPM Companion",
            clientID: "macos-companion"
        )
        let messageEvents = try await client.sendMessage(
            conversationID: "conv-companion",
            clientMessageID: "client-companion-\(Int(Date().timeIntervalSince1970))",
            content: "Hello from Hermes Island companion."
        )
        _ = try await client.runTask(mode: "approval")
        let events = try await client.fetchEvents(afterSeq: 0)
        guard let approvalID = findFirstApprovalID(in: events) else {
            throw LiveGatewayDemoError.missingApprovalID
        }
        let approvalEvents = try await client.resolveApproval(
            approvalID: approvalID,
            decision: .approve
        )

        let uiState = reduce(events: events + approvalEvents)

        return LiveGatewayDemoResult(
            healthStatus: health.status,
            token: auth.token,
            messageEventCount: messageEvents.count,
            approvalEventCount: approvalEvents.count,
            finalIslandTitle: uiState.island.title,
            taskCount: uiState.tasks.count,
            notificationCount: uiState.notifications.count
        )
    }

    private func findFirstApprovalID(in events: [HermesHTTPClient.GenericEventEnvelope]) -> String? {
        for event in events where event.type == .taskRequiresApproval {
            if let approvalID = event.payload.objectValue?["approval_id"]?.stringValue {
                return approvalID
            }
        }
        return nil
    }

    private func reduce(events: [HermesHTTPClient.GenericEventEnvelope]) -> HermesUIState {
        let reducer = HermesUIStateReducer()
        var state = HermesUIState()

        for event in events {
            guard let uiEvent = makeUIEvent(from: event) else {
                continue
            }
            state = reducer.reduce(state, event: uiEvent)
        }

        return state
    }

    private func makeUIEvent(from event: HermesHTTPClient.GenericEventEnvelope) -> HermesUIEvent? {
        let payload = event.payload.objectValue ?? [:]

        switch event.type {
        case .messageAccepted:
            return .messageAccepted
        case .taskStarted:
            return .taskStarted(
                taskID: payload["task_id"]?.stringValue ?? "unknown-task",
                title: payload["title"]?.stringValue ?? "Task started"
            )
        case .taskProgress:
            return .taskProgress(
                taskID: payload["task_id"]?.stringValue ?? "unknown-task",
                progress: payload["progress"]?.numberValue ?? 0,
                message: payload["message"]?.stringValue ?? "Task running"
            )
        case .taskCompleted:
            return .taskCompleted(
                taskID: payload["task_id"]?.stringValue ?? "unknown-task",
                result: payload["result"]?.stringValue ?? "Task completed"
            )
        case .taskFailed:
            let error = payload["error"]?.objectValue
            return .taskFailed(
                taskID: payload["task_id"]?.stringValue ?? "unknown-task",
                message: error?["message"]?.stringValue ?? "Task failed"
            )
        case .taskCancelled:
            return .taskCancelled(
                taskID: payload["task_id"]?.stringValue ?? "unknown-task",
                reason: payload["reason"]?.stringValue
            )
        case .taskRequiresApproval:
            return .taskRequiresApproval(
                taskID: payload["task_id"]?.stringValue ?? "unknown-task",
                approvalID: payload["approval_id"]?.stringValue ?? "unknown-approval",
                prompt: payload["prompt"]?.stringValue ?? "Approval required"
            )
        case .notificationCreated:
            return .notificationCreated(
                id: payload["notification_id"]?.stringValue ?? "unknown-notification",
                title: payload["title"]?.stringValue ?? "Notification",
                body: payload["body"]?.stringValue ?? ""
            )
        case .messageDelta, .messageCompleted, .messageFailed, .agentOnline, .agentOffline, .systemError:
            return nil
        }
    }
}

public enum LiveGatewayDemoError: Error, Equatable {
    case missingApprovalID
}
