import Foundation

/// Identifies the step Back returns from. Active side is part of the step so
/// handing the phone back is one step, and shooting sides are separate steps.
public struct MatchStepKey: Equatable, Sendable {
    public var tableReady: Bool
    public var turn: Int
    public var phase: PhaseId
    public var activeSide: SideId
    public var status: MatchStatus

    public init(_ session: MatchSession) {
        tableReady = session.tableReady
        turn = session.turn
        phase = session.phase
        activeSide = session.activeSide
        status = session.status
    }
}

public enum MatchRecovery {
    /// Newest saved session from a different step, if Back has somewhere to go.
    public static func previousStep(current: MatchSession, undoStack: [MatchSession]) -> MatchSession? {
        let key = MatchStepKey(current)
        return undoStack.last { MatchStepKey($0) != key }
    }

    /// Movement hand-off that keeps recorded moves. Returns nil when Back should
    /// restore a snapshot instead (shots, a new turn, or setup).
    public static func handBack(current: MatchSession, undoStack: [MatchSession]) -> MatchSession? {
        guard current.phase == .movement, current.status == .active else { return nil }
        guard let top = undoStack.last else { return nil }
        guard top.phase == .movement, top.turn == current.turn, top.tableReady == current.tableReady else {
            return nil
        }
        guard top.activeSide != current.activeSide else { return nil }
        guard !discardsDamage(current: current, restoring: top) else { return nil }
        var next = current
        next.activeSide = top.activeSide
        return next
    }

    public static func discardsResults(current: MatchSession, restoring: MatchSession) -> Bool {
        if current.turn != restoring.turn || current.status != restoring.status {
            return true
        }
        if discardsDamage(current: current, restoring: restoring) {
            return true
        }
        let currentByID = Dictionary(uniqueKeysWithValues: current.units.map { ($0.id, $0) })
        for unit in restoring.units {
            guard let now = currentByID[unit.id] else { return true }
            if now.hasMovedThisTurn != unit.hasMovedThisTurn || now.movementMode != unit.movementMode {
                return true
            }
            if now.hasAttackedThisTurn != unit.hasAttackedThisTurn {
                return true
            }
        }
        return false
    }

    private static func discardsDamage(current: MatchSession, restoring: MatchSession) -> Bool {
        let currentByID = Dictionary(uniqueKeysWithValues: current.units.map { ($0.id, $0) })
        for unit in restoring.units {
            guard let now = currentByID[unit.id] else { return true }
            if now.armorDamage != unit.armorDamage
                || now.structureDamage != unit.structureDamage
                || now.heat != unit.heat
                || now.crits != unit.crits
                || now.pendingCritical != unit.pendingCritical
                || now.combatStatus != unit.combatStatus {
                return true
            }
        }
        return current.units.count != restoring.units.count
    }
}
