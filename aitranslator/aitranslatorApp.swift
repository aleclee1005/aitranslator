import SwiftUI
import SwiftData

@main
struct aitranslatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Session.self, TranscriptEntry.self])
    }
}
