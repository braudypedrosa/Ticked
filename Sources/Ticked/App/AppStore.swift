import AppKit
import EfficiencyCore
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var state = TodoListState(todos: DemoData.todos)
    @Published var isRefreshing = false
    @Published var lastRefreshMessage = "Not synced yet"
    @Published var authEmail = ""
    @Published var authMessage = "Sign in with your Supabase email to connect accounts."

    private let appService: SupabaseAppService
    private let syncService: SupabaseSyncService

    init(
        appService: SupabaseAppService = SupabaseAppService(),
        syncService: SupabaseSyncService = SupabaseSyncService()
    ) {
        self.appService = appService
        self.syncService = syncService
        if let email = try? appService.currentSessionEmail() {
            authEmail = email
            authMessage = "Signed in as \(email)"
        }
    }

    var todos: [TodoItem] {
        get { state.todos }
        set { state.todos = newValue }
    }

    var selectedFilter: TodoFilter {
        get { state.selectedFilter }
        set { state.selectedFilter = newValue }
    }

    var selectedProvider: Provider? {
        get { state.selectedProvider }
        set { state.selectedProvider = newValue }
    }

    var viewMode: TodoViewMode {
        get { state.viewMode }
        set { state.viewMode = newValue }
    }

    var visibleTodos: [TodoItem] {
        state.visibleTodos
    }

    func count(for filter: TodoFilter) -> Int {
        state.count(for: filter)
    }

    func toggleCompletion(for todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        if todos[index].isLocallyCompleted {
            todos[index].reopenLocally()
        } else {
            todos[index].markLocallyCompleted()
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await syncService.syncNow()
            lastRefreshMessage = "Manual sync requested"
        } catch {
            lastRefreshMessage = "Manual sync unavailable: \(error.localizedDescription)"
        }
    }

    func sendMagicLink() async {
        do {
            try await appService.sendMagicLink(to: authEmail)
            authMessage = "Magic link sent to \(authEmail)"
        } catch {
            authMessage = "Could not send magic link: \(error.localizedDescription)"
        }
    }

    func handleAuthCallback(_ url: URL) async {
        if url.scheme == "ticked", url.host == "oauth", url.path == "/trello" {
            await handleTrelloCallback(url)
            return
        }

        do {
            try await appService.handleAuthCallback(url)
            if let email = try appService.currentSessionEmail() {
                authEmail = email
                authMessage = "Signed in as \(email)"
            } else {
                authMessage = "Signed in"
            }
        } catch {
            authMessage = "Could not complete sign in: \(error.localizedDescription)"
        }
    }

    func connect(_ provider: Provider) async {
        do {
            let url = try await appService.startOAuth(for: provider)
            NSWorkspace.shared.open(url)
            authMessage = "Opening \(provider.displayName) authorization"
        } catch {
            authMessage = "Could not start \(provider.displayName): \(error.localizedDescription)"
        }
    }

    private func handleTrelloCallback(_ url: URL) async {
        let token = URLComponents(string: "fragment://token?\(url.fragment ?? "")")?
            .queryItems?
            .first(where: { $0.name == "token" })?
            .value
        let state = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "state" })?
            .value

        guard let token, !token.isEmpty else {
            authMessage = "Trello did not return a token"
            return
        }

        do {
            try await appService.storeTrelloToken(token, state: state)
            authMessage = "Trello connected"
        } catch {
            authMessage = "Could not store Trello token: \(error.localizedDescription)"
        }
    }
}
