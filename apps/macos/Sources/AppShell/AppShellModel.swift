import Combine
import Foundation

@MainActor
public final class AppShellModel: ObservableObject {
    @Published public private(set) var connectionState: AppConnectionState
    @Published public private(set) var route: AppRoute

    public init(
        connectionState: AppConnectionState = .offline,
        route: AppRoute = .chat
    ) {
        self.connectionState = connectionState
        self.route = route
    }

    public func send(_ command: AppCommand) {
        switch command {
        case let .open(route):
            self.route = route
        case .connect:
            connectionState = .connecting
        case .disconnect:
            connectionState = .offline
        case .startRun:
            connectionState = .running
        case .stopRun:
            connectionState = .onlineIdle
        case .approve:
            connectionState = .running
        case .reject:
            connectionState = .onlineIdle
        case .quit:
            break
        }
    }

    public func updateConnectionState(_ state: AppConnectionState) {
        connectionState = state
    }
}
