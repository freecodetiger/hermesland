import Foundation

public enum AppRoute: Equatable, Sendable {
    case chat
    case tasks
    case notifications
    case settings
}

public enum AppCommand: Equatable, Sendable {
    case open(AppRoute)
    case connect
    case disconnect
    case startRun
    case stopRun
    case approve
    case reject
    case quit
}
