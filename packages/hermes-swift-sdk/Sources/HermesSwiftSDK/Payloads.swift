public struct MessageAcceptedPayload: Codable, Equatable {
    public let conversationID: String?
    public let messageID: String
    public let clientMessageID: String

    public init(conversationID: String? = nil, messageID: String, clientMessageID: String) {
        self.conversationID = conversationID
        self.messageID = messageID
        self.clientMessageID = clientMessageID
    }

    private enum CodingKeys: String, CodingKey {
        case conversationID = "conversation_id"
        case messageID = "message_id"
        case clientMessageID = "client_msg_id"
    }
}

public struct MessageDeltaPayload: Codable, Equatable {
    public let conversationID: String?
    public let messageID: String
    public let clientMessageID: String?
    public let delta: String

    public init(
        conversationID: String? = nil,
        messageID: String,
        clientMessageID: String? = nil,
        delta: String
    ) {
        self.conversationID = conversationID
        self.messageID = messageID
        self.clientMessageID = clientMessageID
        self.delta = delta
    }

    private enum CodingKeys: String, CodingKey {
        case conversationID = "conversation_id"
        case messageID = "message_id"
        case clientMessageID = "client_msg_id"
        case delta
    }
}

public struct MessageCompletedPayload: Codable, Equatable {
    public let conversationID: String?
    public let messageID: String
    public let clientMessageID: String?
    public let text: String?

    public init(
        conversationID: String? = nil,
        messageID: String,
        clientMessageID: String? = nil,
        text: String? = nil
    ) {
        self.conversationID = conversationID
        self.messageID = messageID
        self.clientMessageID = clientMessageID
        self.text = text
    }

    private enum CodingKeys: String, CodingKey {
        case conversationID = "conversation_id"
        case messageID = "message_id"
        case clientMessageID = "client_msg_id"
        case text
    }
}

public struct MessageFailedPayload: Codable, Equatable {
    public let messageID: String
    public let error: ErrorPayload

    public init(messageID: String, error: ErrorPayload) {
        self.messageID = messageID
        self.error = error
    }

    private enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case error
    }
}

public struct TaskStartedPayload: Codable, Equatable {
    public let taskID: String
    public let title: String

    public init(taskID: String, title: String) {
        self.taskID = taskID
        self.title = title
    }

    private enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case title
    }
}

public struct TaskProgressPayload: Codable, Equatable {
    public let taskID: String
    public let progress: Double
    public let message: String

    public init(taskID: String, progress: Double, message: String) {
        self.taskID = taskID
        self.progress = progress
        self.message = message
    }

    private enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case progress
        case message
    }
}

public struct TaskCompletedPayload: Codable, Equatable {
    public let taskID: String
    public let result: String

    public init(taskID: String, result: String) {
        self.taskID = taskID
        self.result = result
    }

    private enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case result
    }
}

public struct TaskFailedPayload: Codable, Equatable {
    public let taskID: String
    public let error: ErrorPayload

    public init(taskID: String, error: ErrorPayload) {
        self.taskID = taskID
        self.error = error
    }

    private enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case error
    }
}

public struct TaskCancelledPayload: Codable, Equatable {
    public let taskID: String
    public let reason: String

    public init(taskID: String, reason: String) {
        self.taskID = taskID
        self.reason = reason
    }

    private enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case reason
    }
}

public struct TaskRequiresApprovalPayload: Codable, Equatable {
    public let taskID: String
    public let approvalID: String
    public let prompt: String
    public let actions: [String]
    public let expiresAt: String?

    public init(
        taskID: String,
        approvalID: String,
        prompt: String,
        actions: [String],
        expiresAt: String? = nil
    ) {
        self.taskID = taskID
        self.approvalID = approvalID
        self.prompt = prompt
        self.actions = actions
        self.expiresAt = expiresAt
    }

    private enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case approvalID = "approval_id"
        case prompt
        case actions
        case expiresAt = "expires_at"
    }
}

public struct ApprovalDecisionRequest: Codable, Equatable {
    public let approvalID: String
    public let taskID: String
    public let decision: ApprovalDecision

    public init(approvalID: String, taskID: String, decision: ApprovalDecision) {
        self.approvalID = approvalID
        self.taskID = taskID
        self.decision = decision
    }

    private enum CodingKeys: String, CodingKey {
        case approvalID = "approval_id"
        case taskID = "task_id"
        case decision
    }
}

public enum ApprovalDecision: String, Codable, Equatable {
    case approve
    case reject
}

public struct NotificationCreatedPayload: Codable, Equatable {
    public let notificationID: String
    public let title: String
    public let body: String

    public init(notificationID: String, title: String, body: String) {
        self.notificationID = notificationID
        self.title = title
        self.body = body
    }

    private enum CodingKeys: String, CodingKey {
        case notificationID = "notification_id"
        case title
        case body
    }
}

public struct AgentPresencePayload: Codable, Equatable {
    public let agentID: String
    public let name: String?
    public let reason: String?

    public init(agentID: String, name: String? = nil, reason: String? = nil) {
        self.agentID = agentID
        self.name = name
        self.reason = reason
    }

    private enum CodingKeys: String, CodingKey {
        case agentID = "agent_id"
        case name
        case reason
    }
}

public struct SystemErrorPayload: Codable, Equatable {
    public let error: ErrorPayload

    public init(error: ErrorPayload) {
        self.error = error
    }
}

public struct ErrorPayload: Codable, Equatable {
    public let code: String
    public let message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}
