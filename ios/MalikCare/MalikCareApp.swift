import SwiftUI
import SwiftData

@main
struct MalikCareApp: App {
    @AppStorage(Keys.nightMode) private var nightMode = NightMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .arabic()
            .preferredColorScheme(NightMode(rawValue: nightMode)?.colorScheme)
        }
        .modelContainer(for: [FeedEntry.self, DiaperEntry.self, SleepEntry.self])
    }
}
