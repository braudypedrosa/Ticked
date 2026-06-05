import EfficiencyCore
import Foundation

struct AppConfiguration {
    static let current = AppConfiguration(environment: ProcessInfo.processInfo.environment)

    let supabaseURL: URL?
    let supabasePublishableKey: String?

    init(environment: [String: String]) {
        supabaseURL = environment["TICKED_SUPABASE_URL"].flatMap(URL.init(string:))
        supabasePublishableKey = environment["TICKED_SUPABASE_PUBLISHABLE_KEY"]?.nilIfBlank
    }
}
