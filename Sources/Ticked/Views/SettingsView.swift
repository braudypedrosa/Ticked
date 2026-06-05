import EfficiencyCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appStore: AppStore

    var body: some View {
        Form {
            Section("Ticked Account") {
                TextField("Email", text: $appStore.authEmail)
                    .textContentType(.emailAddress)
                Button("Send Sign-In Link") {
                    Task { await appStore.sendMagicLink() }
                }
                Text(appStore.authMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Cloud Sync") {
                LabeledContent("Status", value: AppConfiguration.current.isCloudSyncConfigured ? "Ready" : "Not configured")
            }

            Section("Connections") {
                ForEach(Provider.allCases, id: \.self) { provider in
                    providerBlock(provider)
                }
                LabeledContent("Accounts", value: appStore.connectionMessage)
            }
        }
        .formStyle(.grouped)
        .frame(width: 620, height: 560)
        .padding()
        .task {
            await appStore.loadConnections()
        }
    }

    @ViewBuilder
    private func providerBlock(_ provider: Provider) -> some View {
        let connections = appStore.groupedConnections[provider] ?? []

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(provider.displayName, systemImage: icon(provider))
                    .font(.headline)
                Spacer()
                Button {
                    Task { await appStore.connect(provider) }
                } label: {
                    Label("Connect another", systemImage: "plus")
                }
                .help("Connect another \(provider.displayName) account")
            }

            if connections.isEmpty {
                Text("No accounts connected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(connections) { connection in
                    connectionRow(connection)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func connectionRow(_ connection: IntegrationConnection) -> some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon(connection.status))
                .foregroundStyle(statusColor(connection.status))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(connection.accountLabel)
                    .font(.body)
                HStack(spacing: 8) {
                    Text(connection.status.displayName)
                    if let lastSyncedAt = connection.lastSyncedAt {
                        Text("Synced \(lastSyncedAt.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await appStore.sync(connection) }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Sync \(connection.accountLabel)")

            Button {
                Task { await appStore.reconnect(connection) }
            } label: {
                Image(systemName: "person.crop.circle.badge.checkmark")
            }
            .buttonStyle(.borderless)
            .help("Reconnect \(connection.accountLabel)")

            Button(role: .destructive) {
                Task { await appStore.disconnect(connection) }
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
            .help("Disconnect \(connection.accountLabel)")
        }
        .padding(.leading, 22)
    }

    private func icon(_ provider: Provider) -> String {
        switch provider {
        case .linear: "line.3.horizontal.decrease.circle"
        case .basecamp: "mountain.2"
        case .trello: "rectangle.3.group"
        }
    }

    private func statusIcon(_ status: ConnectionStatus) -> String {
        switch status {
        case .active: "checkmark.circle.fill"
        case .needsReauth: "exclamationmark.circle.fill"
        case .disabled: "minus.circle.fill"
        }
    }

    private func statusColor(_ status: ConnectionStatus) -> Color {
        switch status {
        case .active: .green
        case .needsReauth: .orange
        case .disabled: .secondary
        }
    }
}
