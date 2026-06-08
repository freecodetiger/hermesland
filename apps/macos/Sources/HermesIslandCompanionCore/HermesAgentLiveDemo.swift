import Foundation
import HermesSwiftSDK
import UIState

public struct HermesAgentLiveDemoResult: Equatable, Sendable {
    public let healthStatus: String
    public let modelID: String
    public let runID: String
    public let eventCount: Int
    public let finalIslandTitle: String
    public let taskCount: Int
    public let notificationCount: Int

    public init(
        healthStatus: String,
        modelID: String,
        runID: String,
        eventCount: Int,
        finalIslandTitle: String,
        taskCount: Int,
        notificationCount: Int
    ) {
        self.healthStatus = healthStatus
        self.modelID = modelID
        self.runID = runID
        self.eventCount = eventCount
        self.finalIslandTitle = finalIslandTitle
        self.taskCount = taskCount
        self.notificationCount = notificationCount
    }
}

public struct HermesAgentLiveDemo {
    private let client: HermesAgentAPIClient
    private let model: String
    private let sessionID: String?

    public init(client: HermesAgentAPIClient, model: String, sessionID: String?) {
        self.client = client
        self.model = model
        self.sessionID = sessionID
    }

    public func run(prompt: String) async throws -> HermesAgentLiveDemoResult {
        let health = try await client.health()
        let models = try await client.models()
        guard let selectedModel = models.data.first(where: { $0.id == model }) else {
            throw HermesAgentLiveDemoError.modelNotFound(model)
        }

        let run = try await client.startRun(
            input: prompt,
            model: selectedModel.id,
            sessionID: sessionID
        )
        let eventText = try await client.fetchRunEventsText(runID: run.runID)
        let streamEvents = HermesAgentSSEParser.parse(eventText)

        var normalizer = HermesAgentEventNormalizer()
        var events = normalizer.normalizeRunAccepted(
            runID: run.runID,
            clientMessageID: "client-\(run.runID)",
            title: "Hermes Agent Run"
        )
        for streamEvent in streamEvents {
            events += normalizer.normalize(streamEvent: streamEvent)
        }

        let uiState = reduce(events: events)

        return HermesAgentLiveDemoResult(
            healthStatus: health.status,
            modelID: selectedModel.id,
            runID: run.runID,
            eventCount: events.count,
            finalIslandTitle: uiState.island.title,
            taskCount: uiState.tasks.count,
            notificationCount: uiState.notifications.count
        )
    }

    private func reduce(events: [EventEnvelope<JSONValue>]) -> HermesUIState {
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

    private func makeUIEvent(from event: EventEnvelope<JSONValue>) -> HermesUIEvent? {
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

public enum HermesAgentLiveDemoError: Error, Equatable {
    case modelNotFound(String)
}
