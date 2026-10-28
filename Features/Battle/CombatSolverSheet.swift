import SwiftUI
import TableMechDomain

struct CombatSolverSheet: View {
    let session: MatchSession
    @Bindable var store: MatchStore
    var initialAttackerId: UUID?
    @Environment(\.dismiss) private var dismiss

    @State private var attackerId: UUID?
    @State private var defenderId: UUID?
    @State private var insight = CombatTableInsight()
    @State private var d1: Int?
    @State private var d2: Int?
    @State private var showUnusual = false
    @ScaledMetric(relativeTo: .largeTitle) private var tnSize = 44

    private var attackers: [MatchUnitState] {
        session.units.filter { $0.side == session.activeSide && $0.canAttackThisTurn }
    }

    private var defenders: [MatchUnitState] {
        session.units.filter {
            $0.side != session.activeSide && $0.combatStatus != .removed
        }
    }

    private var attacker: MatchUnitState? {
        attackerId.flatMap { id in session.units.first { $0.id == id } }
    }

    private var defender: MatchUnitState? {
        defenderId.flatMap { id in session.units.first { $0.id == id } }
    }

    private var roll: DiceRoll2D6? {
        guard let d1, let d2 else { return nil }
        return DiceRoll2D6.validated(die1: d1, die2: d2)
    }

    private var modeBinding: Binding<DiceMode> {
        Binding(
            get: { store.session?.diceMode ?? session.diceMode },
            set: { newMode in
                guard newMode != (store.session?.diceMode ?? session.diceMode) else { return }
                d1 = nil
                d2 = nil
                store.setDiceMode(newMode)
            }
        )
    }

    private var solve: CombatSolve? {
        guard let attacker, let defender else { return nil }
        return CombatSolver.solve(
            attacker: attacker,
            defender: defender,
            insight: insight,
            overheatAllowed: session.ruleset.overheatAllowed,
            roll: roll
        )
    }

    private var rangeBandCaption: String {
        switch insight.rangeBracket {
        case .short: "6 inches or less"
        case .medium: "7\u{2013}24 inches"
        case .long: "25\u{2013}42 inches"
        case .outOfRange: "More than 42 inches"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if attackers.isEmpty {
                    Section {
                        Text("\(session.activeSide.displayName) has no shots left. Close this and tap Done shooting.")
                            .foregroundStyle(.orange)
                    }
                } else if attacker == nil || defender == nil {
                    pairPickers
                } else if let attacker, let defender, let solve {
                    shotScreen(attacker: attacker, defender: defender, solve: solve)
                }
            }
            .navigationTitle("Shot solver")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if attacker != nil, defender != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Change") {
                            attackerId = nil
                            defenderId = nil
                        }
                        .accessibilityLabel("Different ’Mechs")
                    }
                }
            }
            .onAppear {
                if attackerId == nil {
                    if let initialAttackerId, attackers.contains(where: { $0.id == initialAttackerId }) {
                        attackerId = initialAttackerId
                    } else if attackers.count == 1 {
                        attackerId = attackers[0].id
                    }
                }
                if defenderId == nil, defenders.count == 1 {
                    defenderId = defenders[0].id
                }
                syncTargetMoveFromDefender()
            }
            .onChange(of: defenderId) { _, _ in
                d1 = nil
                d2 = nil
                syncTargetMoveFromDefender()
            }
            .onChange(of: attackerId) { _, _ in
                d1 = nil
                d2 = nil
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("as.sator.sheet")
    }

    private func syncTargetMoveFromDefender() {
        guard let defender else { return }
        if defender.isImmobile {
            insight.targetMove = .immobile
        } else {
            insight.targetMove = defender.movementMode.asTargetMoveModifier
        }
    }

    private var pairPickers: some View {
        Section("Who vs who") {
            Picker("Shooter", selection: $attackerId) {
                Text("Choose…").tag(Optional<UUID>.none)
                ForEach(attackers) { u in
                    Text(u.name).tag(Optional(u.id))
                }
            }
            .accessibilityIdentifier("as.sator.attacker")
            Picker("Target", selection: $defenderId) {
                Text("Choose…").tag(Optional<UUID>.none)
                ForEach(defenders) { u in
                    Text(u.name).tag(Optional(u.id))
                }
            }
            .accessibilityIdentifier("as.sator.target")
        }
    }

    @ViewBuilder
    private func shotScreen(attacker: MatchUnitState, defender: MatchUnitState, solve: CombatSolve) -> some View {
        Section {
            Text("\(attacker.name) → \(defender.name)")
                .font(.headline)
            Picker("Range", selection: Binding(
                get: {
                    let bracket = insight.rangeBracket
                    return bracket == .outOfRange ? RangeBracket.long : bracket
                },
                set: { newValue in
                    switch newValue {
                    case .short: insight.rangeInches = 6
                    case .medium: insight.rangeInches = 24
                    case .long: insight.rangeInches = 42
                    case .outOfRange: insight.rangeInches = 43
                    }
                }
            )) {
                Text("Short").tag(RangeBracket.short)
                Text("Medium").tag(RangeBracket.medium)
                Text("Long").tag(RangeBracket.long)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("as.sator.range")
            Text(rangeBandCaption)
                .font(.caption)
                .foregroundStyle(.secondary)
            if defender.isImmobile {
                Text("The target can’t move, so this shot is easier.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Recorded move: \(defender.movementMode.displayName).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            DisclosureGroup("Anything unusual?", isExpanded: $showUnusual) {
                Picker("How did the target move?", selection: $insight.targetMove) {
                    Text("Walked or sprinted").tag(TargetMoveModifier.groundUsesTMM)
                    Text("Stood still (under 1 inch)").tag(TargetMoveModifier.standstill)
                    Text("Jumped").tag(TargetMoveModifier.jumpedUsesTMMPlus1)
                    Text("Can’t move").tag(TargetMoveModifier.immobile)
                }
                .accessibilityIdentifier("as.sator.tgtMove")
                Toggle("Trees in the way, or target in trees", isOn: $insight.woods)
                Toggle("Solid cover hiding part of them", isOn: $insight.partialCover)
                Toggle("Shot into their rear", isOn: $insight.rearHit)
                Toggle("I can see the target", isOn: $insight.canSeeTarget)
                Toggle("They’re in front of the shooter", isOn: $insight.targetInFrontArc)
                Button("More than 42 inches") { insight.rangeInches = 43 }
            }
            .accessibilityHint("More shot conditions")
        }
        if insight.rangeBracket != .outOfRange {
            Section {
                DiceRollEntry(
                    mode: modeBinding,
                    die1: $d1,
                    die2: $d2,
                    manualPrompt: "Tap the faces you rolled.",
                    autoPrompt: "The app rolls.",
                    identifierPrefix: "as.sator"
                )
            }
        }
        outcomeSection(solve)
        if solve.cannotShootReason == nil, solve.targetNumber?.autoMiss != true {
            DamageResolverCard(solve: solve)
        }
    }

    @ViewBuilder
    private func outcomeSection(_ solve: CombatSolve) -> some View {
        Section {
            if let reason = solve.cannotShootReason {
                Text(reason)
                    .foregroundStyle(.orange)
            } else if solve.targetNumber?.autoMiss == true {
                Label("Miss", systemImage: "xmark.circle")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityLabel("Miss")
                    .accessibilityIdentifier("as.sator.outcome")
                Text("Need 13 or higher. This shot always misses.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let tn = solve.targetNumber {
                VStack(spacing: 2) {
                    Text("\(tn.value)+")
                        .font(.system(size: tnSize, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                    Text("or higher")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .multilineTextAlignment(.center)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Target number \(tn.value) or higher")
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("as.sator.tnPreview")
                if let isHit = solve.isHit {
                    if isHit {
                        Label("Hit", systemImage: "checkmark.circle")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .accessibilityLabel("Hit")
                            .accessibilityIdentifier("as.sator.outcome")
                    } else {
                        Label("Miss", systemImage: "xmark.circle")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .accessibilityLabel("Miss")
                            .accessibilityIdentifier("as.sator.outcome")
                    }
                }
            }
            Button {
                applyShot()
            } label: {
                Text(applyTitle(solve))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canApply(solve))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .accessibilityIdentifier("as.sator.resolve")
            .accessibilityHint("Records this shot")
        }
    }

    private func applyTitle(_ solve: CombatSolve) -> String {
        if solve.cannotShootReason != nil { return "Can’t apply" }
        if solve.targetNumber?.autoMiss == true { return "Apply miss" }
        if solve.isHit == true {
            if solve.ifHit.zeroDamage { return "Apply hit" }
            return "Apply \(solve.ifHit.delivered) damage"
        }
        if solve.isHit == false { return "Apply miss" }
        return "Apply"
    }

    private var applyingFaces: (Int, Int)? {
        if let d1, let d2 { return (d1, d2) }
        if solve?.targetNumber?.autoMiss == true { return (1, 1) }
        return nil
    }

    private func canApply(_ solve: CombatSolve) -> Bool {
        applyingFaces != nil && attackerId != nil && defenderId != nil && solve.canApply
    }

    private func applyShot() {
        guard let attackerId, let defenderId, let attacker, let faces = applyingFaces else { return }
        let d1 = faces.0
        let d2 = faces.1
        let move = attacker.movementMode == .unset ? MovementMode.ground : attacker.movementMode
        if store.applyAttack(
            attackerId: attackerId,
            defenderId: defenderId,
            range: insight.rangeBracket,
            die1: d1,
            die2: d2,
            attackerMove: move,
            targetMove: insight.targetMove,
            woods: insight.woods,
            partialCover: insight.partialCover,
            rearHit: insight.rearHit
        ) {
            dismiss()
        }
    }
}

private struct DamageResolverCard: View {
    let solve: CombatSolve

    private var boxcarsOweCritical: Bool {
        solve.isHit == true && solve.roll?.isNaturalTwelve == true && solve.ifNaturalTwelve.needsCritical
    }

    private var statusLine: String? {
        if solve.ifHit.wrecksThisTurn { return "This wrecks them." }
        if solve.ifHit.needsCritical || boxcarsOweCritical { return "A critical is owed." }
        return nil
    }

    private var whatHappensNext: String? {
        var parts: [String] = []
        if !solve.ifHit.zeroDamage {
            if solve.ifHit.wrecksThisTurn {
                parts.append("That wrecks them. They can still shoot this turn; take the model off at Clean up.")
            } else if solve.ifHit.needsCritical {
                parts.append("You’ll also roll a critical. Structure was hit.")
            } else {
                parts.append("Armor absorbs it. A critical only happens on two 6s.")
            }
        }
        if boxcarsOweCritical {
            parts.append("Two 6s: a critical happens even if armor stopped the damage.")
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: "\n")
    }

    var body: some View {
        Section("If this hits") {
            VStack(alignment: .leading, spacing: 6) {
                if solve.ifHit.zeroDamage {
                    Text("0 damage at this range. Applying it still uses this ’Mech’s shot.")
                        .foregroundStyle(.orange)
                } else {
                    Text("\(solve.ifHit.delivered) damage to \(solve.defenderName)")
                    Text("Armor \(solve.ifHit.armorBefore) → \(solve.ifHit.armorAfter)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Structure \(solve.ifHit.structureBefore) → \(solve.ifHit.structureAfter)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let statusLine {
                    Text(statusLine)
                        .font(.subheadline)
                }
            }
            if let explanation = whatHappensNext {
                HStack {
                    Text("What happens next")
                    Spacer(minLength: 8)
                    InfoButton(title: "What happens next") { _ in
                        Text(explanation)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
