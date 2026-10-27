import SwiftUI
import SwiftData

@main
struct TableMechApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(dependencies)
                .modelContainer(dependencies.modelContainer)
        }
    }
}
