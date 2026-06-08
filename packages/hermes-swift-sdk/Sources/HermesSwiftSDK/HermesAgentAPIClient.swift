import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct HermesAgentHealthResponse: Codable, Equatable {
    public let status: String
    public let platform: String?

    public init(status: String, platform: String? = nil) {
        self.status = status
        self.platform = platform
    }
}

public struct HermesAgentModelsResponse: Codable, Equatable {
    public let object: String
    public let data: [HermesAgentModel]

    public init(object: String, data: [HermesAgentModel]) {
        self.object = object
        self.data = data
    }
}

public struct HermesAgentModel: Codable, Equatable {
    public let id: String
    public let object: String
    public let created: Int64?
    public let ownedBy: String?
    public let root: String?
    public let parent: String?

    public init(
        id: String,
        object: String,
        created: Int64? = nil,
        ownedBy: String? = nil,
        root: String? = nil,
        parent: String? = nil
    ) {
        self.id = id
        self.object = object
        self.created = created
        self.ownedBy = ownedBy
        self.root = root
        self.parent = parent
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case ownedBy = "owned_by"
        case root
        case parent
    }
}

public struct HermesAgentRunResponse: Codable, Equatable {
    public let runID: String
    public let status: String

    public init(runID: String, status: String) {
        self.runID = runID
        self.status = status
    }

    private enum CodingKeys: String, CodingKey {
        case runID = "run_id"
        case status
    }
}

public final class HermesAgentAPIClient {
    private let baseURL: URL
    private let apiKey: String
    private let transport: HermesHTTPTransport
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        baseURL: URL,
        apiKey: String,
        transport: HermesHTTPTransport = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.transport = transport
        self.decoder = decoder
        self.encoder = encoder
    }

    public func health() async throws -> HermesAgentHealthResponse {
        try await send(path: "/health", method: "GET", requiresAuth: false)
    }

    public func models() async throws -> HermesAgentModelsResponse {
        try await send(path: "/v1/models", method: "GET")
    }

    public func capabilities() async throws -> JSONValue {
        try await send(path: "/v1/capabilities", method: "GET")
    }

    public func startRun(
        input: String,
        model: String,
        sessionID: String? = nil
    ) async throws -> HermesAgentRunResponse {
        var headers: [String: String] = [:]
        if let sessionID, !sessionID.isEmpty {
            headers["X-Hermes-Session-Id"] = sessionID
        }
        return try await send(
            path: "/v1/runs",
            method: "POST",
            headers: headers,
            body: StartRunRequest(input: input, model: model)
        )
    }

    public func runStatus(runID: String) async throws -> JSONValue {
        try await send(path: "/v1/runs/\(Self.encodePath(runID))", method: "GET")
    }

    public func fetchRunEventsText(runID: String) async throws -> String {
        let request = try makeRequest(
            path: "/v1/runs/\(Self.encodePath(runID))/events",
            method: "GET",
            headers: ["Accept": "text/event-stream"],
            requiresAuth: true
        )
        let data = try await responseData(for: request)
        return String(decoding: data, as: UTF8.self)
    }

    public func stopRun(runID: String) async throws -> HermesAgentRunResponse {
        try await send(path: "/v1/runs/\(Self.encodePath(runID))/stop", method: "POST")
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        headers: [String: String] = [:],
        requiresAuth: Bool = true
    ) async throws -> Response {
        let request = try makeRequest(
            path: path,
            method: method,
            headers: headers,
            requiresAuth: requiresAuth
        )
        return try decoder.decode(Response.self, from: try await responseData(for: request))
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        headers: [String: String] = [:],
        requiresAuth: Bool = true,
        body: Body
    ) async throws -> Response {
        var request = try makeRequest(
            path: path,
            method: method,
            headers: headers,
            requiresAuth: requiresAuth
        )
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try decoder.decode(Response.self, from: try await responseData(for: request))
    }

    private func makeRequest(
        path: String,
        method: String,
        headers: [String: String],
        requiresAuth: Bool
    ) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let requestPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [basePath, requestPath].filter { !$0.isEmpty }.joined(separator: "/")

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(headers["Accept"] ?? "application/json", forHTTPHeaderField: "Accept")
        if requiresAuth {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        for (key, value) in headers where key != "Accept" {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }

    private func responseData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await transport.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw HermesHTTPError(
                statusCode: httpResponse.statusCode,
                body: String(decoding: data, as: UTF8.self)
            )
        }
        return data
    }

    private static func encodePath(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}

private struct StartRunRequest: Codable, Equatable {
    let input: String
    let model: String
}
