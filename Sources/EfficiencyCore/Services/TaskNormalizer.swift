import Foundation

public enum TaskNormalizerError: Error, Equatable {
    case missingTitle
}

public enum TaskNormalizer {
    public static func normalizeLinear(_ payload: LinearIssuePayload, connectionID: UUID, now: Date = Date()) throws -> TodoItem {
        let title = payload.title.trimmed
        guard !title.isEmpty else { throw TaskNormalizerError.missingTitle }

        return TodoItem(
            connectionID: connectionID,
            provider: .linear,
            externalID: payload.id,
            sourceKey: payload.identifier,
            title: title,
            externalURL: URL(string: payload.url),
            sourceName: payload.teamName?.nilIfBlank,
            dueDate: payload.dueDate.flatMap(Date.efficiencyDateOnly),
            firstSeenAt: now,
            lastSyncedAt: now,
            metadata: [
                "identifier": payload.identifier,
                "state": payload.stateName ?? ""
            ]
        )
    }

    public static func normalizeBasecamp(_ payload: BasecampAssignmentPayload, connectionID: UUID, now: Date = Date()) throws -> TodoItem {
        let title = payload.content.trimmed
        guard !title.isEmpty else { throw TaskNormalizerError.missingTitle }
        guard !payload.completed else { return TodoItem(connectionID: connectionID, provider: .basecamp, externalID: String(payload.id), title: title, localCompletedAt: now) }

        let sourceName = [payload.bucketName?.nilIfBlank, payload.parentTitle?.nilIfBlank]
            .compactMap { $0 }
            .joined(separator: " / ")

        return TodoItem(
            connectionID: connectionID,
            provider: .basecamp,
            externalID: String(payload.id),
            title: title,
            externalURL: URL(string: payload.appURL),
            sourceName: sourceName.isEmpty ? nil : sourceName,
            dueDate: payload.dueOn.flatMap(Date.efficiencyDateOnly),
            firstSeenAt: now,
            lastSyncedAt: now,
            metadata: [
                "bucket": payload.bucketName ?? "",
                "parent": payload.parentTitle ?? ""
            ]
        )
    }

    public static func normalizeTrello(_ payload: TrelloCardPayload, connectionID: UUID, now: Date = Date()) throws -> TodoItem? {
        guard !payload.closed, !payload.dueComplete else { return nil }
        let title = payload.name.trimmed
        guard !title.isEmpty else { throw TaskNormalizerError.missingTitle }

        let sourceName = [payload.boardName?.nilIfBlank, payload.listName?.nilIfBlank]
            .compactMap { $0 }
            .joined(separator: " / ")

        return TodoItem(
            connectionID: connectionID,
            provider: .trello,
            externalID: payload.id,
            title: title,
            externalURL: URL(string: payload.url),
            sourceName: sourceName.isEmpty ? nil : sourceName,
            dueDate: payload.due.flatMap(Date.efficiencyDateTime),
            firstSeenAt: now,
            lastSyncedAt: now,
            metadata: [
                "board": payload.boardName ?? "",
                "list": payload.listName ?? ""
            ]
        )
    }
}

