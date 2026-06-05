import EfficiencyCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appStore: AppStore
    @SceneStorage("selectedFilter") private var selectedFilterRawValue = TodoFilter.inbox.rawValue

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedFilter: Binding(
                    get: { TodoFilter(rawValue: selectedFilterRawValue) ?? .inbox },
                    set: {
                        selectedFilterRawValue = $0.rawValue
                        appStore.selectedFilter = $0
                    }
                ),
                selectedProvider: $appStore.selectedProvider,
                count: appStore.count(for:)
            )
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 280)
        } detail: {
            TodoListView()
        }
        .frame(minWidth: 920, minHeight: 620)
        .toolbar {
            ToolbarItemGroup {
                Picker("View", selection: $appStore.viewMode) {
                    ForEach(TodoViewMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 148)

                Button {
                    Task { await appStore.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(appStore.isRefreshing)

                SettingsLink {
                    Label("Connections", systemImage: "slider.horizontal.3")
                }
            }
        }
        .onAppear {
            appStore.selectedFilter = TodoFilter(rawValue: selectedFilterRawValue) ?? .inbox
        }
    }
}

