import AppKit
import SwiftUI

@main
struct TickedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appStore = AppStore()

    var body: some Scene {
        WindowGroup("Ticked") {
            ContentView()
                .environmentObject(appStore)
                .onOpenURL { url in
                    Task { await appStore.handleAuthCallback(url) }
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh Todos") {
                    Task { await appStore.refresh() }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appStore)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
