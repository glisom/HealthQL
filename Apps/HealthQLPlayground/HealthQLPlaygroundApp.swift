import SwiftUI
import HealthQLPlayground

@main
struct HealthQLPlaygroundApp: App {
    var body: some Scene {
        WindowGroup {
            REPLView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
