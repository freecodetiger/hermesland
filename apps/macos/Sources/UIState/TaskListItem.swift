import Foundation

public enum TaskListStatus: Equatable, Sendable {
    case running(progress: Double?)
    case waitingApproval(approvalID: String)
    case completed
    case failed(message: String)
    case cancelled(reason: String?)
}

public struct TaskListItem: Equatable, Sendable {
    public let id: String
    public var title: String
    public var status: TaskListStatus

    public init(id: String, title: String, status: TaskListStatus) {
        self.id = id
        self.title = title
        self.status = status
    }
}
