public struct EventEnvelope<Payload: Codable & Equatable>: Codable, Equatable {
    public let eventID: String
    public let seq: Int64
    public let type: EventType
    public let createdAt: String
    public let payload: Payload

    public init(
        eventID: String,
        seq: Int64,
        type: EventType,
        createdAt: String,
        payload: Payload
    ) {
        self.eventID = eventID
        self.seq = seq
        self.type = type
        self.createdAt = createdAt
        self.payload = payload
    }

    private enum CodingKeys: String, CodingKey {
        case eventID = "event_id"
        case seq
        case type
        case createdAt = "created_at"
        case payload
    }
}

public enum EventType: String, Codable, Equatable, CaseIterable {
    case messageAccepted = "message.accepted"
    case messageDelta = "message.delta"
    case messageCompleted = "message.completed"
    case messageFailed = "message.failed"
    case taskStarted = "task.started"
    case taskProgress = "task.progress"
    case taskCompleted = "task.completed"
    case taskFailed = "task.failed"
    case taskCancelled = "task.cancelled"
    case taskRequiresApproval = "task.requires_approval"
    case notificationCreated = "notification.created"
    case agentOnline = "agent.online"
    case agentOffline = "agent.offline"
    case systemError = "system.error"
}
