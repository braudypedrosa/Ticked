import EfficiencyCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appStore: AppStore

    var body: some View {
        Form {
            Section("Sign In") {
                TextField("Email", text: $appStore.authEmail)
                    .textContentType(.emailAddress)
                Button("Send Magic Link") {
                    Task { await appStore.sendMagicLink() }
                }
                Text(appStore.authMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Supabase") {
                LabeledContent("Project URL", value: AppConfiguration.current.supabaseURL?.absoluteString ?? "Set TICKED_SUPABASE_URL")
                LabeledContent("Publishable Key", value: AppConfiguration.current.supabasePublishableKey == nil ? "Set TICKED_SUPABASE_PUBLISHABLE_KEY" : "Configured")
            }

            Section("Connections") {
                ForEach(Provider.allCases, id: \.self) { provider in
                    HStack {
                        Label(provider.displayName, systemImage: icon(provider))
                        Spacer()
                        Button("Connect") {
                            Task { await appStore.connect(provider) }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 430)
        .padding()
    }

    private func icon(_ provider: Provider) -> String {
        switch provider {
        case .linear: "line.3.horizontal.decrease.circle"
        case .basecamp: "mountain.2"
        case .trello: "rectangle.3.group"
        }
    }
}
