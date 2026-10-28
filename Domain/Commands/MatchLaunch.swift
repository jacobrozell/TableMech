import Foundation

/// Whether starting Ridge Line may discard the saved active match.
public enum MatchLaunchDecision: Equatable, Sendable {
    case startFresh
    case replace(UUID)
    case blocked
}

public enum MatchLaunch {
    public static func decide(existingActive: MatchSession?, replaceActive: Bool) -> MatchLaunchDecision {
        guard let existingActive, existingActive.status == .active else {
            return .startFresh
        }
        if replaceActive {
            return .replace(existingActive.id)
        }
        return .blocked
    }
}
