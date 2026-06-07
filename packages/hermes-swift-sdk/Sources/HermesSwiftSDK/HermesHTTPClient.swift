import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum JSONValue: Codable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    public var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    public var numberValue: Double? {
        if case .number(let value) = self {
            return value
        }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }

    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }

    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self {
            return value
        }
        return nil
    }
}

public struct HermesHealthResponse: Codable, Equatable {
    public let status: String

    public init(status: String) {
        self.status = status
    }
}

public struct DeviceAuthStartResponse: Codable, Equatable {
    public let deviceCode: String
    public let token: String

    public init(deviceCode: String, token: String) {
        self.deviceCode = deviceCode
        self.token = token
    }

    private enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case token
    }
}

public struct HermesHTTPError: Error, Equatable {
    public let statusCode: Int
    public let body: String

    public init(statusCode: Int, body: String) {
        self.statusCode = statusCode
        self.body = body
    }
}

public protocol HermesHTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HermesHTTPTransport {}

public final class HermesHTTPClient {
    public typealias GenericEventEnvelope = EventEnvelope<JSONValue>

    private let baseURL: URL
    private let transport: HermesHTTPTransport
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        baseURL: URL,
        transport: HermesHTTPTransport = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.transport = transport
        self.decoder = decoder
        self.encoder = encoder
    }

    public func health() async throws -> HermesHealthResponse {
        try await send(path: "/healthz", method: "GET")
    }

    public func startDeviceAuth(
        deviceName: String,
        clientID: String
    ) async throws -> DeviceAuthStartResponse {
        try await send(
            path: "/v1/auth/device/start",
            method: "POST",
            body: DeviceAuthStartRequest(deviceName: deviceName, clientID: clientID)
        )
    }

    public func sendMessage(
        conversationID: String,
        clientMessageID: String,
        content: String
    ) async throws -> [GenericEventEnvelope] {
        let response: EventsResponse = try await send(
            path: "/v1/messages",
            method: "POST",
            body: SendMessageRequest(
                conversationID: conversationID,
                clientMessageID: clientMessageID,
                content: content
            )
        )
        return response.events
    }

    public func fetchEvents(afterSeq: Int64) async throws -> [GenericEventEnvelope] {
        let response: EventsResponse = try await send(
            path: "/v1/events",
            method: "GET",
            queryItems: [URLQueryItem(name: "after_seq", value: String(afterSeq))]
        )
        return response.events
    }

    public func runTask(mode: String) async throws -> [GenericEventEnvelope] {
        let response: EventsResponse = try await send(
            path: "/v1/tasks/run",
            method: "POST",
            body: RunTaskRequest(mode: mode)
        )
        return response.events
    }

    public func resolveApproval(
        approvalID: String,
        decision: ApprovalDecision
    ) async throws -> [GenericEventEnvelope] {
        let action = decision == .approve ? "approve" : "reject"
        let encodedApprovalID = approvalID.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) ?? approvalID
        let response: EventsResponse = try await send(
            path: "/v1/approvals/\(encodedApprovalID)/\(action)",
            method: "POST"
        )
        return response.events
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        let request = try makeRequest(path: path, method: method, queryItems: queryItems)
        return try await decode(request)
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Body
    ) async throws -> Response {
        var request = try makeRequest(path: path, method: method, queryItems: queryItems)
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await decode(request)
    }

    private func makeRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let requestPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [basePath, requestPath].filter { !$0.isEmpty }.joined(separator: "/")
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func decode<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await transport.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw HermesHTTPError(
                statusCode: httpResponse.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }

        return try decoder.decode(Response.self, from: data)
    }
}

private struct DeviceAuthStartRequest: Encodable {
    let deviceName: String
    let clientID: String

    private enum CodingKeys: String, CodingKey {
        case deviceName = "device_name"
        case clientID = "client_id"
    }
}

private struct SendMessageRequest: Encodable {
    let conversationID: String
    let clientMessageID: String
    let content: String

    private enum CodingKeys: String, CodingKey {
        case conversationID = "conversation_id"
        case clientMessageID = "client_msg_id"
        case content
    }
}

private struct RunTaskRequest: Encodable {
    let mode: String
}

private struct EventsResponse: Decodable {
    let events: [EventEnvelope<JSONValue>]
}
