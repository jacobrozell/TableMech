import SwiftUI

extension EnvironmentValues {
    @Entry var hapticsEnabled: Bool = true
}

enum TMHaptics {
    enum Event: Sendable {
        case dieFaceSelected
        case diceLanded
        case hit
        case miss
        case unitWrecked
        case criticalOwed
        case phaseAdvance
        case victory

        var feedback: SensoryFeedback {
            switch self {
            case .dieFaceSelected:
                .selection
            case .diceLanded, .phaseAdvance:
                .impact(weight: .light)
            case .hit, .victory:
                .success
            case .miss:
                .impact(flexibility: .soft)
            case .unitWrecked:
                .impact(weight: .heavy)
            case .criticalOwed:
                .warning
            }
        }
    }
}

extension View {
    func tmHaptic<T: Equatable>(
        _ event: TMHaptics.Event,
        trigger: T,
        when condition: @escaping (T) -> Bool = { _ in true }
    ) -> some View {
        modifier(TMHapticModifier(event: event, trigger: trigger, condition: condition))
    }
}

private struct TMHapticModifier<T: Equatable>: ViewModifier {
    var event: TMHaptics.Event
    var trigger: T
    var condition: (T) -> Bool
    @Environment(\.hapticsEnabled) private var hapticsEnabled

    func body(content: Content) -> some View {
        content.sensoryFeedback(trigger: trigger) { _, newValue in
            guard hapticsEnabled, condition(newValue) else { return nil }
            return event.feedback
        }
    }
}
