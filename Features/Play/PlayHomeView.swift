import SwiftUI
import TableMechData
import TableMechDomain

struct PlayHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var ridgeTitle = "Ridge Line"
    @State private var loadError: String?
    @State private var matchStore: MatchStore?
    @State private var showGettingStarted = false
    @State private var showHowToPlay = false
    @State private var resume: PlayResume?
    @State private var showReplaceConfirm = false
    @State private var pendingInfo: PlayInfoLink?

    var body: some View {
        List {
            if let resume {
                Section {
                    Button(action: resumeActiveMatch) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Continue")
                                .font(.headline)
                            Text(resume.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityIdentifier("as.modeHome.resume")
                }
            }

            if dependencies.releaseSurface.isEnabled(.ridgeLineMission) {
                Section {
                    HStack(spacing: 0) {
                        Button(action: requestNewRidgeLine) {
                            Label("Play Ridge Line", systemImage: "flag.checkered")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("as.modeHome.ridgeLine")
                        InfoButton(title: "Ridge Line", onDismiss: openPendingInfo) { dismiss in
                            ridgeLineInfo(dismiss: dismiss)
                        }
                    }
                } header: {
                    Text("Alpha Strike")
                }
            }

            if dependencies.releaseSurface.isEnabled(.classicComingSoonEntry) {
                Section {
                    HStack(spacing: 0) {
                        Text("Classic BattleTech")
                        Spacer(minLength: 8)
                        Text("Coming soon")
                            .foregroundStyle(.secondary)
                        InfoButton(
                            title: "Classic BattleTech",
                            accessibilityIdentifier: "play.classicComingSoon",
                            onDismiss: openPendingInfo
                        ) { dismiss in
                            classicInfo(dismiss: dismiss)
                        }
                    }
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
        .accessibilityIdentifier("play.home")
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
                startNewRidgeLine(replaceActive: true)
            }
            Button("Keep current game", role: .cancel) {}
        } message: {
            Text("You already have a match saved. Starting Ridge Line will throw that progress away.")
        }
        .onAppear(perform: refreshResume)
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

    private func ridgeLineInfo(dismiss: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ridge Line")
                .font(.headline)
            Text("Four miniatures, two dice, and a tape. Two players, about 40 minutes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("New here?") {
                pendingInfo = .gettingStarted
                dismiss()
            }
            .accessibilityIdentifier("as.modeHome.gettingStarted")
            Button("How to play Ridge Line") {
                pendingInfo = .howToPlay
                dismiss()
            }
            .accessibilityIdentifier("as.modeHome.howToPlay")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func classicInfo(dismiss: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming later")
                .font(.headline)
            Text("Classic uses paper record sheets, heat, and hit locations. For a first night, play Ridge Line.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Play the beginner game") {
                pendingInfo = .playRidgeLine
                dismiss()
            }
            .accessibilityIdentifier("classic.comingSoon.playAS")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openPendingInfo() {
        let next = pendingInfo
        pendingInfo = nil
        guard let next else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            switch next {
            case .gettingStarted:
                showGettingStarted = true
            case .howToPlay:
                showHowToPlay = true
            case .playRidgeLine:
                requestNewRidgeLine()
            }
        }
    }

    private func requestNewRidgeLine() {
        if resume != nil {
            showReplaceConfirm = true
        } else {
            startNewRidgeLine(replaceActive: false)
        }
    }

    private func startNewRidgeLine(replaceActive: Bool) {
        let store = MatchStore(repository: dependencies.matchSessions)
        store.startRidgeLine(from: dependencies.content, replaceActive: replaceActive)
        if store.session != nil {
            matchStore = store
        } else {
            loadError = store.lastError ?? "Could not start Ridge Line"
        }
    }

    private func resumeActiveMatch() {
        let store = MatchStore(repository: dependencies.matchSessions)
        do {
            guard try store.resumeActive() else {
                resume = nil
                return
            }
            matchStore = store
        } catch {
            loadError = "Could not resume: \(error.localizedDescription)"
        }
    }

    private func refreshResume() {
        do {
            if let session = try MatchStore.loadActive(from: dependencies.matchSessions) {
                resume = PlayResume(
                    scenario: ridgeTitle,
                    turn: session.turn,
                    maxTurn: session.ruleset.maxTurns,
                    phase: session.phase.displayName
                )
            } else {
                resume = nil
            }
        } catch {
            resume = nil
            dependencies.logger.error("\(error)", category: "persistence")
        }
    }
}

private enum PlayInfoLink {
    case gettingStarted
    case howToPlay
    case playRidgeLine
}

private struct PlayResume: Equatable {
    var scenario: String
    var turn: Int
    var maxTurn: Int?
    var phase: String

    var detail: String {
        if let maxTurn {
            return "\(scenario) · Turn \(turn) of \(maxTurn) · \(phase)"
        }
        return "\(scenario) · Turn \(turn) · \(phase)"
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
                    HStack(alignment: .center, spacing: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(index + 1). \(item.title)")
                                .font(.headline)
                                .accessibilityLabel("\(index + 1). \(item.title)")
                                .accessibilityIdentifier("as.gettingStarted.check.\(item.id)")
                            if let link = item.linkURL, let url = URL(string: link) {
                                Link("Open official downloads (Safari)", destination: url)
                                    .font(.subheadline)
                                    .buttonStyle(.borderless)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if let detail = item.detail {
                            InfoButton(title: item.title) { _ in
                                Text(detail)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            Section("Words on the card") {
                cardTerm("Move", "How many inches it can walk")
                cardTerm("Armor", "Outer hit points")
                cardTerm("Structure", "Inner hit points — 0 means wrecked")
                cardTerm("Skill", "Starting shot difficulty (usually 4)")
                cardTerm("S / M / L", "Damage at short, medium, long range")
                cardTerm("TMM", "Extra “harder to hit” when it moved")
            }
        }
        .navigationTitle("New here")
        .accessibilityIdentifier("as.gettingStarted.screen")
        .task {
            items = (try? dependencies.content.gettingStarted().items) ?? []
        }
    }

    private func cardTerm(_ term: String, _ definition: String) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(term)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            InfoButton(title: term) { _ in
                Text(definition)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ForcePlaceholderView: View {
    @Environment(AppDependencies.self) private var dependencies
    let loadToken: Int
    @State private var units: [MatchUnitState] = []
    @State private var loadError: String?

    var body: some View {
        List {
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
                            HStack(alignment: .center, spacing: 0) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(unit.name)
                                        .font(.headline)
                                    Text("Armor \(unit.remainingArmor)/\(unit.armorCap)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("Structure \(unit.remainingStructure)/\(unit.structureCap)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(unit.name), armor \(unit.remainingArmor) of \(unit.armorCap), structure \(unit.remainingStructure) of \(unit.structureCap)")
                                .accessibilityIdentifier("force.as.unit.\(unit.name)")

                                InfoButton(title: unit.name) { _ in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Move \(unit.mv) · Skill \(unit.skill) · Damage \(unit.s)/\(unit.m)/\(unit.l)")
                                            .font(.subheadline)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if !unit.abilities.isEmpty {
                                            Text(unit.abilities)
                                                .font(.subheadline)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Force")
        .accessibilityIdentifier("force.as.list")
        .onAppear(perform: loadForces)
        .task(id: loadToken) { loadForces() }
    }

    private func loadForces() {
        do {
            if let session = try MatchStore.loadActive(from: dependencies.matchSessions) {
                units = session.units
            } else {
                let scenario = try dependencies.content.ridgeLineScenario()
                units = RidgeLineFactory.makeUnits(from: scenario)
            }
            loadError = nil
        } catch {
            loadError = error.localizedDescription
            units = []
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
                .accessibilityHint("Opens this topic")
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
        .accessibilityIdentifier("rules.as.detail.\(topic.id)")
    }
}

struct SettingsHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var confirmDelete = false
    @State private var deleteError: String?

    var body: some View {
        List {
            Section {
                Button("Delete saved games", role: .destructive) {
                    confirmDelete = true
                }
                .accessibilityIdentifier("settings.deleteAll")
                .accessibilityHint("Deletes the saved game")
            }
            Section {
                Link("Privacy Policy", destination: AppLinks.privacy)
                    .accessibilityLabel("Privacy Policy")
                Link("Support", destination: AppLinks.support)
                    .accessibilityLabel("Support")
                Link("Accessibility", destination: AppLinks.accessibility)
                    .accessibilityLabel("Accessibility")
            } header: {
                Text("Legal")
            } footer: {
                Text("Unofficial fan aid. BattleTech and Alpha Strike are trademarks of their respective owners.")
            }
        }
        .navigationTitle("Settings")
        .accessibilityIdentifier("settings.home")
        .confirmationDialog(
            "Delete every saved game?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                do {
                    try dependencies.matchSessions.deleteAll()
                } catch {
                    deleteError = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes the game in progress.")
        }
        .alert(
            "Could not delete",
            isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }
}
