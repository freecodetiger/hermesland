import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HermesIslandCompanionCore
import HermesSwiftSDK
import Testing

struct HermesAgentLiveDemoTests {
    @Test func agentLiveDemoRunsAgainstMockTransportAndUpdatesUIState() async throws {
        let transport = AgentSequenceTransport(responses: [
            #"{"status":"ok","platform":"hermes-agent"}"#,
            """
            {
              "object": "list",
              "data": [
                {
                  "id": "hermes-zpc",
                  "object": "model",
                  "created": 1,
                  "owned_by": "hermes",
                  "permission": [],
                  "root": "hermes-zpc",
                  "parent": null
                }
              ]
            }
            """,
            #"{"run_id":"run_1","status":"started"}"#,
            """
            data: {"event":"message.delta","run_id":"run_1","delta":"hello"}

            data: {"event":"run.completed","run_id":"run_1","output":"done"}

            """,
        ])
        let client = HermesAgentAPIClient(
            baseURL: URL(string: "http://agent.test")!,
            apiKey: "secret",
            transport: transport
        )

        let result = try await HermesAgentLiveDemo(
            client: client,
            model: "hermes-zpc",
            sessionID: "session-1"
        ).run(prompt: "hello")

        #expect(result.healthStatus == "ok")
        #expect(result.modelID == "hermes-zpc")
        #expect(result.runID == "run_1")
        #expect(result.eventCount == 6)
        #expect(result.finalIslandTitle == "Task completed")
        #expect(result.taskCount == 1)
        #expect(result.notificationCount == 1)
        #expect(await transport.paths == [
            "/health",
            "/v1/models",
            "/v1/runs",
            "/v1/runs/run_1/events",
        ])
    }
}

private actor AgentSequenceTransport: HermesHTTPTransport {
    private var responses: [String]
    private(set) var paths: [String] = []

    init(responses: [String]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        paths.append(request.url!.path + (request.url!.query.map { "?\($0)" } ?? ""))
        let body = responses.removeFirst()
        let statusCode = request.url!.path == "/v1/runs" ? 202 : 200
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(body.utf8), response)
    }
}
