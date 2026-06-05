import Foundation

public struct TodoItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let connectionID: UUID
    public let provider: Provider
    public let externalID: String
    public let sourceKey: String?
    public var title: String
    public var externalURL: URL?
    public var sourceName: String?
    public var dueDate: Date?
    public var firstSeenAt: Date
    public var lastSyncedAt: Date
    public var localCompletedAt: Date?
    public var metadata: [String: String]

    public init(
        id: UUID = UUID(),
        connectionID: UUID,
        provider: Provider,
        externalID: String,
        sourceKey: String? = nil,
        title: String,
        externalURL: URL? = nil,
        sourceName: String? = nil,
        dueDate: Date? = nil,
        firstSeenAt: Date = Date(),
        lastSyncedAt: Date = Date(),
        localCompletedAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.connectionID = connectionID
        self.provider = provider
        self.externalID = externalID
        self.sourceKey = sourceKey
        self.title = title
        self.externalURL = externalURL
        self.sourceName = sourceName
        self.dueDate = dueDate
        self.firstSeenAt = firstSeenAt
        self.lastSyncedAt = lastSyncedAt
        self.localCompletedAt = localCompletedAt
        self.metadata = metadata
    }

    public var isLocallyCompleted: Bool {
        localCompletedAt != nil
    }

    public mutating func markLocallyCompleted(at date: Date = Date()) {
        localCompletedAt = date
    }

    public mutating func reopenLocally() {
        localCompletedAt = nil
    }

    public func isNew(on date: Date, calendar: Calendar = .efficiencyUTC) -> Bool {
        calendar.isDate(firstSeenAt, inSameDayAs: date)
    }

    public func isDueToday(on date: Date, calendar: Calendar = .efficiencyUTC) -> Bool {
        guard let dueDate else { return false }
        return calendar.isDate(dueDate, inSameDayAs: date)
    }

    public func isOverdue(on date: Date, calendar: Calendar = .efficiencyUTC) -> Bool {
        guard let dueDate else { return false }
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: date)
    }
}

public extension TodoItem {
    static func fixture(
        id: UUID = UUID(),
        connectionID: UUID,
        provider: Provider,
        title: String,
        dueDate: Date?,
        firstSeenAt: Date
    ) -> TodoItem {
        TodoItem(
            id: id,
            connectionID: connectionID,
            provider: provider,
            externalID: id.uuidString,
            title: title,
            dueDate: dueDate,
            firstSeenAt: firstSeenAt,
            lastSyncedAt: firstSeenAt
        )
    }
}

