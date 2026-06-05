import EfficiencyCore
import SwiftUI

struct TodoListView: View {
    @EnvironmentObject private var appStore: AppStore

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var content: some View {
        if appStore.visibleTodos.isEmpty {
            ContentUnavailableView("No todos", systemImage: "checklist", description: Text("Try another filter or run a refresh."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch appStore.viewMode {
            case .list:
                List(appStore.visibleTodos) { todo in
                    TodoRowView(todo: todo) {
                        appStore.toggleCompletion(for: todo)
                    }
                }
            case .card:
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                        ForEach(appStore.visibleTodos) { todo in
                            TodoCardView(todo: todo) {
                                appStore.toggleCompletion(for: todo)
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appStore.selectedFilter.title)
                    .font(.title2.weight(.semibold))
                Text(appStore.lastRefreshMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(appStore.visibleTodos.count)")
                .font(.title3.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
