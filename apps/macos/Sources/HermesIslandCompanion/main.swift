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
case "agent-live":
    let env = ProcessInfo.processInfo.environment
    let baseURL = URL(string: env["HERMES_AGENT_GATEWAY_URL"] ?? "http://127.0.0.1:8650")!
    guard let apiKey = env["HERMES_AGENT_API_KEY"], !apiKey.isEmpty else {
        fputs("Missing HERMES_AGENT_API_KEY\n", stderr)
        Foundation.exit(78)
    }
    let model = env["HERMES_AGENT_MODEL"] ?? "hermes-zpc"
    let sessionID = env["HERMES_AGENT_SESSION_ID"]
    let prompt = CommandLine.arguments.dropFirst(2).joined(separator: " ")
    let effectivePrompt = prompt.isEmpty ? "Reply with a short Hermes Island connectivity check." : prompt
    do {
        let client = HermesAgentAPIClient(baseURL: baseURL, apiKey: apiKey)
        let result = try await HermesAgentLiveDemo(
            client: client,
            model: model,
            sessionID: sessionID
        ).run(prompt: effectivePrompt)
        print("Hermes Island Agent Live")
        print("gateway=\(baseURL.absoluteString)")
        print("health=\(result.healthStatus)")
        print("model=\(result.modelID)")
        print("run=\(result.runID)")
        print("events=\(result.eventCount)")
        print("island=\(result.finalIslandTitle)")
        print("tasks=\(result.taskCount)")
        print("notifications=\(result.notificationCount)")
    } catch {
        fputs("Agent live demo failed: \(error)\n", stderr)
        Foundation.exit(1)
    }
case "help":
    print("Usage: hermes-island-companion [demo|live|agent-live|help]")
default:
    fputs("Unknown command: \(command)\n", stderr)
    fputs("Usage: hermes-island-companion [demo|live|agent-live|help]\n", stderr)
    Foundation.exit(64)
}
