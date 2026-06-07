public protocol KeychainTokenStore {
    func saveToken(_ token: String) async throws
    func loadToken() async throws -> String?
    func clearToken() async throws
}

public actor InMemoryTokenStore: KeychainTokenStore {
    private var token: String?

    public init(token: String? = nil) {
        self.token = token
    }

    public func saveToken(_ token: String) {
        self.token = token
    }

    public func loadToken() -> String? {
        token
    }

    public func clearToken() {
        token = nil
    }
}
