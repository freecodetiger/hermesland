import Foundation

public enum AppConnectionState: Equatable, Sendable {
    case offline
    case connecting
    case onlineIdle
    case running
    case needsApproval
    case error(String)
}
