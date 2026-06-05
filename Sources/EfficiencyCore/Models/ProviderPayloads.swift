import Foundation

public struct LinearIssuePayload: Codable, Hashable, Sendable {
    public let id: String
    public let identifier: String
    public let title: String
    public let url: String
    public let dueDate: String?
    public let teamName: String?
    public let stateName: String?

    public init(id: String, identifier: String, title: String, url: String, dueDate: String?, teamName: String?, stateName: String?) {
        self.id = id
        self.identifier = identifier
        self.title = title
        self.url = url
        self.dueDate = dueDate
        self.teamName = teamName
        self.stateName = stateName
    }
}

public struct BasecampAssignmentPayload: Codable, Hashable, Sendable {
    public let id: Int64
    public let content: String
    public let appURL: String
    public let dueOn: String?
    public let bucketName: String?
    public let parentTitle: String?
    public let completed: Bool

    public init(id: Int64, content: String, appURL: String, dueOn: String?, bucketName: String?, parentTitle: String?, completed: Bool) {
        self.id = id
        self.content = content
        self.appURL = appURL
        self.dueOn = dueOn
        self.bucketName = bucketName
        self.parentTitle = parentTitle
        self.completed = completed
    }
}

public struct TrelloCardPayload: Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let url: String
    public let due: String?
    public let dueComplete: Bool
    public let closed: Bool
    public let boardName: String?
    public let listName: String?

    public init(id: String, name: String, url: String, due: String?, dueComplete: Bool, closed: Bool, boardName: String?, listName: String?) {
        self.id = id
        self.name = name
        self.url = url
        self.due = due
        self.dueComplete = dueComplete
        self.closed = closed
        self.boardName = boardName
        self.listName = listName
    }
}

