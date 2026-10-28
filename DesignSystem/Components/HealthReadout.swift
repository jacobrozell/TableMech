import SwiftUI

struct HealthReadout: View {
    var armorRemaining: Int
    var armorCapacity: Int
    var structureRemaining: Int
    var structureCapacity: Int
    var size: PipTrack.Size = .regular
    var armorIdentifier: String?
    var structureIdentifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: TMSpace.xs) {
            row(
                icon: "shield.fill",
                title: "Armor",
                track: PipTrack(
                    remaining: armorRemaining,
                    capacity: armorCapacity,
                    kind: .armor,
                    size: size,
                    accessibilityIdentifier: armorIdentifier
                )
            )
            row(
                icon: "square.stack.3d.up.fill",
                title: "Structure",
                track: PipTrack(
                    remaining: structureRemaining,
                    capacity: structureCapacity,
                    kind: .structure,
                    size: size,
                    accessibilityIdentifier: structureIdentifier
                )
            )
        }
    }

    private func row(icon: String, title: String, track: PipTrack) -> some View {
        HStack(alignment: .center, spacing: TMSpace.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
                .frame(width: 16)
            track
        }
    }
}

#if DEBUG
#Preview("Health") {
    PreviewPair {
        HealthReadout(
            armorRemaining: 3,
            armorCapacity: 5,
            structureRemaining: 5,
            structureCapacity: 5,
            size: .regular
        )
    }
}
#endif
