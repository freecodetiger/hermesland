import Foundation
import HermesIslandCompanionCore
import HermesSwiftSDK
import Testing

struct LiveGatewayDemoTests {
    @Test func liveDemoRunsAgainstMockTransportAndUpdatesUIState() async throws {
        let transport = SequenceTransport(responses: [
            #"{"status":"ok"}"#,
            #"{"device_code":"device-code","token":"token-123"}"#,
            eventsResponse([
                event(seq: 1, type: "message.accepted", payload: [
                    "conversation_id": "conv-companion",
                    "message_id": "msg-1",
                    "client_msg_id": "client-1",
                ]),
                event(seq: 2, type: "message.delta", payload: [
                    "conversation_id": "conv-companion",
                    "message_id": "msg-1",
                    "client_msg_id": "client-1",
                    "delta": "Hello",
                ]),
                event(seq: 3, type: "message.completed", payload: [
                    "conversation_id": "conv-companion",
                    "message_id": "msg-1",
                    "client_msg_id": "client-1",
                ]),
            ]),
            eventsResponse([
                event(seq: 4, type: "task.started", payload: [
                    "task_id": "task-1",
                    "title": "Mock approval task",
                ]),
                event(seq: 5, type: "task.requires_approval", payload: [
                    "task_id": "task-1",
                    "approval_id": "approval-1",
                    "prompt": "Approve mock task?",
                    "actions": ["approve", "reject"],
                ]),
            ]),
            eventsResponse([
                event(seq: 1, type: "message.accepted", payload: ["message_id": "msg-1"]),
                event(seq: 4, type: "task.started", payload: [
                    "task_id": "task-1",
                    "title": "Mock approval task",
                ]),
                event(seq: 5, type: "task.requires_approval", payload: [
                    "task_id": "task-1",
                    "approval_id": "approval-1",
                    "prompt": "Approve mock task?",
                ]),
            ]),
            eventsResponse([
                event(seq: 6, type: "task.progress", payload: [
                    "task_id": "task-1",
                    "progress": 1,
                    "message": "Approval granted.",
                ]),
                event(seq: 7, type: "task.completed", payload: [
                    "task_id": "task-1",
                    "result": "Mock task approved and completed.",
                ]),
            ]),
        ])
        let client = HermesHTTPClient(
            baseURL: URL(string: "http://gateway.test")!,
            transport: transport
        )

        let result = try await LiveGatewayDemo(client: client).run()

        #expect(result.healthStatus == "ok")
        #expect(result.token == "token-123")
        #expect(result.messageEventCount == 3)
        #expect(result.approvalEventCount == 2)
        #expect(result.finalIslandTitle == "Task completed")
        #expect(result.taskCount == 1)
        #expect(result.notificationCount == 1)
        #expect(await transport.paths == [
            "/healthz",
            "/v1/auth/device/start",
            "/v1/messages",
            "/v1/tasks/run",
            "/v1/events?after_seq=0",
            "/v1/approvals/approval-1/approve",
        ])
    }
}

private actor SequenceTransport: HermesHTTPTransport {
    private var responses: [String]
    private(set) var paths: [String] = []

    init(responses: [String]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        paths.append(request.url!.path + (request.url!.query.map { "?\($0)" } ?? ""))
        let body = responses.removeFirst()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(body.utf8), response)
    }
}

private func eventsResponse(_ events: [String]) -> String {
    #"{"events":["# + events.joined(separator: ",") + "]}"
}

private func event(seq: Int, type: String, payload: [String: Any]) -> String {
    let payloadData = try! JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
    let payloadString = String(data: payloadData, encoding: .utf8)!
    return """
    {
      "event_id": "evt_\(seq)",
      "seq": \(seq),
      "type": "\(type)",
      "created_at": "2026-06-08T00:00:00.000Z",
      "payload": \(payloadString)
    }
    """
}
