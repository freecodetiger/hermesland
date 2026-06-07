import Foundation

public struct NotificationItem: Equatable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public var isRead: Bool

    public init(id: String, title: String, body: String, isRead: Bool = false) {
        self.id = id
        self.title = title
        self.body = body
        self.isRead = isRead
    }
}
