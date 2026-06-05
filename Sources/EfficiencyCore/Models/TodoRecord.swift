import Foundation

public struct TodoRecord: Decodable, Hashable, Sendable {
    public let id: UUID
    public let connectionID: UUID
    public let provider: Provider
    public let externalID: String
    public let sourceKey: String?
    public let title: String
    public let externalURL: URL?
    public let sourceName: String?
    public let dueAt: Date?
    public let firstSeenAt: Date
    public let lastSyncedAt: Date
    public let localCompletedAt: Date?

    public init(
        id: UUID,
        connectionID: UUID,
        provider: Provider,
        externalID: String,
        sourceKey: String? = nil,
        title: String,
        externalURL: URL? = nil,
        sourceName: String? = nil,
        dueAt: Date? = nil,
        firstSeenAt: Date,
        lastSyncedAt: Date,
        localCompletedAt: Date? = nil
    ) {
        self.id = id
        self.connectionID = connectionID
        self.provider = provider
        self.externalID = externalID
        self.sourceKey = sourceKey
        self.title = title
        self.externalURL = externalURL
        self.sourceName = sourceName
        self.dueAt = dueAt
        self.firstSeenAt = firstSeenAt
        self.lastSyncedAt = lastSyncedAt
        self.localCompletedAt = localCompletedAt
    }

    public var todoItem: TodoItem {
        TodoItem(
            id: id,
            connectionID: connectionID,
            provider: provider,
            externalID: externalID,
            sourceKey: sourceKey,
            title: title,
            externalURL: externalURL,
            sourceName: sourceName,
            dueDate: dueAt,
            firstSeenAt: firstSeenAt,
            lastSyncedAt: lastSyncedAt,
            localCompletedAt: localCompletedAt
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case connectionID = "connection_id"
        case provider
        case externalID = "external_id"
        case sourceKey = "source_key"
        case title
        case externalURL = "external_url"
        case sourceName = "source_name"
        case dueAt = "due_at"
        case firstSeenAt = "first_seen_at"
        case lastSyncedAt = "last_synced_at"
        case localCompletedAt = "local_completed_at"
    }
}
