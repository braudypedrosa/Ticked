import XCTest
@testable import EfficiencyCore

final class TodoListStateTests: XCTestCase {
    func testVisibleTodosRespectFilterProviderAndViewMode() {
        let now = Date.iso8601("2026-06-05T12:00:00Z")
        let linear = TodoItem.fixture(
            connectionID: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            provider: .linear,
            title: "Linear item",
            dueDate: Date.iso8601("2026-06-05T00:00:00Z"),
            firstSeenAt: now
        )
        let trello = TodoItem.fixture(
            connectionID: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
            provider: .trello,
            title: "Trello item",
            dueDate: nil,
            firstSeenAt: now
        )

        var state = TodoListState(todos: [linear, trello], now: { now })
        state.selectedFilter = .dueToday
        state.selectedProvider = .linear
        state.viewMode = .card

        XCTAssertEqual(state.visibleTodos.map(\.title), ["Linear item"])
        XCTAssertEqual(state.count(for: .inbox), 2)
        XCTAssertEqual(state.viewMode, .card)
    }
}

