import EfficiencyCore
import Foundation
import Supabase

struct SupabaseAppService {
    private let configuration: AppConfiguration

    init(configuration: AppConfiguration = .current) {
        self.configuration = configuration
    }

    var isConfigured: Bool {
        configuration.supabaseURL != nil && configuration.supabasePublishableKey != nil
    }

    func client() throws -> SupabaseClient {
        guard let url = configuration.supabaseURL,
              let key = configuration.supabasePublishableKey
        else {
            throw SyncError.missingSupabaseConfiguration
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    func sendMagicLink(to email: String) async throws {
        let client = try client()
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "ticked://auth-callback"),
            shouldCreateUser: true
        )
    }

    func handleAuthCallback(_ url: URL) async throws {
        let client = try client()
        try await client.auth.session(from: url)
    }

    func currentSessionEmail() throws -> String? {
        try client().auth.currentUser?.email
    }

    func listConnections() async throws -> [IntegrationConnection] {
        let client = try client()
        return try await client
            .from("integration_connections")
            .select()
            .order("provider")
            .order("account_label")
            .execute()
            .value
    }

    func disableConnection(_ connection: IntegrationConnection) async throws {
        let client = try client()
        try await client
            .from("integration_connections")
            .update(ConnectionStatusUpdate(status: .disabled), returning: .minimal)
            .eq("id", value: connection.id.uuidString)
            .execute()
    }

    func startOAuth(for provider: EfficiencyCore.Provider) async throws -> URL {
        let client = try client()
        let response: OAuthStartResponse = try await client.functions.invoke(
            "oauth-start",
            options: .init(
                method: .get,
                query: [URLQueryItem(name: "provider", value: provider.rawValue)]
            )
        )
        return response.authorizeURL
    }

    func storeTrelloToken(_ token: String, state: String?) async throws {
        let client = try client()
        try await client.functions.invoke(
            "trello-store-token",
            options: .init(method: .post, body: TrelloStoreTokenRequest(token: token, state: state))
        )
    }
}

struct OAuthStartResponse: Decodable {
    let authorizeURL: URL

    enum CodingKeys: String, CodingKey {
        case authorizeURL = "authorize_url"
    }
}

struct TrelloStoreTokenRequest: Encodable {
    let token: String
    let state: String?
}

private struct ConnectionStatusUpdate: Encodable {
    let status: ConnectionStatus
}
