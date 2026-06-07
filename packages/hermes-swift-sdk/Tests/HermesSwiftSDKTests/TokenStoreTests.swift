import Testing
@testable import HermesSwiftSDK

struct TokenStoreTests {
    @Test func inMemoryTokenStoreSavesLoadsAndClearsToken() async throws {
        let store: KeychainTokenStore = InMemoryTokenStore()

        #expect(try await store.loadToken() == nil)

        try await store.saveToken("token_123")
        #expect(try await store.loadToken() == "token_123")

        try await store.clearToken()
        #expect(try await store.loadToken() == nil)
    }
}
