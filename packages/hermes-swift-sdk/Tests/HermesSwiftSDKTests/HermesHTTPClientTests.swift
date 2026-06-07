import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import HermesSwiftSDK

struct HermesHTTPClientTests {
    @Test func healthGetsGatewayHealth() async throws {
        let transport = TestHTTPTransport { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/healthz")
            return TestHTTPResponse(body: #"{"status":"ok"}"#)
        }
        let client = HermesHTTPClient(baseURL: URL(string: "http://gateway.test")!, transport: transport)

        let health = try await client.health()

        #expect(health.status == "ok")
    }

    @Test func startDeviceAuthPostsDeviceNameAndClientID() async throws {
        let transport = TestHTTPTransport { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/auth/device/start")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try request.jsonBody()
            #expect(body["device_name"] as? String == "MacBook Pro")
            #expect(body["client_id"] as? String == "macos-companion")
            return TestHTTPResponse(body: #"{"device_code":"device-123","token":"token-abc"}"#)
        }
        let client = HermesHTTPClient(baseURL: URL(string: "http://gateway.test")!, transport: transport)

        let response = try await client.startDeviceAuth(
            deviceName: "MacBook Pro",
            clientID: "macos-companion"
        )

        #expect(response.deviceCode == "device-123")
        #expect(response.token == "token-abc")
    }

    @Test func sendMessagePostsMessageAndDecodesEvents() async throws {
        let transport = TestHTTPTransport { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/messages")
            let body = try request.jsonBody()
            #expect(body["conversation_id"] as? String == "conv-1")
            #expect(body["client_msg_id"] as? String == "client-msg-1")
            #expect(body["content"] as? String == "hello")
            return TestHTTPResponse(body: """
            {
              "accepted": true,
              "events": [
                {
                  "event_id": "evt_000001",
                  "seq": 1,
                  "type": "message.accepted",
                  "created_at": "2026-06-08T00:00:00.000Z",
                  "payload": {
                    "conversation_id": "conv-1",
                    "message_id": "msg_1",
                    "client_msg_id": "client-msg-1"
                  }
                }
              ]
            }
            """)
        }
        let client = HermesHTTPClient(baseURL: URL(string: "http://gateway.test")!, transport: transport)

        let events = try await client.sendMessage(
            conversationID: "conv-1",
            clientMessageID: "client-msg-1",
            content: "hello"
        )

        #expect(events.map(\.eventID) == ["evt_000001"])
        #expect(events.map(\.seq) == [1])
        #expect(events.map(\.type) == [.messageAccepted])
        #expect(events.first?.createdAt == "2026-06-08T00:00:00.000Z")
        #expect(events.first?.payload.objectValue?["message_id"]?.stringValue == "msg_1")
    }

    @Test func fetchEventsGetsAfterSeqAndDecodesPayloadValues() async throws {
        let transport = TestHTTPTransport { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/v1/events")
            #expect(request.url?.query == "after_seq=41")
            return TestHTTPResponse(body: """
            {
              "events": [
                {
                  "event_id": "evt_000042",
                  "seq": 42,
                  "type": "task.progress",
                  "created_at": "2026-06-08T00:00:00.000Z",
                  "payload": {
                    "task_id": "task_1",
                    "progress": 0.5,
                    "message": "Halfway"
                  }
                }
              ]
            }
            """)
        }
        let client = HermesHTTPClient(baseURL: URL(string: "http://gateway.test")!, transport: transport)

        let events = try await client.fetchEvents(afterSeq: 41)

        #expect(events.first?.eventID == "evt_000042")
        #expect(events.first?.seq == 42)
        #expect(events.first?.type == .taskProgress)
        #expect(events.first?.payload.objectValue?["progress"]?.numberValue == 0.5)
        #expect(events.first?.payload.objectValue?["message"]?.stringValue == "Halfway")
    }

    @Test func runTaskPostsModeAndReturnsEvents() async throws {
        let transport = TestHTTPTransport { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/tasks/run")
            let body = try request.jsonBody()
            #expect(body["mode"] as? String == "success")
            return TestHTTPResponse(body: """
            {
              "task": {
                "task_id": "task_1",
                "mode": "success",
                "status": "completed",
                "title": "Mock success task"
              },
              "events": [
                {
                  "event_id": "evt_1",
                  "seq": 1,
                  "type": "task.completed",
                  "created_at": "2026-06-08T00:00:00.000Z",
                  "payload": {
                    "task_id": "task_1",
                    "result": "done"
                  }
                }
              ]
            }
            """)
        }
        let client = HermesHTTPClient(baseURL: URL(string: "http://gateway.test")!, transport: transport)

        let events = try await client.runTask(mode: "success")

        #expect(events.first?.type == .taskCompleted)
        #expect(events.first?.payload.objectValue?["result"]?.stringValue == "done")
    }

    @Test func resolveApprovalPostsDecisionPathAndReturnsEvents() async throws {
        let transport = TestHTTPTransport { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/v1/approvals/approval%201/reject")
            #expect((request.httpBody ?? Data()).isEmpty)
            return TestHTTPResponse(body: """
            {
              "approval": {
                "approval_id": "approval 1",
                "task_id": "task_1",
                "status": "rejected",
                "prompt": "Approve mock task?",
                "actions": ["approve", "reject"]
              },
              "events": [
                {
                  "event_id": "evt_2",
                  "seq": 2,
                  "type": "task.cancelled",
                  "created_at": "2026-06-08T00:00:00.000Z",
                  "payload": {
                    "task_id": "task_1",
                    "reason": "Approval rejected."
                  }
                }
              ]
            }
            """)
        }
        let client = HermesHTTPClient(baseURL: URL(string: "http://gateway.test")!, transport: transport)

        let events = try await client.resolveApproval(approvalID: "approval 1", decision: .reject)

        #expect(events.first?.eventID == "evt_2")
        #expect(events.first?.type == .taskCancelled)
        #expect(events.first?.payload.objectValue?["reason"]?.stringValue == "Approval rejected.")
    }

    @Test func throwsHTTPErrorForNonSuccessResponse() async throws {
        let transport = TestHTTPTransport { _ in
            TestHTTPResponse(statusCode: 409, body: #"{"error":"approval_already_resolved"}"#)
        }
        let client = HermesHTTPClient(baseURL: URL(string: "http://gateway.test")!, transport: transport)

        do {
            _ = try await client.resolveApproval(approvalID: "approval_1", decision: .approve)
            Issue.record("Expected non-2xx response to throw")
        } catch let error as HermesHTTPError {
            #expect(error.statusCode == 409)
            #expect(error.body == #"{"error":"approval_already_resolved"}"#)
        }
    }
}

private struct TestHTTPResponse {
    var statusCode = 200
    var body: String
}

private struct TestHTTPTransport: HermesHTTPTransport {
    let handler: (URLRequest) async throws -> TestHTTPResponse

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
