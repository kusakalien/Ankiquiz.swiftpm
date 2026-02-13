import SwiftUI

@main
struct AnkiQuizApp: App {
    @StateObject private var store = DeckStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
