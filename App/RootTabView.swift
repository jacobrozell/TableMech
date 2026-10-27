import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Play", systemImage: "flag.checkered") {
                NavigationStack {
                    PlayHomeView()
                }
            }
            Tab("Force", systemImage: "shield.lefthalf.filled") {
                NavigationStack {
                    ForcePlaceholderView()
                }
            }
            Tab("Rules", systemImage: "book") {
                NavigationStack {
                    RulesHomeView()
                }
            }
            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsHomeView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
