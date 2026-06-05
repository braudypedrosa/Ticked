import Foundation

public enum Provider: String, Codable, CaseIterable, Hashable, Sendable {
    case linear
    case basecamp
    case trello

    public var displayName: String {
        switch self {
        case .linear: "Linear"
        case .basecamp: "Basecamp"
        case .trello: "Trello"
        }
    }
}

