import Foundation

public enum TodoViewMode: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case list
    case card

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .list: "List"
        case .card: "Card"
        }
    }

    public var systemImage: String {
        switch self {
        case .list: "list.bullet"
        case .card: "square.grid.2x2"
        }
    }
}

