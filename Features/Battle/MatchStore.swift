import Foundation
import Observation
import TableMechData
import TableMechDomain

@Observable
@MainActor
final class MatchStore: Identifiable {
    let id = UUID()
    private(set) var session: MatchSession?
    var lastError: String?
    private let repository: any MatchSessionRepository
    private var undoStack: [MatchSession] = []

    var isActive: Bool {
        guard let session else { return false }
        return session.status == .active
    }

    var canUndo: Bool { !undoStack.isEmpty }

    init(repository: any MatchSessionRepository) {
        self.repository = repository
    }

    func startRidgeLine(from catalog: any ContentCatalogRepository) {
        do {
            if let existing = try repository.loadActive(mode: .alphaStrike) {
                try repository.delete(id: existing.id)
            }
            let dto = try catalog.ridgeLineScenario()
            let ruleset = RidgeLineFactory.mapRuleset(dto.ruleset)
            let units = RidgeLineFactory.makeUnits(from: dto)
            session = try MatchReducer.reduce(
                MatchSession(ruleset: ruleset),
                .startMission(scenarioId: .ridgeLine, ruleset: ruleset, units: units)
            )
            undoStack.removeAll()
            lastError = nil
            persist()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func rematch(from catalog: any ContentCatalogRepository) {
        if let session, session.status == .completed {
            try? repository.delete(id: session.id)
        }
        startRidgeLine(from: catalog)
    }

    func resume(_ session: MatchSession) {
        self.session = session
        undoStack = session.recoverySnapshots.map { snapshot in
            var copy = snapshot
            copy.recoverySnapshots = []
            return copy
        }
        lastError = nil
    }

    var canBack: Bool {
        guard let session else { return false }
        return MatchRecovery.handBack(current: session, undoStack: undoStack) != nil
            || MatchRecovery.previousStep(current: session, undoStack: undoStack) != nil
    }

    /// Back keeps recorded moves when it only hands the phone to the previous side.
    /// Restoring an earlier step asks first when shots, damage, or moves would disappear.
    var backNeedsConfirm: Bool {
        guard let session else { return false }
        if MatchRecovery.handBack(current: session, undoStack: undoStack) != nil {
            return false
        }
        guard let target = MatchRecovery.previousStep(current: session, undoStack: undoStack) else {
            return false
        }
        return MatchRecovery.discardsResults(current: session, restoring: target)
    }

    func back() {
        guard let session else { return }
        if let handed = MatchRecovery.handBack(current: session, undoStack: undoStack) {
            self.session = handed
            lastError = nil
            persist()
            return
        }
        guard let target = MatchRecovery.previousStep(current: session, undoStack: undoStack) else { return }
        let key = MatchStepKey(session)
        if let index = undoStack.lastIndex(where: { MatchStepKey($0) != key }) {
            undoStack = Array(undoStack.prefix(index))
        }
        self.session = target
        lastError = nil
        persist()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        session = previous
        lastError = nil
        persist()
    }

    func markTableReady() {
        mutate(.markTableReady)
    }

    /// Preference for the rest of this match. Not an undo step.
    func setDiceMode(_ mode: DiceMode) {
        guard session?.diceMode != mode else { return }
        mutate(.setDiceMode(mode), undoable: false)
    }

    func reviseMove(unitId: UUID, mode: MovementMode) {
        mutate(.reviseMovement(unitId: unitId, mode: mode))
    }

    func swapSides() {
        mutate(.swapSides)
    }

    func setInitiative(a1: Int, a2: Int, b1: Int, b2: Int) {
        guard let a = DiceRoll2D6.validated(die1: a1, die2: a2),
              let b = DiceRoll2D6.validated(die1: b1, die2: b2) else {
            lastError = "Dice must be 1–6"
            return
        }
        mutate(.setInitiative(InitiativeRolls(lanceA: a, lanceB: b)))
    }

    /// One-tap initiative: roll 2D6 each side, re-roll ties.
    func rollInitiative() {
        for _ in 0..<20 {
            let a1 = Int.random(in: 1...6)
            let a2 = Int.random(in: 1...6)
            let b1 = Int.random(in: 1...6)
            let b2 = Int.random(in: 1...6)
            guard a1 + a2 != b1 + b2 else { continue }
            setInitiative(a1: a1, a2: a2, b1: b1, b2: b2)
            return
        }
        lastError = "Could not break initiative tie"
    }

    func setMove(unitId: UUID, mode: MovementMode) {
        guard let session else { return }
        do {
            var next = try MatchReducer.reduce(session, .setMovementMode(unitId: unitId, mode: mode))
            next = try MatchReducer.reduce(next, .markMoved(unitId: unitId))
            pushUndo(session)
            self.session = next
            lastError = nil
            persist()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func skipMovesAndAdvance() {
        guard let session else { return }
        do {
            var next = try MatchReducer.reduce(session, .skipRemainingMoves)
            next = try MatchReducer.reduce(next, .advancePhase)
            pushUndo(session)
            self.session = next
            lastError = nil
            persist()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func finishCombatSide() {
        mutate(.finishCombatSide)
    }

    func resolveEnd() {
        mutate(.resolveEndPhase)
    }

    @discardableResult
    func applyAttack(
        attackerId: UUID,
        defenderId: UUID,
        range: RangeBracket,
        die1: Int,
        die2: Int,
        attackerMove: MovementMode,
        targetMove: TargetMoveModifier,
        woods: Bool = false,
        partialCover: Bool = false,
        rearHit: Bool = false
    ) -> Bool {
        guard let roll = DiceRoll2D6.validated(die1: die1, die2: die2) else {
            lastError = "Dice must be 1–6"
            return false
        }
        mutate(
            .resolveSATOR(
                SATORAttackCommand(
                    attackerId: attackerId,
                    defenderId: defenderId,
                    range: range,
                    roll: roll,
                    attackerMove: attackerMove,
                    targetMove: targetMove,
                    woods: woods,
                    partialCover: partialCover,
                    rearHit: rearHit
                )
            )
        )
        return lastError == nil
    }

    @discardableResult
    func applyPendingCrit(unitId: UUID, die1: Int, die2: Int) -> Bool {
        guard let roll = DiceRoll2D6.validated(die1: die1, die2: die2) else {
            lastError = "Invalid crit roll"
            return false
        }
        mutate(.applyCritical(unitId: unitId, roll: roll))
        return lastError == nil
    }

    /// Autosave + dismiss — does not abandon.
    func leaveAndSave() {
        persist()
    }

    func abandon() {
        guard let session else { return }
        let id = session.id
        mutate(.abandonMatch, undoable: false)
        do {
            try repository.delete(id: id)
            self.session = nil
            undoStack.removeAll()
            lastError = nil
        } catch {
            lastError = "Could not discard match: \(error.localizedDescription)"
        }
    }

    /// Leave a completed match without rewriting status to abandoned.
    func dismissCompleted() {
        guard let session, session.status == .completed else { return }
        do {
            try repository.delete(id: session.id)
            self.session = nil
            undoStack.removeAll()
            lastError = nil
        } catch {
            lastError = "Could not clear match: \(error.localizedDescription)"
        }
    }

    private func mutate(_ command: MatchCommand, undoable: Bool = true) {
        guard let session else { return }
        do {
            let next = try MatchReducer.reduce(session, command)
            if undoable {
                pushUndo(session)
            }
            self.session = next
            lastError = nil
            persist()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func pushUndo(_ snapshot: MatchSession) {
        var trimmed = snapshot
        trimmed.recoverySnapshots = []
        undoStack.append(trimmed)
        if undoStack.count > 12 {
            undoStack.removeFirst()
        }
    }

    private func persist() {
        guard var session else { return }
        session.recoverySnapshots = undoStack
        self.session = session
        if session.status == .abandoned {
            do {
                try repository.delete(id: session.id)
            } catch {
                lastError = "Save failed: \(error.localizedDescription)"
            }
            return
        }
        do {
            try repository.save(session)
        } catch {
            lastError = "Save failed: \(error.localizedDescription)"
        }
    }
}
