import SwiftData
import SwiftUI

@main
struct TeleprompterApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Script.self, AppSettings.self])
    }
}
