import SwiftUI
import TableMechData
import TableMechDomain

struct PlayHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var ridgeTitle = "Ridge Line"
    @State private var loadError: String?
    @State private var matchStore: MatchStore?
    @State private var showClassicInfo = false
    @State private var showGettingStarted = false
    @State private var showHowToPlay = false
    @State private var resumeSummary: String?
    @State private var showReplaceConfirm = false

    var body: some View {
        List {
            Section {
                Text("Play with miniatures on a real table. This phone is the rules helper — it will tell you what to do next, even if you’ve never played a wargame.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("play.home")
            }

            if let resumeSummary {
                Section("Continue") {
                    Button {
                        resumeActiveMatch()
                    } label: {
                        Label(resumeSummary, systemImage: "arrow.clockwise")
                    }
                    .accessibilityIdentifier("as.modeHome.resume")
                }
            }

            if dependencies.releaseSurface.isEnabled(.ridgeLineMission) {
                Section {
                    Button {
                        requestNewRidgeLine()
                    } label: {
                        Label("Play Ridge Line", systemImage: "flag.checkered")
                    }
                    .accessibilityIdentifier("as.modeHome.ridgeLine")
                    Text("Two players · four ’Mechs · about 40 minutes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let loadError {
                Section {
                    Text(loadError)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Play")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("New here?") { showGettingStarted = true }
                        .accessibilityIdentifier("as.modeHome.gettingStarted")
                    Button("How to play Ridge Line") { showHowToPlay = true }
                        .accessibilityIdentifier("as.modeHome.howToPlay")
                    if dependencies.releaseSurface.isEnabled(.classicComingSoonEntry) {
                        Button("Classic") { showClassicInfo = true }
                            .accessibilityIdentifier("play.classicComingSoon")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            NavigationStack {
                HowToPlayRidgeLineView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showHowToPlay = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showGettingStarted) {
            NavigationStack {
                GettingStartedView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showGettingStarted = false }
                        }
                    }
            }
        }
        .fullScreenCover(item: $matchStore, onDismiss: {
            matchStore = nil
            refreshResume()
        }) { store in
            NavigationStack {
                BattleFlowView(store: store)
            }
        }
        .confirmationDialog(
            "Replace the game in progress?",
            isPresented: $showReplaceConfirm,
            titleVisibility: .visible
        ) {
            Button("Discard and start Ridge Line", role: .destructive) {
                startNewRidgeLine()
            }
            Button("Keep current game", role: .cancel) {}
        } message: {
            Text("You already have a match saved. Starting Ridge Line will throw that progress away.")
        }
        .sheet(isPresented: $showClassicInfo) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Classic BattleTech")
                        .font(.title2.bold())
                    Text("Classic BattleTech is a more detailed game (paper record sheets, heat, hit locations). It’s coming later. For a first night, play Ridge Line — Alpha Strike with this app as your coach.")
                    Button("Play the beginner game") {
                        showClassicInfo = false
                        requestNewRidgeLine()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("classic.comingSoon.playAS")
                    Spacer()
                }
                .padding()
                .navigationTitle("Coming soon")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
        .task {
            do {
                let scenario = try dependencies.content.ridgeLineScenario()
                ridgeTitle = scenario.title
            } catch {
                loadError = "Could not load content: \(error.localizedDescription)"
                dependencies.logger.error("\(error)", category: "content")
            }
            refreshResume()
        }
    }

    private func requestNewRidgeLine() {
        if resumeSummary != nil {
            showReplaceConfirm = true
        } else {
            startNewRidgeLine()
        }
    }

    private func startNewRidgeLine() {
        let store = MatchStore(repository: dependencies.matchSessions)
        store.startRidgeLine(from: dependencies.content)
        matchStore = store
    }

    private func resumeActiveMatch() {
        do {
            guard let session = try dependencies.matchSessions.loadActive(mode: .alphaStrike) else {
                resumeSummary = nil
                return
            }
            let store = MatchStore(repository: dependencies.matchSessions)
            store.resume(session)
            matchStore = store
        } catch {
            loadError = "Could not resume: \(error.localizedDescription)"
        }
    }

    private func refreshResume() {
        do {
            if let session = try dependencies.matchSessions.loadActive(mode: .alphaStrike) {
                let phase = session.phase.displayName
                resumeSummary = "Resume \(ridgeTitle) · Turn \(session.turn) · \(phase)"
            } else {
                resumeSummary = nil
            }
        } catch {
            resumeSummary = nil
            dependencies.logger.error("\(error)", category: "persistence")
        }
    }
}

struct GettingStartedView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var items: [GettingStartedItemDTO] = []

    var body: some View {
        List {
            Section {
                Text("You don’t need to know BattleTech yet. Gather a few things, then start Ridge Line from Play. The mission will coach you step by step.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("Before you sit down") {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(index + 1). \(item.title)")
                            .font(.headline)
                        if let detail = item.detail {
                            Text(detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let link = item.linkURL, let url = URL(string: link) {
                            Link("Open official downloads (Safari)", destination: url)
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("as.gettingStarted.check.\(item.id)")
                }
            }
            Section("Words on the card") {
                LabeledContent("Move") {
                    Text("How many inches it can walk")
                }
                LabeledContent("Armor") {
                    Text("Outer hit points")
                }
                LabeledContent("Structure") {
                    Text("Inner hit points — 0 means wrecked")
                }
                LabeledContent("Skill") {
                    Text("Starting shot difficulty (usually 4)")
                }
                LabeledContent("S / M / L") {
                    Text("Damage at short, medium, long range")
                }
                LabeledContent("TMM") {
                    Text("Extra “harder to hit” when it moved")
                }
            }
        }
        .navigationTitle("New here")
        .accessibilityIdentifier("as.gettingStarted.screen")
        .task {
            items = (try? dependencies.content.gettingStarted().items) ?? []
        }
    }
}

struct ForcePlaceholderView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var units: [MatchUnitState] = []
    @State private var loadError: String?

    var body: some View {
        List {
            Section {
                Text("Ridge Line’s four 'Mechs. Match these names to your miniatures and cards. Live Armor/Structure is tracked in the battle screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let loadError {
                Section {
                    Text(loadError)
                        .foregroundStyle(.red)
                }
            }
            ForEach(SideId.allCases, id: \.self) { side in
                let sideUnits = units.filter { $0.side == side }
                if !sideUnits.isEmpty {
                    Section(side.displayName) {
                        ForEach(sideUnits) { unit in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(unit.name)
                                    .font(.headline)
                                Text("Move \(unit.mv) · Skill \(unit.skill) · Damage \(unit.s)/\(unit.m)/\(unit.l)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Armor \(unit.armorCap) · Structure \(unit.structureCap)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !unit.abilities.isEmpty {
                                    Text(unit.abilities)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityIdentifier("force.as.unit.\(unit.name)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Force")
        .accessibilityIdentifier("force.as.list")
        .task {
            do {
                let scenario = try dependencies.content.ridgeLineScenario()
                units = RidgeLineFactory.makeUnits(from: scenario)
            } catch {
                loadError = error.localizedDescription
            }
        }
    }
}

struct RulesHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var topics: [RulesTopicDTO] = []
    @State private var disclaimer: String?

    var body: some View {
        List {
            Section {
                Text("Start with the first topic if you’ve never played. During a game, follow the prompts on the battle screen — you don’t have to read all of this first.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(topics) { topic in
                NavigationLink(topic.title) {
                    RulesTopicDetailView(topic: topic)
                }
                .accessibilityIdentifier("rules.as.\(topic.id)")
            }
            if let disclaimer {
                Section {
                    Text(disclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Rules")
        .accessibilityIdentifier("rules.home")
        .task {
            let packed = try? dependencies.content.rulesTopics()
            topics = packed?.topics ?? []
            disclaimer = packed?.disclaimer
        }
    }
}

struct RulesTopicDetailView: View {
    let topic: RulesTopicDTO

    var body: some View {
        List(topic.sections, id: \.heading) { section in
            Section(section.heading) {
                Text(section.body)
            }
        }
        .navigationTitle(topic.title)
    }
}

struct SettingsHomeView: View {
    var body: some View {
        List {
            Section("Legal") {
                Link("Privacy Policy", destination: AppLinks.privacy)
                Link("Support", destination: AppLinks.support)
                Link("Accessibility", destination: AppLinks.accessibility)
                Text("Unofficial fan aid. BattleTech and Alpha Strike are trademarks of their respective owners.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .accessibilityIdentifier("settings.home")
    }
}
