import SwiftUI

@main
struct ZotaApp: App {
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
        }
        .defaultSize(width: 700, height: 500)

        Settings {
            SettingsView()
                .environmentObject(appSettings)
        }
    }
}
