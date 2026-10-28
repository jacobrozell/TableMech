import SwiftUI

enum AppTab: Hashable {
    case play
    case force
    case rules
    case settings
}

struct RootTabView: View {
    @State private var tab: AppTab = .play
    @State private var forceLoads = 0

    var body: some View {
        TabView(selection: $tab) {
            Tab("Play", systemImage: "flag.checkered", value: AppTab.play) {
                NavigationStack {
                    PlayHomeView()
                }
            }
            Tab("Force", systemImage: "shield.lefthalf.filled", value: AppTab.force) {
                NavigationStack {
                    ForcePlaceholderView(loadToken: forceLoads)
                }
            }
            Tab("Rules", systemImage: "book", value: AppTab.rules) {
                NavigationStack {
                    RulesHomeView()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsHomeView()
                }
            }
        }
        .onChange(of: tab) { _, newTab in
            if newTab == .force {
                forceLoads += 1
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
