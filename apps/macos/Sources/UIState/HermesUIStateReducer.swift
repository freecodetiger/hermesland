import Foundation

public enum HermesUIEvent: Equatable, Sendable {
    case messageAccepted
    case taskStarted(taskID: String, title: String)
    case taskProgress(taskID: String, progress: Double, message: String)
    case taskCompleted(taskID: String, result: String)
    case taskFailed(taskID: String, message: String)
    case taskCancelled(taskID: String, reason: String?)
    case taskRequiresApproval(taskID: String, approvalID: String, prompt: String)
    case notificationCreated(id: String, title: String, body: String)
}

public struct HermesUIState: Equatable, Sendable {
    public var island: IslandState
    public var tasks: [TaskListItem]
    public var notifications: [NotificationItem]

    public init(
        island: IslandState = .hidden,
        tasks: [TaskListItem] = [],
        notifications: [NotificationItem] = []
    ) {
        self.island = island
        self.tasks = tasks
        self.notifications = notifications
    }
}

public struct HermesUIStateReducer {
    public init() {}

    public func reduce(_ state: HermesUIState, event: HermesUIEvent) -> HermesUIState {
        var next = state

        switch event {
        case .messageAccepted:
            break
        case let .taskStarted(taskID, title):
            upsertTask(&next.tasks, item: TaskListItem(
                id: taskID,
                title: title,
                status: .running(progress: nil)
            ))
            next.island = IslandState(title: title, detail: "Running", priority: .transient)
        case let .taskProgress(taskID, progress, message):
            updateTask(&next.tasks, taskID: taskID) { item in
                item.status = .running(progress: progress)
            }
            next.island = IslandState(title: message, detail: progressText(progress), priority: .transient)
        case let .taskCompleted(taskID, result):
            updateTask(&next.tasks, taskID: taskID) { item in
                item.status = .completed
            }
            next.island = IslandState(title: "Task completed", detail: result, priority: .transient)
        case let .taskFailed(taskID, message):
            updateTask(&next.tasks, taskID: taskID) { item in
                item.status = .failed(message: message)
            }
            next.island = IslandState(title: "Task failed", detail: message, priority: .persistent)
            next.notifications.append(NotificationItem(id: "task-failed-\(taskID)", title: "Task failed", body: message))
        case let .taskCancelled(taskID, reason):
            updateTask(&next.tasks, taskID: taskID) { item in
                item.status = .cancelled(reason: reason)
            }
            next.island = IslandState(title: "Task cancelled", detail: reason, priority: .transient)
        case let .taskRequiresApproval(taskID, approvalID, prompt):
            updateTask(&next.tasks, taskID: taskID) { item in
                item.status = .waitingApproval(approvalID: approvalID)
            }
            next.island = IslandState(
                title: "Approval required",
                detail: prompt,
                priority: .persistent,
                approvalID: approvalID
            )
            next.notifications.append(NotificationItem(id: approvalID, title: "Approval required", body: prompt))
        case let .notificationCreated(id, title, body):
            next.notifications.append(NotificationItem(id: id, title: title, body: body))
        }

        return next
    }

    private func upsertTask(_ tasks: inout [TaskListItem], item: TaskListItem) {
        if let index = tasks.firstIndex(where: { $0.id == item.id }) {
            tasks[index] = item
        } else {
            tasks.append(item)
        }
    }

    private func updateTask(_ tasks: inout [TaskListItem], taskID: String, update: (inout TaskListItem) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else {
            return
        }

        update(&tasks[index])
    }

    private func progressText(_ progress: Double) -> String {
        "\(Int(progress * 100))%"
    }
}
