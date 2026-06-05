import EfficiencyCore
import Foundation

enum DemoData {
    static let todos: [TodoItem] = {
        let linearConnection = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
        let basecampConnection = UUID(uuidString: "20000000-0000-0000-0000-000000000002")!
        let trelloConnection = UUID(uuidString: "20000000-0000-0000-0000-000000000003")!

        return [
            TodoItem(
                connectionID: linearConnection,
                provider: .linear,
                externalID: "linear-demo-1",
                sourceKey: "DEV-42",
                title: "Connect the task inbox",
                externalURL: URL(string: "https://linear.app"),
                sourceName: "Platform",
                dueDate: Date.efficiencyDateOnly("2026-06-05"),
                firstSeenAt: Date(),
                lastSyncedAt: Date()
            ),
            TodoItem(
                connectionID: basecampConnection,
                provider: .basecamp,
                externalID: "basecamp-demo-1",
                title: "Review Basecamp assignments",
                externalURL: URL(string: "https://basecamp.com"),
                sourceName: "Client Ops / Launch",
                dueDate: Date.efficiencyDateOnly("2026-06-04"),
                firstSeenAt: Calendar.efficiencyUTC.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                lastSyncedAt: Date()
            ),
            TodoItem(
                connectionID: trelloConnection,
                provider: .trello,
                externalID: "trello-demo-1",
                title: "Check card view polish",
                externalURL: URL(string: "https://trello.com"),
                sourceName: "Product / Doing",
                dueDate: nil,
                firstSeenAt: Date(),
                lastSyncedAt: Date()
            )
        ]
    }()
}

