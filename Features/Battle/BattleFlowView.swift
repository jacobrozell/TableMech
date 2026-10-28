import SwiftUI
import UIKit
import TableMechDomain

struct BattleFlowView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Bindable var store: MatchStore
    @Environment(\.dismiss) private var dismiss

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
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
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
                    if store.canBack {
                        Button("Back", systemImage: "chevron.backward") {
                            attemptBack()
                        }
                        .accessibilityIdentifier("as.battle.back")
                    }
                    if store.canUndo {
                        Button("Undo last change", systemImage: "arrow.uturn.backward") {
                            store.undo()
                        }
                    }
                    if let session = store.session {
                        let coach = BattleCoach(session: session)
                        if coach.canSwapSides {
                            Button("Swap sides", systemImage: "arrow.left.arrow.right") {
                                store.swapSides()
                            }
                        }
                        if coach.step == .movement, !coach.movementComplete {
                            Button("Skip remaining moves", systemImage: "forward.end") {
                                showSkipConfirm = true
                            }
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
            guard store.session == nil else { return }
            do {
                if try store.resumeActive() { return }
            } catch {
                store.lastError = error.localizedDescription
                return
            }
            store.startRidgeLine(from: dependencies.content, replaceActive: false)
        }
        .onChange(of: store.session?.status) { _, status in
            if status == .abandoned || store.session == nil {
                dismiss()
            }
        }
        .onChange(of: store.session?.phase) { _, new in
            if new == .initiative {
                a1 = nil
                a2 = nil
                b1 = nil
                b2 = nil
            }
        }
        .sheet(isPresented: $showEventLog) {
            eventLogSheet
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
        let coach = BattleCoach(session: session)
        if coach.step == .victory {
            VictoryView(
                session: session,
                onRematch: {
                    store.rematch(from: dependencies.content)
                },
                onDone: {
                    store.dismissCompleted()
                    dismiss()
                },
                onBack: { attemptBack() }
            )
        } else if coach.step == .tableSetup {
            tableReady(session, coach: coach)
        } else {
            battleTable(session, coach: coach)
        }
    }

    private func tableReady(_ session: MatchSession, coach: BattleCoach) -> some View {
        List {
            Section("Set the table") {
                ForEach(Array(tableSteps(for: session).enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                }
            }
            Section {
                ForEach(SideId.allCases, id: \.self) { side in
                    let sideUnits = session.units.filter { $0.side == side }
                    if !sideUnits.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(side.displayName)
                                .font(.subheadline.weight(.semibold))
                            ForEach(sideUnits) { unit in
                                Text(unit.name)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                }
            } header: {
                HStack {
                    Text("Who’s who")
                    Spacer(minLength: 8)
                    if coach.canSwapSides {
                        Button {
                            store.swapSides()
                        } label: {
                            Label("Swap", systemImage: "arrow.left.arrow.right")
                                .labelStyle(.titleAndIcon)
                                .font(.subheadline)
                                .frame(minHeight: 44)
                        }
                        .buttonStyle(.borderless)
                        .textCase(nil)
                        .accessibilityLabel("Swap sides")
                        .accessibilityHint("Trades which player has which ’Mechs")
                        .accessibilityIdentifier("as.battle.swapSides")
                    }
                }
            }
            if let winning = winningSummary {
                Section {
                    HStack(alignment: .center, spacing: 0) {
                        Text("How you win")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        InfoButton(title: "How you win") { _ in
                            Text(winning)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
            Section {
                Button {
                    store.markTableReady()
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("as.ridge.tableReady")
            }
        }
        .accessibilityIdentifier("as.ridge.tablePrep")
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

    private func battleTable(_ session: MatchSession, coach: BattleCoach) -> some View {
        List {
            Section {
                Text(stepHeadline(session, coach: coach))
                    .font(.headline)
                    .accessibilityIdentifier("as.battle.table")
                    .background {
                        if coach.step == .movement || coach.step == .combat || coach.step == .placeMiniatures {
                            Color.clear
                                .accessibilityElement()
                                .accessibilityIdentifier("as.battle.activeSide")
                                .accessibilityLabel("Active side, \(session.activeSide.displayName)")
                                .accessibilityValue(session.activeSide == .lanceA ? "lanceA" : "lanceB")
                        }
                    }
                stepBody(session, coach: coach)
            }
        }
        .accessibilityIdentifier("as.battle.screen")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if coach.primary != nil || showsDoneShooting(coach) {
                HStack(spacing: 12) {
                    if showsDoneShooting(coach) {
                        Button {
                            finishShooting(coach)
                        } label: {
                            Text("Done shooting")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .accessibilityLabel("\(session.activeSide.displayName) is done shooting")
                        .accessibilityIdentifier("as.battle.doneShooting")
                    }
                    if let primary = coach.primary {
                        Button {
                            primaryAction(session, coach: coach)
                        } label: {
                            Text(primaryTitle(primary))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(primary == .useInitiativeRolls && !initiativeReady)
                        .accessibilityIdentifier("as.battle.primary")
                        .accessibilityHint(primaryHint(primary))
                    }
                }
                .padding()
                .background(.bar)
            }
        }
    }

    private func stepHeadline(_ session: MatchSession, coach: BattleCoach) -> String {
        if coach.pendingCritical != nil { return "Critical hit" }
        let turn = "Turn \(turnLabel(session))"
        switch coach.step {
        case .placeMiniatures:
            return "Place the miniatures"
        case .initiative:
            return "\(turn) · Roll dice"
        case .movement:
            if coach.otherMechStillToMove {
                return "\(turn) · \(session.activeSide.displayName)’s other ’Mech"
            }
            return "\(turn) · \(session.activeSide.displayName) moves"
        case .combat:
            return "\(turn) · \(session.activeSide.displayName) shoots"
        case .end:
            return "\(turn) · Clean up"
        case .tableSetup, .victory:
            return turn
        }
    }

    @ViewBuilder
    private func stepBody(_ session: MatchSession, coach: BattleCoach) -> some View {
        if let owed = coach.pendingCritical {
            Text(session.diceMode == .auto
                ? "\(owed.unitName) took a serious hit. The app rolls before anyone else shoots."
                : "\(owed.unitName) took a serious hit. Roll two dice before anyone else shoots.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if owed.count > 1 {
                Text("\(owed.count) criticals are waiting. This one is first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        switch coach.step {
            case .initiative:
                initiativeEntry()
            case .placeMiniatures, .movement:
                movementStep(session, coach: coach)
            case .combat:
                shotsThisTurn(session)
                compactHealth(session, shooting: true)
            case .end:
                HStack(alignment: .center, spacing: 0) {
                    Text("Take wrecks off the table.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let max = session.ruleset.maxTurns, session.turn >= max {
                        InfoButton(title: "How the game can end") { _ in
                            Text("Last turn. The side with the most structure left wins, even if ’Mechs are still standing. Equal structure is a draw.")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .buttonStyle(.borderless)
                compactHealth(session)
            case .tableSetup, .victory:
                EmptyView()
            }
    }

    @ViewBuilder
    private func movementStep(_ session: MatchSession, coach: BattleCoach) -> some View {
        if coach.step == .placeMiniatures {
            HStack(alignment: .top, spacing: 0) {
                Text("Place each side on its own short edge. \(session.activeSide.displayName) places first.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                InfoButton(title: "About placement") { _ in
                    Text("Put each side’s ’Mechs within 6 inches of its own short edge.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .buttonStyle(.borderless)
        } else {
            Group {
                Text("Measure, then tap how it moved.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if session.units.contains(where: { $0.combatStatus == .destroyedPendingEnd }) {
                    Text("Wrecks stay. They can still shoot.")
                }
                recordedMoveChecks(session)
                movementRecorder(session)
                recordedMoveEditor(session)
            }
            .buttonStyle(.borderless)
        }
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.2) \(item.1.hit ? "hit" : "missed") \(item.1.targetName). \(item.1.rowDetail)")
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
                    } else if unit.combatStatus == .destroyedPendingEnd {
                        Text("Wrecked — still shoots")
                            .font(.caption2)
                    } else if unit.isImmobile {
                        Text("Can’t move")
                            .font(.caption2)
                    } else if unit.movementMode == .sprint {
                        Text("Can’t shoot")
                            .font(.caption2)
                    } else if let shot = unit.turnShot {
                        Text(shot.rowTitle)
                            .font(.caption)
                        Text(shot.rowDetail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text("Armor \(unit.remainingArmor)/\(unit.armorCap)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Structure \(unit.remainingStructure)/\(unit.structureCap)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(unitAccessibilityLabel(unit))
            .accessibilityHint("Opens this ’Mech")
            .accessibilityIdentifier("as.battle.unit.\(unit.id.uuidString)")
        }
    }

    private func unitAccessibilityLabel(_ unit: MatchUnitState) -> String {
        var parts: [String] = [unit.name]
        if unit.pendingCritical {
            parts.append(unit.criticalsOwed > 1 ? "\(unit.criticalsOwed) criticals waiting" : "Critical waiting")
        } else if unit.combatStatus == .destroyedPendingEnd {
            parts.append("Wrecked — still shoots")
        } else if unit.isImmobile {
            parts.append("Can’t move")
        } else if unit.movementMode == .sprint {
            parts.append("Can’t shoot")
        } else if let shot = unit.turnShot {
            parts.append(shot.rowTitle)
            parts.append(shot.rowDetail)
        }
        parts.append("Armor \(unit.remainingArmor) of \(unit.armorCap)")
        parts.append("Structure \(unit.remainingStructure) of \(unit.structureCap)")
        return parts.joined(separator: ", ")
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

    private func attemptBack() {
        if store.backNeedsConfirm {
            showBackConfirm = true
        } else {
            store.back()
        }
    }

    private func primaryTitle(_ primary: BattleCoach.Primary) -> String {
        switch primary {
        case .acknowledgeDeployment:
            "Placed"
        case .useInitiativeRolls:
            if let name = initiativeLeaderName { "\(name) goes first" } else { "Use rolls" }
        case .rollInitiative:
            "Roll"
        case .startShooting:
            "Start shooting"
        case .solveShot:
            "Solve a shot"
        case .rollCritical(let count):
            count > 1 ? "Critical (\(count))" : "Critical"
        case .resolveEnd:
            "Continue"
        }
    }

    private func primaryHint(_ primary: BattleCoach.Primary) -> String {
        switch primary {
        case .acknowledgeDeployment:
            "Records that the miniatures are placed."
        case .useInitiativeRolls:
            if let name = initiativeLeaderName {
                "\(name) moves first."
            } else {
                "Uses these dice to decide who goes first."
            }
        case .rollInitiative:
            "Rolls both sides to decide who goes first."
        case .startShooting:
            "Ends movement and starts shooting."
        case .solveShot:
            "Opens the shot solver."
        case .rollCritical(let count):
            count > 1 ? "Opens the next critical roll. \(count) are waiting." : "Opens the critical roll."
        case .resolveEnd:
            "Finishes cleanup and continues the game."
        }
    }

    private func primaryAction(_ session: MatchSession, coach: BattleCoach) {
        switch coach.primary {
        case .rollCritical:
            if let pending = coach.pendingCritical,
               let unit = session.units.first(where: { $0.id == pending.unitId }) {
                showCrit = unit
            }
        case .rollInitiative:
            store.rollInitiative()
        case .useInitiativeRolls:
            if initiativeReady, let a1, let a2, let b1, let b2 {
                store.setInitiative(a1: a1, a2: a2, b1: b1, b2: b2)
                self.a1 = nil
                self.a2 = nil
                self.b1 = nil
                self.b2 = nil
            }
        case .acknowledgeDeployment:
            store.acknowledgeDeployment()
        case .startShooting:
            if coach.movementComplete {
                store.skipMovesAndAdvance()
            } else {
                showSkipConfirm = true
            }
        case .solveShot:
            prefillAttackerId = nil
            showSATOR = true
        case .resolveEnd:
            store.resolveEnd()
        case nil:
            break
        }
    }

    @ViewBuilder
    private func movementRecorder(_ session: MatchSession) -> some View {
        let movers = session.units.filter {
            $0.side == session.activeSide
                && $0.combatStatus == .active
                && !$0.hasMovedThisTurn
        }
        if let unit = movers.first {
            HStack(alignment: .center, spacing: 0) {
                Text(unit.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let hint = moveHint(for: unit), !unit.isImmobile {
                    InfoButton(title: "About moving") { _ in
                        Text(hint)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .buttonStyle(.borderless)
            if let move = PrintedMove(unit.effectiveMV), !unit.isImmobile {
                Text(move.summary)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(move.spokenSummary)
            }
            ForEach(unit.legalMovementModes, id: \.self) { mode in
                let move = PrintedMove(unit.effectiveMV)
                Button {
                    store.setMove(unitId: unit.id, mode: mode)
                } label: {
                    Text(moveButtonLabel(mode, move: unit.isImmobile ? nil : move))
                        .font(.body.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .controlSize(.large)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .accessibilityLabel(move?.spokenChoice(mode) ?? moveButtonTitle(mode))
                .accessibilityIdentifier("as.battle.move.\(mode.rawValue)")
            }
            if unit.isImmobile, let hint = moveHint(for: unit) {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func moveButtonTitle(_ mode: MovementMode) -> String {
        switch mode {
        case .unset: "Move"
        case .standstill: "Still"
        case .ground: "Walk"
        case .sprint: "Sprint"
        case .jump: "Jump"
        }
    }

    private func moveButtonLabel(_ mode: MovementMode, move: PrintedMove?) -> String {
        guard let move, let detail = move.detail(for: mode) else { return moveButtonTitle(mode) }
        return "\(moveButtonTitle(mode)) · \(detail)"
    }

    private func moveHint(for unit: MatchUnitState) -> String? {
        if unit.isImmobile { return "Can’t move." }
        var parts: [String] = []
        if unit.legalMovementModes.contains(.sprint) { parts.append("Sprint can’t shoot.") }
        if unit.legalMovementModes.contains(.jump) { parts.append("Jump shoots worse.") }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    @ViewBuilder
    private func recordedMoveChecks(_ session: MatchSession) -> some View {
        let recorded = session.units.filter {
            $0.side == session.activeSide && $0.hasMovedThisTurn && $0.combatStatus == .active
        }
        ForEach(recorded) { unit in
            let choice = moveButtonTitle(unit.movementMode)
            Label("\(unit.name) · \(choice)", systemImage: "checkmark")
                .font(.subheadline.weight(.semibold))
                .accessibilityLabel("\(unit.name), \(choice)")
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

    @ViewBuilder
    private func initiativeEntry() -> some View {
        DiceModePicker(mode: diceModeBinding, identifier: "as.battle.rollInit")
        if (store.session?.diceMode ?? .manual) == .manual {
            Text(SideId.lanceA.displayName)
                .font(.subheadline.weight(.semibold))
            DiceFaces(title: "First die", value: $a1)
            DiceFaces(title: "Second die", value: $a2)
            diceTotalLine(a1, a2)
            Text(SideId.lanceB.displayName)
                .font(.subheadline.weight(.semibold))
            DiceFaces(title: "First die", value: $b1)
            DiceFaces(title: "Second die", value: $b2)
            diceTotalLine(b1, b2)
            if let a1, let a2, let b1, let b2, a1 + a2 == b1 + b2 {
                Text("Same total — roll again.")
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityIdentifier("as.initiative.tieHint")
            } else if let name = initiativeLeaderName {
                Text("\(name) goes first")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        } else {
            Text("The app rolls both sides. The Roll button is below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func showsDoneShooting(_ coach: BattleCoach) -> Bool {
        coach.step == .combat && coach.pendingCritical == nil
    }

    private func finishShooting(_ coach: BattleCoach) {
        if coach.finishCombatNeedsConfirm {
            showDoneShootingConfirm = true
        } else {
            store.finishCombatSide()
        }
    }

    private var diceModeBinding: Binding<DiceMode> {
        Binding(
            get: { store.session?.diceMode ?? .manual },
            set: { newMode in
                a1 = nil
                a2 = nil
                b1 = nil
                b2 = nil
                store.setDiceMode(newMode)
            }
        )
    }

    private var initiativeReady: Bool {
        initiativeLeaderName != nil
    }

    private var initiativeLeaderName: String? {
        guard let a1, let a2, let b1, let b2 else { return nil }
        let sideA = a1 + a2
        let sideB = b1 + b2
        if sideA > sideB { return SideId.lanceA.displayName }
        if sideB > sideA { return SideId.lanceB.displayName }
        return nil
    }

    @ViewBuilder
    private func diceTotalLine(_ first: Int?, _ second: Int?) -> some View {
        if let first, let second {
            Text("\(first + second)")
                .font(.title.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityLabel("Total \(first + second)")
        } else {
            Text("Tap both dice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
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
                    HStack(alignment: .center, spacing: 0) {
                        Text(unit.name)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        InfoButton(title: "About criticals") { _ in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(unit.name) took a serious hit. The app applies the result, including a wreck or no effect.")
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let d1, let d2, critPreview(d1 + d2) != critOneLine(d1 + d2) {
                                    Text(critPreview(d1 + d2))
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderless)
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
                        Text(critOneLine(d1 + d2))
                            .font(.headline)
                    }
                }
                Button {
                    guard let d1, let d2 else { return }
                    if store.applyPendingCrit(unitId: unit.id, die1: d1, die2: d2) {
                        dismiss()
                    }
                } label: {
                    Text("Apply this critical")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(d1 == nil || d2 == nil)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("as.crit.confirm")
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

    private func critOneLine(_ total: Int) -> String {
        let full = critPreview(total)
        guard let dot = full.firstIndex(of: ".") else { return full }
        let after = full.index(after: dot)
        if after == full.endIndex { return full }
        return String(full[...dot])
    }
}

struct DiceModePicker: View {
    @Binding var mode: DiceMode
    var identifier: String

    var body: some View {
        Picker("How to roll", selection: $mode) {
            Text("Real dice").tag(DiceMode.manual)
            Text("In the app").tag(DiceMode.auto)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel("How to roll")
        .accessibilityHint("Real dice on the table, or the app rolls")
        .accessibilityIdentifier(identifier)
    }
}

struct DiceRollEntry: View {
    @Binding var mode: DiceMode
    @Binding var die1: Int?
    @Binding var die2: Int?
    var manualPrompt: String
    var autoPrompt: String
    var identifierPrefix: String

    private var clearingMode: Binding<DiceMode> {
        Binding(
            get: { mode },
            set: { newMode in
                guard newMode != mode else { return }
                die1 = nil
                die2 = nil
                mode = newMode
            }
        )
    }

    var body: some View {
        Group {
            DiceModePicker(mode: clearingMode, identifier: "\(identifierPrefix).diceMode")
            if mode == .auto {
                Button {
                    die1 = Int.random(in: 1...6)
                    die2 = Int.random(in: 1...6)
                } label: {
                    Text(die1 == nil || die2 == nil ? "Roll" : "Roll again")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("\(identifierPrefix).autoRoll")
                if let die1, let die2 {
                    Text("Rolled \(die1) and \(die2) · total \(die1 + die2)")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text(autoPrompt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
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
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

/// Card move such as `10"j`, `10"/6"j`, or `16"`, including a halved MP hit.
private struct PrintedMove {
    var walk: Int
    var jump: Int?

    init?(_ mv: String) {
        let parts = mv.split(separator: "/")
        guard let first = parts.first else { return nil }
        let walkDigits = String(first.filter(\.isNumber))
        guard let walk = Int(walkDigits) else { return nil }
        self.walk = walk
        if parts.count >= 2 {
            let jumpDigits = String(parts[1].filter(\.isNumber))
            jump = Int(jumpDigits)
        } else if first.contains("j") {
            jump = walk
        } else {
            jump = nil
        }
    }

    var sprint: Int { Int((Double(walk) * 1.5).rounded()) }

    var summary: String {
        if let jump {
            if jump == walk { return "\(walk)″ walk or jump" }
            return "\(walk)″ walk · \(jump)″ jump"
        }
        return "\(walk)″ walk"
    }

    var spokenSummary: String {
        if let jump {
            if jump == walk { return "\(walk) inches, walk or jump" }
            return "\(walk) inches walk, \(jump) inches jump"
        }
        return "\(walk) inches walk"
    }

    func detail(for mode: MovementMode) -> String? {
        switch mode {
        case .standstill: "under 1″"
        case .ground: "\(walk)″"
        case .sprint: "about \(sprint)″"
        case .jump: jump.map { "\($0)″" }
        case .unset: nil
        }
    }

    func spokenChoice(_ mode: MovementMode) -> String {
        switch mode {
        case .standstill: "Still, under 1 inch"
        case .ground: "Walk, \(walk) inches"
        case .sprint: "Sprint, about \(sprint) inches. Can’t shoot this turn."
        case .jump: jump.map { "Jump, \($0) inches" } ?? "Jump"
        case .unset: "Move"
        }
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
