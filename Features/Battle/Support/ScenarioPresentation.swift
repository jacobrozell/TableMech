import Foundation

/// Briefing copy for the open mission. Cached on `MatchStore` so the battle screen does not decode JSON in `body`.
struct ScenarioPresentation: Equatable, Sendable {
    var title: String
    var subtitle: String?
    var tableSteps: [String]
    var winningSummary: String?

    static let fallback = ScenarioPresentation(
        title: "Ridge Line",
        subtitle: nil,
        tableSteps: [
            "Clear a table about 3 feet across",
            "Set out the four ’Mechs and their cards",
            "Have two six-sided dice and a tape measure ready"
        ],
        winningSummary: nil
    )
}
