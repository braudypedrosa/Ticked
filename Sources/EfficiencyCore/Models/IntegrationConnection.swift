import Foundation

public enum ConnectionStatus: String, Codable, Hashable, Sendable {
    case active
    case needsReauth = "needs_reauth"
    case disabled

    public var displayName: String {
        switch self {
        case .active: "Active"
        case .needsReauth: "Reconnect"
        case .disabled: "Disabled"
        }
    }
}

public struct IntegrationConnection: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let userID: UUID
    public let provider: Provider
    public var accountLabel: String
    public var externalAccountID: String?
    public var externalAccountURL: URL?
    public var status: ConnectionStatus
    public var scopes: [String]
    public var lastSyncedAt: Date?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        provider: Provider,
        accountLabel: String,
        externalAccountID: String? = nil,
        externalAccountURL: URL? = nil,
        status: ConnectionStatus = .active,
        scopes: [String] = [],
        lastSyncedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.provider = provider
        self.accountLabel = accountLabel
        self.externalAccountID = externalAccountID
        self.externalAccountURL = externalAccountURL
        self.status = status
        self.scopes = scopes
        self.lastSyncedAt = lastSyncedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isActive: Bool {
        status == .active
    }

    public static func groupedByProvider(_ connections: [IntegrationConnection]) -> [Provider: [IntegrationConnection]] {
        Dictionary(grouping: connections.sorted { lhs, rhs in
            if lhs.provider == rhs.provider {
                return lhs.accountLabel.localizedCaseInsensitiveCompare(rhs.accountLabel) == .orderedAscending
            }
            return lhs.provider.displayName < rhs.provider.displayName
        }, by: \.provider)
    }

    public static func activeCount(in connections: [IntegrationConnection]) -> Int {
        connections.filter(\.isActive).count
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case provider
        case accountLabel = "account_label"
        case externalAccountID = "external_account_id"
        case externalAccountURL = "external_account_url"
        case status
        case scopes
        case lastSyncedAt = "last_synced_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public extension IntegrationConnection {
    static func fixture(
        id: UUID = UUID(),
        userID: UUID = UUID(uuidString: "40000000-0000-0000-0000-000000000001")!,
        provider: Provider,
        accountLabel: String,
        status: ConnectionStatus = .active
    ) -> IntegrationConnection {
        IntegrationConnection(
            id: id,
            userID: userID,
            provider: provider,
            accountLabel: accountLabel,
            externalAccountID: id.uuidString,
            status: status,
            scopes: ["read"]
        )
    }
}
