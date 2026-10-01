import SwiftUI

@main
struct IPCalculatorApp: App {
    @AppStorage("dark_mode") private var darkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkMode ? .dark : .light)
        }
    }
}
