import Foundation

public struct TodoListState: Hashable {
    public var todos: [TodoItem]
    public var selectedFilter: TodoFilter
    public var selectedProvider: Provider?
    public var viewMode: TodoViewMode
    private let nowProvider: () -> Date

    public init(
        todos: [TodoItem] = [],
        selectedFilter: TodoFilter = .inbox,
        selectedProvider: Provider? = nil,
        viewMode: TodoViewMode = .list,
        now: @escaping () -> Date = Date.init
    ) {
        self.todos = todos
        self.selectedFilter = selectedFilter
        self.selectedProvider = selectedProvider
        self.viewMode = viewMode
        self.nowProvider = now
    }

    public var visibleTodos: [TodoItem] {
        let filtered = selectedFilter.apply(to: todos, now: nowProvider())
        guard let selectedProvider else { return filtered }
        return filtered.filter { $0.provider == selectedProvider }
    }

    public func count(for filter: TodoFilter) -> Int {
        filter.apply(to: todos, now: nowProvider()).count
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(todos)
        hasher.combine(selectedFilter)
        hasher.combine(selectedProvider)
        hasher.combine(viewMode)
    }

    public static func == (lhs: TodoListState, rhs: TodoListState) -> Bool {
        lhs.todos == rhs.todos &&
            lhs.selectedFilter == rhs.selectedFilter &&
            lhs.selectedProvider == rhs.selectedProvider &&
            lhs.viewMode == rhs.viewMode
    }
}

