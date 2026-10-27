import SwiftUI
import TableMechDomain

struct UnitFocusSheet: View {
    let unit: MatchUnitState
    let session: MatchSession
    var onResolveAttack: (() -> Void)?
    var onRollCrit: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Side", value: unit.side.displayName)
                    LabeledContent("Status", value: unit.combatStatus.displayName)
                    LabeledContent("Skill", value: "\(unit.skill)")
                    LabeledContent("Move", value: unit.effectiveMV)
                    LabeledContent("Harder to hit", value: "+\(unit.effectiveTMM)")
                    LabeledContent("Damage", value: "S\(unit.effectiveDamage.s) / M\(unit.effectiveDamage.m) / L\(unit.effectiveDamage.l)")
                    if !unit.abilities.isEmpty {
                        LabeledContent("Abilities", value: unit.abilities)
                    }
                }

                Section("Armor (outer hits)") {
                    PipTrack(filled: unit.remainingArmor, capacity: unit.armorCap)
                    Text("\(unit.remainingArmor) of \(unit.armorCap) left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("as.unitFocus.wounds.\(unit.id.uuidString)")

                Section("Structure (inner hits)") {
                    PipTrack(filled: unit.remainingStructure, capacity: unit.structureCap)
                    Text("\(unit.remainingStructure) of \(unit.structureCap) left — 0 means wrecked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if unit.crits.engineHits > 0 || unit.crits.weaponHits > 0 || unit.crits.fireControlHits > 0 || unit.crits.mpHit {
                    Section("Criticals so far") {
                        if unit.crits.engineHits > 0 {
                            Text("Engine hits: \(unit.crits.engineHits)")
                        }
                        if unit.crits.weaponHits > 0 {
                            Text("Weapon hits: \(unit.crits.weaponHits) (damage reduced)")
                        }
                        if unit.crits.fireControlHits > 0 {
                            Text("Fire control: \(unit.crits.fireControlHits) (+2 to its shots each)")
                        }
                        if unit.crits.mpHit {
                            Text("MP hit — move and harder-to-hit halved")
                        }
                    }
                }

                Section("This turn") {
                    LabeledContent("Moved", value: unit.hasMovedThisTurn ? unit.movementMode.displayName : "Not yet")
                    if let shot = unit.turnShot {
                        LabeledContent("Shot", value: shot.rowTitle)
                        Text(shot.rowDetail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        LabeledContent("Shot", value: unit.hasAttackedThisTurn ? "Already shot" : "Not yet")
                    }
                }

                Section {
                    if unit.pendingCritical, let onRollCrit {
                        Button("Roll critical…") {
                            onRollCrit()
                            dismiss()
                        }
                        .font(.headline)
                    }
                    if session.phase == .combat,
                       !session.units.contains(where: \.pendingCritical),
                       unit.side == session.activeSide,
                       unit.canAttackThisTurn,
                       let onResolveAttack {
                        Button("Solve a shot with this 'Mech…") {
                            onResolveAttack()
                            dismiss()
                        }
                        .accessibilityIdentifier("as.unitFocus.resolve.\(unit.id.uuidString)")
                    }
                }
            }
            .navigationTitle(unit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("as.unitFocus.sheet")
    }
}

struct PipTrack: View {
    let filled: Int
    let capacity: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(capacity, 0), id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(index < filled ? Color.primary : Color.secondary.opacity(0.25))
                    .frame(width: 14, height: 18)
            }
            if capacity == 0 {
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(filled) of \(capacity)")
    }
}
