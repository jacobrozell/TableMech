import SwiftUI
import TableMechDomain

struct BattleFlowView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Bindable var store: MatchStore
    @Environment(\.dismiss) private var dismiss

    @State private var showInitiative = false
    @State private var showSATOR = false
    @State private var showCrit: MatchUnitState?
    @State private var focusUnit: MatchUnitState?
    @State private var prefillAttackerId: UUID?
    @State private var a1: Int?
    @State private var a2: Int?
    @State private var b1: Int?
    @State private var b2: Int?

    @State private var showAbandonConfirm = false
    @State private var showSkipConfirm = false
    @State private var showEventLog = false
    @State private var deployAcknowledged = false
    @State private var handoffSide: SideId?
    @State private var showBackConfirm = false
    @State private var showDoneShootingConfirm = false
    @State private var focusFollowUp: FocusFollowUp?

    var body: some View {
        Group {
            if let session = store.session {
                content(session)
            } else {
                ProgressView("Loading the mission…")
            }
        }
        .navigationTitle("Ridge Line")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Leave") {
                    if store.session?.status == .completed {
                        store.dismissCompleted()
                    } else {
                        store.leaveAndSave()
                    }
                    dismiss()
                }
                .accessibilityIdentifier("as.battle.leave")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if store.canUndo {
                        Button("Undo last change", systemImage: "arrow.uturn.backward") {
                            store.undo()
                        }
                    }
                    Button("What just happened", systemImage: "list.bullet") {
                        showEventLog = true
                    }
                    Button("Quit and discard this game", role: .destructive) {
                        showAbandonConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityIdentifier("as.battle.more")
            }
        }
        .confirmationDialog("Quit this game?", isPresented: $showAbandonConfirm, titleVisibility: .visible) {
            Button("Quit and discard", role: .destructive) {
                store.abandon()
            }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("You’ll lose this game’s progress. You can start Ridge Line again from Play.")
        }
        .confirmationDialog(
            "Go back a step?",
            isPresented: $showBackConfirm,
            titleVisibility: .visible
        ) {
            Button("Go back", role: .destructive) {
                store.back()
                handoffSide = nil
            }
            Button("Stay here", role: .cancel) {}
        } message: {
            Text("This undoes shots, damage, or recorded moves from this step. The rest of the game stays saved.")
        }
        .confirmationDialog(
            "Some ’Mechs have not shot",
            isPresented: $showDoneShootingConfirm,
            titleVisibility: .visible
        ) {
            Button("Done shooting anyway") {
                store.finishCombatSide()
            }
            Button("Keep shooting", role: .cancel) {}
        } message: {
            Text("They can still fire. Skipping means this side fires nothing else.")
        }
        .confirmationDialog(
            "Some 'Mechs have no move recorded",
            isPresented: $showSkipConfirm,
            titleVisibility: .visible
        ) {
            Button("Start shooting anyway") {
                store.skipMovesAndAdvance()
            }
            Button("Keep recording moves", role: .cancel) {}
        } message: {
            Text("Unrecorded moves will count as Walk when they shoot. Prefer recording Stand still / Walk / Sprint / Jump for each 'Mech.")
        }
        .onAppear {
            if store.session == nil {
                store.startRidgeLine(from: dependencies.content)
            } else if store.session?.units.contains(where: \.hasMovedThisTurn) == true {
                deployAcknowledged = true
            }
        }
        .onChange(of: store.session?.status) { _, status in
            if status == .abandoned || store.session == nil {
                dismiss()
            }
        }
        .onChange(of: store.session?.phase) { old, new in
            if old == .initiative, new == .movement {
                deployAcknowledged = false
            }
            if new == .initiative || new == .end {
                handoffSide = nil
            }
            if new == .movement, store.session?.units.contains(where: \.hasMovedThisTurn) != true {
                deployAcknowledged = false
            }
        }
        .onChange(of: store.session?.activeSide) { old, new in
            guard let old, let new, old != new else { return }
            guard let phase = store.session?.phase, phase == .movement || phase == .combat else {
                handoffSide = nil
                return
            }
            if phase == .movement, store.session?.turn == 1, !deployAcknowledged {
                return
            }
            handoffSide = new
        }
        .sheet(isPresented: $showEventLog) {
            eventLogSheet
        }
        .sheet(isPresented: $showInitiative) {
            initiativeSheet
        }
        .sheet(isPresented: $showSATOR) {
            if let session = store.session {
                CombatSolverSheet(
                    session: session,
                    store: store,
                    initialAttackerId: prefillAttackerId
                )
            }
        }
        .sheet(item: $showCrit) { unit in
            CritSheet(unit: unit, store: store)
        }
        .sheet(item: $focusUnit, onDismiss: {
            switch focusFollowUp {
            case .shot(let id):
                prefillAttackerId = id
                showSATOR = true
            case .crit(let unit):
                showCrit = unit
            case nil:
                break
            }
            focusFollowUp = nil
        }) { unit in
            if let session = store.session {
                UnitFocusSheet(
                    unit: unit,
                    session: session,
                    onResolveAttack: { focusFollowUp = .shot(unit.id) },
                    onRollCrit: { focusFollowUp = .crit(unit) }
                )
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )) {
            Button("OK", role: .cancel) { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "")
        }
    }

    @ViewBuilder
    private func content(_ session: MatchSession) -> some View {
        if session.status == .completed {
            VictoryView(
                session: session,
                onRematch: {
                    store.rematch(from: dependencies.content)
                    deployAcknowledged = false
                },
                onDone: {
                    store.dismissCompleted()
                    dismiss()
                },
                onBack: { attemptBack() }
            )
        } else if !session.tableReady {
            tableReady(session)
        } else {
            battleTable(session)
        }
    }

    private func tableReady(_ session: MatchSession) -> some View {
        List {
            Section {
                Text("The miniatures stay on the table. This phone only tracks turns, dice math, and damage. Sit so both players can see the screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("Set the table") {
                ForEach(Array(tableSteps(for: session).enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                }
            }
            Section("Who’s who") {
                Text("A “lance” is just a team of 'Mechs. One player takes Side A, the other takes Side B.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(session.units) { unit in
                    LabeledContent(unit.side.displayName, value: unit.name)
                }
            }
            if let notes = coachNotes, !notes.isEmpty {
                Section("For this first game") {
                    ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                        Text(note)
                    }
                }
            }
            if let winning = winningSummary {
                Section("How you win") {
                    Text(winning)
                }
            }
            Section("Dice") {
                Picker("Dice", selection: Binding(
                    get: { session.diceMode },
                    set: { store.setDiceMode($0) }
                )) {
                    Text("Manual").tag(DiceMode.manual)
                    Text("Auto").tag(DiceMode.auto)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("as.ridge.diceMode")
                Text(diceModeDetail(session.diceMode))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section {
                Button("We’re sitting on the wrong sides") {
                    store.swapSides()
                }
            }
            Section {
                Button("The table is set — start the first turn") {
                    store.markTableReady()
                }
                .accessibilityIdentifier("as.ridge.tableReady")
            }
        }
        .accessibilityIdentifier("as.ridge.tablePrep")
    }

    private var coachNotes: [String]? {
        try? dependencies.content.ridgeLineScenario().coachNotes
    }

    private var winningSummary: String? {
        try? dependencies.content.ridgeLineScenario().winningSummary
    }

    private func turnLabel(_ session: MatchSession) -> String {
        if let max = session.ruleset.maxTurns {
            return "\(session.turn) of \(max)"
        }
        return "\(session.turn)"
    }

    private func tableSteps(for session: MatchSession) -> [String] {
        if let steps = try? dependencies.content.ridgeLineScenario().tableSteps, !steps.isEmpty {
            return steps
        }
        return [
            "Clear a table about 3 feet across",
            "Set out the four 'Mechs and their cards",
            "Have two six-sided dice and a tape measure ready"
        ]
    }

    private func battleTable(_ session: MatchSession) -> some View {
        List {
            if store.canBack || store.canUndo {
                Section {
                    if store.canBack {
                        Button("Back") { attemptBack() }
                            .accessibilityIdentifier("as.battle.back")
                    }
                    if store.canUndo {
                        Button("Undo last change", systemImage: "arrow.uturn.backward") {
                            store.undo()
                        }
                    }
                }
            }

            Section {
                Text(stepHeadline(session))
                    .font(.headline)
                    .accessibilityIdentifier("as.battle.table")
                if session.phase == .movement || session.phase == .combat {
                    Text(session.activeSide.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("as.battle.activeSide")
                        .accessibilityValue(session.activeSide == .lanceA ? "lanceA" : "lanceB")
                }
                stepBody(session)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(primaryTitle(session)) { primaryAction(session) }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.bar)
                .accessibilityIdentifier("as.battle.primary")
        }
    }

    private func stepHeadline(_ session: MatchSession) -> String {
        if handoffSide != nil { return "Pass the phone" }
        if pendingCrits(session).first != nil { return "Critical hit" }
        if session.phase == .movement, session.turn == 1, !deployAcknowledged {
            return "Place the miniatures"
        }
        let turn = "Turn \(turnLabel(session))"
        switch session.phase {
        case .initiative:
            return "\(turn) · Roll dice"
        case .movement:
            if otherMechStillToMove(session) {
                return "\(turn) · \(session.activeSide.displayName)’s other ’Mech"
            }
            return "\(turn) · \(session.activeSide.displayName) moves"
        case .combat:
            return "\(turn) · \(session.activeSide.displayName) shoots"
        case .end:
            return "\(turn) · Clean up"
        }
    }

    @ViewBuilder
    private func stepBody(_ session: MatchSession) -> some View {
        if let handoffSide {
            Text("Hand the phone to \(handoffSide.displayName). Wait until they have it, then tap the button at the bottom.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("as.battle.handoff")
        } else if let owed = pendingCrits(session).first {
            Text(session.diceMode == .auto
                ? "\(owed.name) took a serious hit. The app rolls before anyone else shoots."
                : "\(owed.name) took a serious hit. Roll two dice before anyone else shoots.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if pendingCrits(session).count > 1 {
                Text("\(pendingCrits(session).count) criticals are waiting. This one is first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            switch session.phase {
            case .initiative:
                Text(session.diceMode == .auto
                    ? "We don’t have dice. The app rolls both sides. Highest total moves and shoots last. Same totals? It rolls again."
                    : "Each side rolls two dice. Highest total moves and shoots last. Same totals? Roll again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if session.diceMode == .auto {
                    Button("We have dice — enter the roll") {
                        store.setDiceMode(.manual)
                        showInitiative = true
                    }
                } else {
                    Button("We don’t have dice — let the app roll") {
                        store.setDiceMode(.auto)
                        store.rollInitiative()
                    }
                    .accessibilityIdentifier("as.battle.rollInit")
                }
                if canSwapSides(session) {
                    Button("We’re sitting on the wrong sides") { store.swapSides() }
                }
            case .movement:
                movementStep(session)
            case .combat:
                Text(combatCoach(session))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                shotsThisTurn(session)
                compactHealth(session, shooting: true)
                if pendingCrits(session).isEmpty {
                    Button("\(session.activeSide.displayName) is done shooting") {
                        let canStillShoot = session.units.contains {
                            $0.side == session.activeSide && $0.canAttackThisTurn
                        }
                        if canStillShoot {
                            showDoneShootingConfirm = true
                        } else {
                            store.finishCombatSide()
                        }
                    }
                    .accessibilityIdentifier("as.battle.doneShooting")
                }
            case .end:
                if let max = session.ruleset.maxTurns, session.turn >= max {
                    Text("Last turn. The side with the most structure left wins, even if ’Mechs are still standing. Equal structure is a draw.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("Pick up any ’Mech whose structure hit 0. Then tap the button at the bottom.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                compactHealth(session)
            }
        }
    }

    @ViewBuilder
    private func movementStep(_ session: MatchSession) -> some View {
        if session.turn == 1, !deployAcknowledged {
            Text("Put each side’s two ’Mechs within 6 inches of its own short table edge. \(session.activeSide.displayName) places one first, then take turns.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text("Move the miniature with the tape, then record how far it went.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if session.units.contains(where: { $0.combatStatus == .destroyedPendingEnd }) {
                Text("Wrecks stay where they are. They can still shoot this turn.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            movementRecorder(session)
            recordedMoveEditor(session)
        }
        if canSwapSides(session) {
            Button("We’re sitting on the wrong sides") { store.swapSides() }
        }
    }

    private func combatCoach(_ session: MatchSession) -> String {
        let now = session.activeSide.displayName
        let other = session.activeSide.other.displayName
        if session.initiativeWinner == session.activeSide {
            return "Both sides shoot this turn, one side at a time. \(other) is done. \(now) shoots now. Each of their ’Mechs gets one shot."
        }
        return "Both sides shoot this turn, one side at a time. \(now) shoots now. Each of their ’Mechs gets one shot. \(other) shoots after \(now) is done."
    }

    @ViewBuilder
    private func shotsThisTurn(_ session: MatchSession) -> some View {
        let shots = session.units.compactMap { unit -> (Int, TurnShot, String)? in
            guard let shot = unit.turnShot else { return nil }
            let index = session.eventLog.lastIndex { $0.message.hasPrefix(unit.name) } ?? 0
            return (index, shot, unit.name)
        }
        .sorted { $0.0 < $1.0 }
        if !shots.isEmpty {
            Text("Shots this turn")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(Array(shots.enumerated().reversed()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(item.2) \(item.1.hit ? "hit" : "missed") \(item.1.targetName)")
                        .font(.subheadline.weight(.semibold))
                    Text(item.1.rowDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier(item.1.hit ? "as.battle.shot.hit" : "as.battle.shot.miss")
            }
        }
    }

    @ViewBuilder
    private func compactHealth(_ session: MatchSession, shooting: Bool = false) -> some View {
        let visible = session.units.filter { $0.combatStatus != .removed }
        if shooting {
            Text("\(session.activeSide.displayName) — shooting now")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            unitRows(visible.filter { $0.side == session.activeSide }, session: session, shooting: true)
            Text(otherSideHeading(session))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            unitRows(visible.filter { $0.side != session.activeSide }, session: session, shooting: true)
        } else {
            unitRows(visible, session: session, shooting: false)
        }
    }

    private func otherSideHeading(_ session: MatchSession) -> String {
        let name = session.activeSide.other.displayName
        if session.initiativeWinner == session.activeSide {
            return "\(name) — already shot"
        }
        return "\(name) — shoots next"
    }

    @ViewBuilder
    private func unitRows(_ units: [MatchUnitState], session: MatchSession, shooting: Bool) -> some View {
        ForEach(units) { unit in
            Button {
                focusUnit = unit
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(unit.name)
                        .font(.subheadline.weight(.semibold))
                    if unit.pendingCritical {
                        Text(unit.criticalsOwed > 1 ? "\(unit.criticalsOwed) criticals waiting" : "Critical waiting")
                            .font(.caption2)
                    } else if shooting {
                        Text(shootLine(unit, session: session))
                            .font(.caption)
                            .foregroundStyle(shootLineColor(unit, session: session))
                        if let shot = unit.turnShot {
                            Text(shot.rowDetail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else if unit.combatStatus == .destroyedPendingEnd {
                        Text("Wrecked — still shoots this turn")
                            .font(.caption2)
                    } else if unit.isImmobile {
                        Text("Can’t move")
                            .font(.caption2)
                    } else if unit.movementMode == .sprint {
                        Text("Sprinted — can’t shoot")
                            .font(.caption2)
                    }
                    PipTrack(filled: unit.remainingArmor, capacity: unit.armorCap)
                    Text("Armor \(unit.remainingArmor) · Structure \(unit.remainingStructure)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("as.battle.unit.\(unit.id.uuidString)")
        }
    }

    private func shootLine(_ unit: MatchUnitState, session: MatchSession) -> String {
        let shootingNow = unit.side == session.activeSide
        let otherSideFinished = session.initiativeWinner == session.activeSide
        if !shootingNow {
            if otherSideFinished {
                if let shot = unit.turnShot { return shot.rowTitle }
                if unit.movementMode == .sprint { return "Sprinted — didn’t shoot" }
                return "Didn’t shoot"
            }
            return "Not this side’s turn"
        }
        if unit.movementMode == .sprint { return "Sprinted — can’t shoot" }
        if let shot = unit.turnShot { return shot.rowTitle }
        if unit.hasAttackedThisTurn { return "Already shot" }
        if unit.combatStatus == .destroyedPendingEnd { return "Wrecked — can still shoot" }
        if unit.canAttackThisTurn { return "Can shoot" }
        return "Can’t shoot"
    }

    private func shootLineColor(_ unit: MatchUnitState, session: MatchSession) -> Color {
        if unit.side == session.activeSide, unit.canAttackThisTurn {
            return .primary
        }
        if unit.turnShot?.hit == false {
            return .orange
        }
        return .secondary
    }

    private var eventLogSheet: some View {
        NavigationStack {
            List {
                if store.session?.eventLog.isEmpty != false {
                    Text("Nothing yet.")
                        .foregroundStyle(.secondary)
                } else if let session = store.session {
                    ForEach(session.eventLog.suffix(12).reversed()) { event in
                        Text(event.message)
                    }
                }
            }
            .navigationTitle("What just happened")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { showEventLog = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func pendingCrits(_ session: MatchSession) -> [MatchUnitState] {
        session.units.filter(\.pendingCritical)
    }

    private func otherMechStillToMove(_ session: MatchSession) -> Bool {
        let mine = session.units.filter { $0.side == session.activeSide && $0.combatStatus == .active }
        return mine.contains(where: \.hasMovedThisTurn) && mine.contains { !$0.hasMovedThisTurn }
    }

    private func canSwapSides(_ session: MatchSession) -> Bool {
        (session.phase == .initiative || session.phase == .movement)
            && !session.units.contains { $0.hasMovedThisTurn || $0.armorDamage > 0 || $0.structureDamage > 0 }
    }

    private func diceModeDetail(_ mode: DiceMode) -> String {
        switch mode {
        case .manual:
            "We have dice. You tap what you rolled. The app says whether the shot hit."
        case .auto:
            "We don’t have dice. The app rolls and says whether the shot hit."
        }
    }

    private func attemptBack() {
        if store.backNeedsConfirm {
            showBackConfirm = true
        } else {
            store.back()
            handoffSide = nil
        }
    }

    private func primaryTitle(_ session: MatchSession) -> String {
        if let handoffSide {
            return "It’s \(handoffSide.displayName)"
        }
        if let owed = pendingCrits(session).first {
            let extra = pendingCrits(session).count > 1 ? " (\(pendingCrits(session).count) left)" : ""
            return "Roll a critical\(extra) for \(owed.name)"
        }
        switch session.phase {
        case .initiative:
            return session.diceMode == .auto ? "Roll for both sides" : "Enter what we rolled"
        case .movement:
            if session.turn == 1, !deployAcknowledged {
                return "We’ve placed them — start moving"
            }
            return "Start shooting"
        case .combat:
            return "Solve a shot"
        case .end:
            return "Wrecks are off — continue"
        }
    }

    private func primaryAction(_ session: MatchSession) {
        if handoffSide != nil {
            handoffSide = nil
            return
        }
        if let owed = pendingCrits(session).first {
            showCrit = owed
            return
        }
        switch session.phase {
        case .initiative:
            if session.diceMode == .auto {
                store.rollInitiative()
            } else {
                showInitiative = true
            }
        case .movement:
            if session.turn == 1, !deployAcknowledged {
                deployAcknowledged = true
                handoffSide = session.activeSide
                return
            }
            if AlphaStrikePhaseEngine.movementComplete(units: session.units) {
                store.skipMovesAndAdvance()
            } else {
                showSkipConfirm = true
            }
        case .combat:
            prefillAttackerId = nil
            showSATOR = true
        case .end:
            store.resolveEnd()
        }
    }

    @ViewBuilder
    private func movementRecorder(_ session: MatchSession) -> some View {
        let movers = session.units.filter {
            $0.side == session.activeSide
                && $0.combatStatus == .active
                && !$0.hasMovedThisTurn
        }
        if movers.isEmpty {
            Text("\(session.activeSide.displayName) has recorded every move. If the other side still needs to move, they go next. If not, start shooting.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        ForEach(movers) { unit in
                Menu {
                    ForEach(unit.legalMovementModes, id: \.self) { mode in
                        Button(mode.displayName) {
                            store.setMove(unitId: unit.id, mode: mode)
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(unit.name)
                        Text(unit.movementMode.coachDetail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }

    @ViewBuilder
    private func recordedMoveEditor(_ session: MatchSession) -> some View {
        let recorded = session.units.filter { $0.hasMovedThisTurn && $0.combatStatus == .active }
        if !recorded.isEmpty {
            DisclosureGroup("Change a recorded move") {
                ForEach(recorded) { unit in
                    Menu {
                        ForEach(unit.legalMovementModes, id: \.self) { mode in
                            Button(mode.displayName) {
                                store.reviseMove(unitId: unit.id, mode: mode)
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(unit.name)
                            Text(unit.movementMode.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var initiativeSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Tap the faces you rolled. Highest total goes last this turn.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("Side A rolled") {
                    DiceFaces(title: "First die", value: $a1)
                    DiceFaces(title: "Second die", value: $a2)
                    Text(diceTotal(a1, a2))
                        .foregroundStyle(.secondary)
                }
                Section("Side B rolled") {
                    DiceFaces(title: "First die", value: $b1)
                    DiceFaces(title: "Second die", value: $b2)
                    Text(diceTotal(b1, b2))
                        .foregroundStyle(.secondary)
                }
                if let a1, let a2, let b1, let b2, a1 + a2 == b1 + b2 {
                    Section {
                        Text("Same total — both sides roll again, then change the numbers.")
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("as.initiative.tieHint")
                    }
                }
            }
            .navigationTitle("Dice roll")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showInitiative = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use these rolls") {
                        guard let a1, let a2, let b1, let b2 else { return }
                        store.setInitiative(a1: a1, a2: a2, b1: b1, b2: b2)
                        if store.session?.phase == .movement {
                            showInitiative = false
                            self.a1 = nil
                            self.a2 = nil
                            self.b1 = nil
                            self.b2 = nil
                        }
                    }
                    .disabled(!initiativeReady)
                    .accessibilityIdentifier("as.initiative.apply")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("as.initiative.sheet")
    }

    private var initiativeReady: Bool {
        guard let a1, let a2, let b1, let b2 else { return false }
        return a1 + a2 != b1 + b2
    }

    private func diceTotal(_ first: Int?, _ second: Int?) -> String {
        guard let first, let second else { return "Tap both dice" }
        return "Total \(first + second)"
    }
}

private enum FocusFollowUp {
    case shot(UUID)
    case crit(MatchUnitState)
}

private struct VictoryView: View {
    let session: MatchSession
    let onRematch: () -> Void
    let onDone: () -> Void
    let onBack: () -> Void
    @State private var confirmRematch = false

    var body: some View {
        ContentUnavailableView {
            Label(victoryTitle, systemImage: "flag.checkered")
        } description: {
            Text(victoryDescription)
        } actions: {
            Button("Wait — go back", action: onBack)
                .accessibilityIdentifier("as.victory.back")
            Button("Play again (same mission)") { confirmRematch = true }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("as.victory.rematch")
            Button("Back to Play", action: onDone)
                .accessibilityIdentifier("as.victory.done")
        }
        .confirmationDialog("Start a new game?", isPresented: $confirmRematch, titleVisibility: .visible) {
            Button("Start over", role: .destructive, action: onRematch)
            Button("Stay here", role: .cancel) {}
        } message: {
            Text("This throws away the game you just finished.")
        }
        .accessibilityIdentifier("as.victory")
    }

    private var victoryTitle: String {
        switch session.outcome {
        case .draw: "Draw"
        case .winner: "We have a winner"
        case nil: "Game over"
        }
    }

    private var victoryDescription: String {
        let outcome = session.outcome?.displaySummary ?? "The game is over"
        let a = VictoryEvaluator.remainingStructure(side: .lanceA, in: session)
        let b = VictoryEvaluator.remainingStructure(side: .lanceB, in: session)
        return "\(outcome) after turn \(session.turn).\nSide A structure left: \(a) · Side B: \(b)"
    }
}

private struct CritSheet: View {
    let unit: MatchUnitState
    @Bindable var store: MatchStore
    @Environment(\.dismiss) private var dismiss
    @State private var d1: Int?
    @State private var d2: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("\(unit.name) took a serious hit. The app applies the result, including a wreck or no effect.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    DiceRollEntry(
                        mode: Binding(
                            get: { store.session?.diceMode ?? .manual },
                            set: { newMode in
                                guard newMode != (store.session?.diceMode ?? .manual) else { return }
                                d1 = nil
                                d2 = nil
                                store.setDiceMode(newMode)
                            }
                        ),
                        die1: $d1,
                        die2: $d2,
                        manualPrompt: "Roll two dice on the table, then tap the faces.",
                        autoPrompt: "The app rolls two dice.",
                        identifierPrefix: "as.crit"
                    )
                    if let d1, let d2 {
                        Text(critPreview(d1 + d2))
                            .font(.headline)
                    }
                }
                Button("Apply this critical") {
                    guard let d1, let d2 else { return }
                    if store.applyPendingCrit(unitId: unit.id, die1: d1, die2: d2) {
                        dismiss()
                    }
                }
                .disabled(d1 == nil || d2 == nil)
            }
            .navigationTitle("Critical hit")
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("as.crit.sheet")
    }

    private func critPreview(_ total: Int) -> String {
        switch AlphaStrikeCriticals.resultId(forTotal: total) {
        case .ammo: "Ammo hit. Without CASE or ENE, this ’Mech is wrecked."
        case .engine: "Engine hit. A second one wrecks it, and later shots are harder."
        case .fireControl: "Fire control hit. Its shots get harder."
        case .none: "No critical."
        case .weapon: "Weapon hit. Its damage goes down."
        case .mp: "Motive hit. It moves half as far. A second one stops it."
        case .destroyed: "Destroyed. It is wrecked, and it can still shoot this turn."
        }
    }
}

struct DiceRollEntry: View {
    @Binding var mode: DiceMode
    @Binding var die1: Int?
    @Binding var die2: Int?
    var manualPrompt: String
    var autoPrompt: String
    var identifierPrefix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("How to roll", selection: $mode) {
                Text("Manual").tag(DiceMode.manual)
                Text("Auto").tag(DiceMode.auto)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("\(identifierPrefix).diceMode")

            if mode == .auto {
                Button(die1 == nil || die2 == nil ? "Roll" : "Roll again") {
                    die1 = Int.random(in: 1...6)
                    die2 = Int.random(in: 1...6)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("\(identifierPrefix).autoRoll")
                if let die1, let die2 {
                    Text("Rolled \(die1) and \(die2) · total \(die1 + die2)")
                        .foregroundStyle(.secondary)
                } else {
                    Text(autoPrompt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(manualPrompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                DiceFaces(title: "First die", value: $die1)
                    .accessibilityIdentifier("\(identifierPrefix).die1")
                DiceFaces(title: "Second die", value: $die2)
                    .accessibilityIdentifier("\(identifierPrefix).die2")
                if let die1, let die2 {
                    Text("Total \(die1 + die2)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.borderless)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
    }
}

struct DiceFaces: View {
    let title: String
    @Binding var value: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value.map { "\(title): \($0)" } ?? title)
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 6) {
                ForEach(1...6, id: \.self) { face in
                    Button {
                        value = face
                    } label: {
                        Text("\(face)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                value == face ? Color.accentColor : Color.secondary.opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .foregroundStyle(value == face ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) \(face)")
                    .accessibilityAddTraits(value == face ? .isSelected : [])
                }
            }
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
    }
}
