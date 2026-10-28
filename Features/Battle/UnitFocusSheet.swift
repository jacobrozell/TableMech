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
                    HStack {
                        Text("Card")
                        Spacer(minLength: 8)
                        InfoButton(title: "Card") { _ in
                            VStack(alignment: .leading, spacing: 8) {
                                LabeledContent("Skill", value: "\(unit.skill)")
                                LabeledContent("Move", value: unit.effectiveMV)
                                LabeledContent("Harder to hit", value: "+\(unit.effectiveTMM)")
                                LabeledContent("Damage", value: "S\(unit.effectiveDamage.s) / M\(unit.effectiveDamage.m) / L\(unit.effectiveDamage.l)")
                                if !unit.abilities.isEmpty {
                                    LabeledContent("Abilities", value: unit.abilities)
                                }
                                if unit.crits.weaponHits > 0 {
                                    Text("Weapon hits reduce damage.")
                                }
                                if unit.crits.fireControlHits > 0 {
                                    Text("Each fire control hit adds 2 to its shots.")
                                }
                                if unit.crits.mpHit {
                                    Text("An MP hit halves move and harder to hit.")
                                }
                                Text("0 structure means wrecked.")
                            }
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Section("Armor (outer hits)") {
                    PipTrack(filled: unit.remainingArmor, capacity: unit.armorCap, name: "Armor")
                    Text("\(unit.remainingArmor) of \(unit.armorCap) left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("as.unitFocus.wounds.\(unit.id.uuidString)")

                Section("Structure (inner hits)") {
                    PipTrack(filled: unit.remainingStructure, capacity: unit.structureCap, name: "Structure")
                    Text("\(unit.remainingStructure) of \(unit.structureCap) left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if unit.crits.engineHits > 0 || unit.crits.weaponHits > 0 || unit.crits.fireControlHits > 0 || unit.crits.mpHit {
                    Section("Criticals so far") {
                        if unit.crits.engineHits > 0 {
                            Text("Engine hits: \(unit.crits.engineHits)")
                        }
                        if unit.crits.weaponHits > 0 {
                            Text("Weapon hits: \(unit.crits.weaponHits)")
                        }
                        if unit.crits.fireControlHits > 0 {
                            Text("Fire control: \(unit.crits.fireControlHits)")
                        }
                        if unit.crits.mpHit {
                            Text("MP hit")
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
                        Button {
                            onRollCrit()
                            dismiss()
                        } label: {
                            Text("Roll critical…")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .accessibilityHint("Opens the critical roll")
                    }
                    if session.phase == .combat,
                       !session.units.contains(where: \.pendingCritical),
                       unit.side == session.activeSide,
                       unit.canAttackThisTurn,
                       let onResolveAttack {
                        Button {
                            onResolveAttack()
                            dismiss()
                        } label: {
                            Text("Solve a shot with this ’Mech…")
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .accessibilityIdentifier("as.unitFocus.resolve.\(unit.id.uuidString)")
                        .accessibilityHint("Opens the shot solver")
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
    var name: String?

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
        .accessibilityLabel(spokenCount)
    }

    private var spokenCount: String {
        if let name, !name.isEmpty {
            "\(name), \(filled) of \(capacity)"
        } else {
            "\(filled) of \(capacity)"
        }
    }
}
