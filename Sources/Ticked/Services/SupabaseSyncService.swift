import Foundation
import Supabase

struct SupabaseSyncService {
    private let configuration: AppConfiguration

    init(configuration: AppConfiguration = .current) {
        self.configuration = configuration
    }

    func syncNow() async throws {
        guard let url = configuration.supabaseURL,
              let key = configuration.supabasePublishableKey
        else {
            throw SyncError.missingSupabaseConfiguration
        }

        let client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        _ = try await client.functions.invoke("sync-now")
    }
}

enum SyncError: LocalizedError {
    case missingSupabaseConfiguration

    var errorDescription: String? {
        switch self {
        case .missingSupabaseConfiguration:
            "Supabase URL or publishable key is missing"
        }
    }
}

