import Foundation

public enum TodoFilter: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case inbox
    case new
    case dueToday
    case overdue
    case completed

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .inbox: "Inbox"
        case .new: "New"
        case .dueToday: "Due Today"
        case .overdue: "Overdue"
        case .completed: "Completed"
        }
    }

    public func apply(to todos: [TodoItem], now: Date = Date()) -> [TodoItem] {
        todos.filter { todo in
            switch self {
            case .inbox:
                !todo.isLocallyCompleted
            case .new:
                !todo.isLocallyCompleted && todo.isNew(on: now)
            case .dueToday:
                !todo.isLocallyCompleted && todo.isDueToday(on: now)
            case .overdue:
                !todo.isLocallyCompleted && todo.isOverdue(on: now)
            case .completed:
                todo.isLocallyCompleted
            }
        }
    }
}

