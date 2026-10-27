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
    @State private var distanceConfirmed = false
    @State private var showWhatHappened = false

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
                } else if !distanceConfirmed, let attacker, let defender {
                    distanceStep(attacker: attacker, defender: defender)
                } else if let solve {
                    resultStep(solve)
                }
            }
            .navigationTitle("Shot solver")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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
                distanceConfirmed = false
                d1 = nil
                d2 = nil
                showWhatHappened = false
                syncTargetMoveFromDefender()
            }
            .onChange(of: attackerId) { _, _ in
                distanceConfirmed = false
                d1 = nil
                d2 = nil
                showWhatHappened = false
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

    private func distanceStep(attacker: MatchUnitState, defender: MatchUnitState) -> some View {
        Section {
            Text("\(attacker.name) shooting \(defender.name).")
                .font(.headline)
            Stepper(value: $insight.rangeInches, in: 1...48) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tape measure: \(insight.rangeInches) inch\(insight.rangeInches == 1 ? "" : "es")")
                    Text(insight.rangeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("as.sator.range")

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
            }
            Button("Use this distance") { distanceConfirmed = true }
            Button("Different ’Mechs") {
                attackerId = nil
                defenderId = nil
            }
        }
    }

    @ViewBuilder
    private func resultStep(_ solve: CombatSolve) -> some View {
        outcomeSection(solve)
            .accessibilityIdentifier("as.sator.tnPreview")
        if solve.cannotShootReason == nil, showsDamagePreview(solve) {
            DamageResolverCard(solve: solve)
        }
        Section {
            Button("Change the distance") {
                distanceConfirmed = false
                d1 = nil
                d2 = nil
            }
        }
    }

    @ViewBuilder
    private func outcomeSection(_ solve: CombatSolve) -> some View {
        Section("Did it hit?") {
            if let reason = solve.cannotShootReason {
                Text(reason)
                    .foregroundStyle(.orange)
            } else if solve.targetNumber?.autoMiss == true {
                Text("Miss")
                    .font(.largeTitle.bold())
                    .accessibilityIdentifier("as.sator.outcome")
                Text("Need 13 or higher. This shot always misses.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let tn = solve.targetNumber {
                Text("Need \(tn.value) or higher · \(tn.hitOddsPercent)%")
                    .font(.headline)
                DiceRollEntry(
                    mode: modeBinding,
                    die1: $d1,
                    die2: $d2,
                    manualPrompt: "Roll two dice on the table, then tap the faces.",
                    autoPrompt: "The app rolls two dice.",
                    identifierPrefix: "as.sator"
                )
                if let isHit = solve.isHit {
                    Text(isHit ? "Hit" : "Miss")
                        .font(.largeTitle.bold())
                        .foregroundStyle(isHit ? .primary : .secondary)
                        .accessibilityIdentifier("as.sator.outcome")
                }
            }
            if modeBinding.wrappedValue == .auto, let detail = whatHappened(solve) {
                DisclosureGroup("What happened", isExpanded: $showWhatHappened) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(detail.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .accessibilityIdentifier("as.sator.whatHappened")
            }
            Button(applyTitle(solve)) { applyShot() }
                .disabled(!canApply(solve))
                .accessibilityIdentifier("as.sator.resolve")
        }
    }

    private func showsDamagePreview(_ solve: CombatSolve) -> Bool {
        if solve.targetNumber?.autoMiss == true { return false }
        if modeBinding.wrappedValue == .auto, solve.isHit != nil { return false }
        return true
    }

    /// Auto rolls stay a Hit or Miss until this is opened.
    private func whatHappened(_ solve: CombatSolve) -> [String]? {
        guard let tn = solve.targetNumber else { return nil }
        guard solve.isHit != nil || tn.autoMiss else { return nil }

        var lines: [String] = ["\(solve.attackerName) shooting \(solve.defenderName)."]
        if let roll = solve.roll {
            lines.append("Rolled \(roll.die1) and \(roll.die2). Total \(roll.total).")
            if tn.autoMiss {
                lines.append("Two dice can’t reach \(tn.value), so it misses.")
            } else if roll.total >= tn.value {
                lines.append("\(roll.total) is at least \(tn.value), so it hits.")
            } else {
                lines.append("\(roll.total) is under \(tn.value), so it misses.")
            }
        } else if tn.autoMiss {
            lines.append("Two dice can’t reach \(tn.value), so it misses.")
        }
        lines.append(contentsOf: tn.reasons)

        if solve.isHit == true {
            let damage = solve.roll?.isNaturalTwelve == true ? solve.ifNaturalTwelve : solve.ifHit
            lines.append(contentsOf: damageLines(damage, boxcars: solve.roll?.isNaturalTwelve == true))
        } else if solve.isHit == false || tn.autoMiss {
            lines.append("No damage.")
            if !solve.ifHit.zeroDamage {
                lines.append("A hit would have done \(solve.ifHit.delivered) damage.")
            }
        }
        return lines
    }

    private func damageLines(_ damage: CombatDamagePreview, boxcars: Bool) -> [String] {
        if damage.zeroDamage {
            return ["Hit for 0 damage at this range. The shot is still used."]
        }
        var lines = [
            "\(damage.delivered) damage. Armor \(damage.armorBefore) → \(damage.armorAfter). Structure \(damage.structureBefore) → \(damage.structureAfter)."
        ]
        if damage.wrecksThisTurn {
            lines.append("That wrecks them. They can still shoot this turn. Take the model off at Clean up.")
        } else if damage.needsCritical {
            lines.append(boxcars
                ? "Two 6s. A critical happens even if armor stopped the damage."
                : "Structure was hit, so a critical is owed.")
        } else {
            lines.append("Armor stopped it. A critical only happens on two 6s.")
        }
        return lines
    }

    private func applyTitle(_ solve: CombatSolve) -> String {
        if solve.cannotShootReason != nil { return "Can’t apply this shot" }
        if solve.targetNumber?.autoMiss == true { return "Always misses — this uses the shot" }
        if solve.isHit == true {
            if solve.ifHit.zeroDamage { return "Hit for 0 — this still uses the shot" }
            return "Apply hit — \(solve.ifHit.delivered) damage"
        }
        if solve.isHit == false { return "Apply miss" }
        return "Apply this shot"
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
                    if solve.ifHit.wrecksThisTurn {
                        Text("That wrecks them. They can still shoot this turn; take the model off at Clean up.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if solve.ifHit.needsCritical {
                        Text("You’ll also roll a critical. Structure was hit.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Armor absorbs it. A critical only happens on two 6s.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                if solve.isHit == true, solve.roll?.isNaturalTwelve == true, solve.ifNaturalTwelve.needsCritical {
                    Text("Two 6s: a critical happens even if armor stopped the damage.")
                        .font(.subheadline)
                }
            }
        }
    }
}
