import Foundation
import HermesIslandCompanionCore

let command = CommandLine.arguments.dropFirst().first ?? "demo"

switch command {
case "demo":
    let result = CompanionDemo().run()
    print("Hermes Island Companion")
    print("state=\(result.connectionState)")
    print("island=\(result.islandTitle)")
    print("tasks=\(result.taskCount)")
    print("notifications=\(result.notificationCount)")
case "help":
    print("Usage: hermes-island-companion [demo|help]")
default:
    fputs("Unknown command: \(command)\n", stderr)
    fputs("Usage: hermes-island-companion [demo|help]\n", stderr)
    Foundation.exit(64)
}
