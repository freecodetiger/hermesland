import Foundation

public enum IslandPriority: Int, Equatable, Sendable {
    case passive = 0
    case transient = 1
    case persistent = 2
}

public struct IslandState: Equatable, Sendable {
    public let title: String
    public let detail: String?
    public let priority: IslandPriority
    public let approvalID: String?

    public init(
        title: String,
        detail: String? = nil,
        priority: IslandPriority = .transient,
        approvalID: String? = nil
    ) {
        self.title = title
        self.detail = detail
        self.priority = priority
        self.approvalID = approvalID
    }

    public static let hidden = IslandState(
        title: "",
        detail: nil,
        priority: .passive,
        approvalID: nil
    )
}
