import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import HermesSwiftSDK

struct HermesAgentAPIClientTests {
    @Test func healthUsesAgentHealthPath() async throws {
        let transport = AgentTestHTTPTransport { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/health")
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            return AgentTestHTTPResponse(body: #"{"status":"ok","platform":"hermes-agent"}"#)
        }
        let client = HermesAgentAPIClient(
            baseURL: URL(string: "http://agent.test")!,
            apiKey: "secret",
            transport: transport
        )

        let health = try await client.health()

        #expect(health.status == "ok")
        #expect(health.platform == "hermes-agent")
    }

    @Test func modelsSendsBearerTokenAndDecodesModelID() async throws {
        let transport = AgentTestHTTPTransport { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/v1/models")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
            return AgentTestHTTPResponse(body: """
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
            """)
        }
        let client = HermesAgentAPIClient(
            baseURL: URL(string: "http://agent.test")!,
            apiKey: "secret",
            transport: transport
        )

        let models = try await client.models()

        #expect(models.data.map(\.id) == ["hermes-zpc"])
        #expect(models.data.first?.ownedBy == "hermes")
    }

    @Test func startRunPostsInputModelAndSessionHeader() async throws {
        let transport = AgentTestHTTPTransport { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/runs")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
            #expect(request.value(forHTTPHeaderField: "X-Hermes-Session-Id") == "session-1")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try request.jsonBody()
            #expect(body["input"] as? String == "hello")
            #expect(body["model"] as? String == "hermes-zpc")
            return AgentTestHTTPResponse(statusCode: 202, body: #"{"run_id":"run_123","status":"started"}"#)
        }
        let client = HermesAgentAPIClient(
            baseURL: URL(string: "http://agent.test")!,
            apiKey: "secret",
            transport: transport
        )

        let run = try await client.startRun(
            input: "hello",
            model: "hermes-zpc",
            sessionID: "session-1"
        )

        #expect(run.runID == "run_123")
        #expect(run.status == "started")
    }

    @Test func fetchRunEventsTextGetsSSEEndpointWithBearerToken() async throws {
        let transport = AgentTestHTTPTransport { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/v1/runs/run_123/events")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
            #expect(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
            return AgentTestHTTPResponse(body: #"data: {"event":"run.completed","run_id":"run_123"}"#)
        }
        let client = HermesAgentAPIClient(
            baseURL: URL(string: "http://agent.test")!,
            apiKey: "secret",
            transport: transport
        )

        let text = try await client.fetchRunEventsText(runID: "run_123")

        #expect(text.contains("run.completed"))
    }

    @Test func throwsHTTPErrorForAgentNonSuccessResponse() async throws {
        let transport = AgentTestHTTPTransport { _ in
            AgentTestHTTPResponse(statusCode: 401, body: #"{"error":{"message":"Invalid API key"}}"#)
        }
        let client = HermesAgentAPIClient(
            baseURL: URL(string: "http://agent.test")!,
            apiKey: "bad",
            transport: transport
        )

        do {
            _ = try await client.models()
            Issue.record("Expected non-2xx response to throw")
        } catch let error as HermesHTTPError {
            #expect(error.statusCode == 401)
            #expect(error.body.contains("Invalid API key"))
        }
    }
}

private struct AgentTestHTTPResponse {
    var statusCode = 200
    var body: String
}

private struct AgentTestHTTPTransport: HermesHTTPTransport {
    let handler: (URLRequest) async throws -> AgentTestHTTPResponse

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = try await handler(request)
        let urlResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: response.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(response.body.utf8), urlResponse)
    }
}

private extension URLRequest {
    func jsonBody() throws -> [String: Any] {
        let data = httpBody ?? Data()
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }
}
