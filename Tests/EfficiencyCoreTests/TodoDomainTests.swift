import XCTest
@testable import EfficiencyCore

final class TodoDomainTests: XCTestCase {
    func testLinearPayloadNormalizesToAssignedTodo() throws {
        let payload = LinearIssuePayload(
            id: "issue-1",
            identifier: "DEV-42",
            title: "Ship task inbox",
            url: "https://linear.app/acme/issue/DEV-42",
            dueDate: "2026-06-04",
            teamName: "Platform",
            stateName: "Todo"
        )

        let todo = try TaskNormalizer.normalizeLinear(payload, connectionID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)

        XCTAssertEqual(todo.provider, .linear)
        XCTAssertEqual(todo.externalID, "issue-1")
        XCTAssertEqual(todo.sourceKey, "DEV-42")
        XCTAssertEqual(todo.title, "Ship task inbox")
        XCTAssertEqual(todo.sourceName, "Platform")
        XCTAssertTrue(todo.isOverdue(on: Date.iso8601("2026-06-05T12:00:00Z")))
    }

    func testBasecampPayloadUsesAssignmentContentAndParent() throws {
        let payload = BasecampAssignmentPayload(
            id: 9007199254741623,
            content: "Program the flux capacitor",
            appURL: "https://3.basecamp.com/195539477/buckets/2085958504/todos/9007199254741623",
            dueOn: "2026-06-05",
            bucketName: "The Leto Laptop",
            parentTitle: "Development tasks",
            completed: false
        )

        let todo = try TaskNormalizer.normalizeBasecamp(payload, connectionID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)

        XCTAssertEqual(todo.provider, .basecamp)
        XCTAssertEqual(todo.externalID, "9007199254741623")
        XCTAssertEqual(todo.title, "Program the flux capacitor")
        XCTAssertEqual(todo.sourceName, "The Leto Laptop / Development tasks")
        XCTAssertTrue(todo.isDueToday(on: Date.iso8601("2026-06-05T09:00:00Z")))
    }

    func testTrelloClosedOrDueCompleteCardIsNotImported() throws {
        let payload = TrelloCardPayload(
            id: "card-1",
            name: "Review landing page",
            url: "https://trello.com/c/card-1",
            due: "2026-06-05T17:00:00.000Z",
            dueComplete: true,
            closed: false,
            boardName: "Launch",
            listName: "Doing"
        )

        XCTAssertNil(try TaskNormalizer.normalizeTrello(payload, connectionID: UUID()))
    }

    func testFiltersRespectLocalCompletionAndNewness() {
        let now = Date.iso8601("2026-06-05T12:00:00Z")
        let connectionID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let open = TodoItem.fixture(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            connectionID: connectionID,
            provider: .linear,
            title: "Open",
            dueDate: Date.iso8601("2026-06-06T00:00:00Z"),
            firstSeenAt: Date.iso8601("2026-06-05T08:00:00Z")
        )
        let overdue = TodoItem.fixture(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            connectionID: connectionID,
            provider: .basecamp,
            title: "Overdue",
            dueDate: Date.iso8601("2026-06-04T00:00:00Z"),
            firstSeenAt: Date.iso8601("2026-06-01T08:00:00Z")
        )
        var completed = TodoItem.fixture(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
            connectionID: connectionID,
            provider: .trello,
            title: "Completed",
            dueDate: nil,
            firstSeenAt: Date.iso8601("2026-06-05T08:00:00Z")
        )
        completed.markLocallyCompleted(at: now)

        let todos = [open, overdue, completed]

        XCTAssertEqual(TodoFilter.inbox.apply(to: todos, now: now).map(\.title), ["Open", "Overdue"])
        XCTAssertEqual(TodoFilter.new.apply(to: todos, now: now).map(\.title), ["Open"])
        XCTAssertEqual(TodoFilter.overdue.apply(to: todos, now: now).map(\.title), ["Overdue"])
        XCTAssertEqual(TodoFilter.completed.apply(to: todos, now: now).map(\.title), ["Completed"])
    }

    func testTodoRecordMapsDatabaseColumnsToTodoItem() {
        let id = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
        let connectionID = UUID(uuidString: "20000000-0000-0000-0000-000000000002")!
        let dueAt = Date.iso8601("2026-06-05T00:00:00Z")
        let firstSeenAt = Date.iso8601("2026-06-05T08:00:00Z")
        let lastSyncedAt = Date.iso8601("2026-06-05T09:00:00Z")
        let completedAt = Date.iso8601("2026-06-05T10:00:00Z")
        let record = TodoRecord(
            id: id,
            connectionID: connectionID,
            provider: .basecamp,
            externalID: "task-1",
            sourceKey: nil,
            title: "Imported task",
            externalURL: URL(string: "https://example.com/task-1"),
            sourceName: "Client / List",
            dueAt: dueAt,
            firstSeenAt: firstSeenAt,
            lastSyncedAt: lastSyncedAt,
            localCompletedAt: completedAt
        )

        let todo = record.todoItem

        XCTAssertEqual(todo.id, id)
        XCTAssertEqual(todo.connectionID, connectionID)
        XCTAssertEqual(todo.provider, .basecamp)
        XCTAssertEqual(todo.externalID, "task-1")
        XCTAssertEqual(todo.title, "Imported task")
        XCTAssertEqual(todo.externalURL, URL(string: "https://example.com/task-1"))
        XCTAssertEqual(todo.sourceName, "Client / List")
        XCTAssertEqual(todo.dueDate, dueAt)
        XCTAssertEqual(todo.firstSeenAt, firstSeenAt)
        XCTAssertEqual(todo.lastSyncedAt, lastSyncedAt)
        XCTAssertEqual(todo.localCompletedAt, completedAt)
    }
}
