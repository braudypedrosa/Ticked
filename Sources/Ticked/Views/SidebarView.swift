import EfficiencyCore
import SwiftUI

struct SidebarView: View {
    @Binding var selectedFilter: TodoFilter
    @Binding var selectedProvider: Provider?
    let count: (TodoFilter) -> Int

    var body: some View {
        List(selection: $selectedFilter) {
            Section("Todos") {
                ForEach(TodoFilter.allCases) { filter in
                    Label {
                        HStack {
                            Text(filter.title)
                            Spacer()
                            Text("\(count(filter))")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    } icon: {
                        Image(systemName: iconName(for: filter))
                    }
                    .tag(filter)
                }
            }

            Section("Sources") {
                Button {
                    selectedProvider = nil
                } label: {
                    Label("All Sources", systemImage: "tray.full")
                }
                ForEach(Provider.allCases, id: \.self) { provider in
                    Button {
                        selectedProvider = provider
                    } label: {
                        Label(provider.displayName, systemImage: providerIcon(provider))
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func iconName(for filter: TodoFilter) -> String {
        switch filter {
        case .inbox: "tray"
        case .new: "sparkle"
        case .dueToday: "calendar"
        case .overdue: "exclamationmark.triangle"
        case .completed: "checkmark.circle"
        }
    }

    private func providerIcon(_ provider: Provider) -> String {
        switch provider {
        case .linear: "line.3.horizontal.decrease.circle"
        case .basecamp: "mountain.2"
        case .trello: "rectangle.3.group"
        }
    }
}

