import Foundation
import HermesIslandCompanionCore
import HermesSwiftSDK

let command = CommandLine.arguments.dropFirst().first ?? "demo"

switch command {
case "demo":
    let result = CompanionDemo().run()
    print("Hermes Island Companion")
    print("state=\(result.connectionState)")
    print("island=\(result.islandTitle)")
    print("tasks=\(result.taskCount)")
    print("notifications=\(result.notificationCount)")
case "live":
    let baseURL = URL(string: ProcessInfo.processInfo.environment["HERMES_GATEWAY_URL"] ?? "http://127.0.0.1:8787")!
    do {
        let result = try await LiveGatewayDemo(client: HermesHTTPClient(baseURL: baseURL)).run()
        print("Hermes Island Companion Live")
        print("gateway=\(baseURL.absoluteString)")
        print("health=\(result.healthStatus)")
        print("token=\(result.token)")
        print("messageEvents=\(result.messageEventCount)")
        print("approvalEvents=\(result.approvalEventCount)")
        print("island=\(result.finalIslandTitle)")
        print("tasks=\(result.taskCount)")
        print("notifications=\(result.notificationCount)")
    } catch {
        fputs("Live demo failed: \(error)\n", stderr)
        Foundation.exit(1)
    }
case "help":
    print("Usage: hermes-island-companion [demo|live|help]")
default:
    fputs("Unknown command: \(command)\n", stderr)
    fputs("Usage: hermes-island-companion [demo|live|help]\n", stderr)
    Foundation.exit(64)
}
