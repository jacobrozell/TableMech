import Foundation

public enum VictoryRule: Codable, Sendable, Equatable {
    case destroyAllEnemies
    case destroyAllEnemiesOrStructureAfterTurn(maxTurn: Int)

    private enum CodingKeys: String, CodingKey {
        case type, maxTurn
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "destroyAllEnemies":
            self = .destroyAllEnemies
        case "destroyAllEnemiesOrStructureAfterTurn":
            let maxTurn = try container.decode(Int.self, forKey: .maxTurn)
            self = .destroyAllEnemiesOrStructureAfterTurn(maxTurn: maxTurn)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown victory type \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .destroyAllEnemies:
            try container.encode("destroyAllEnemies", forKey: .type)
        case .destroyAllEnemiesOrStructureAfterTurn(let maxTurn):
            try container.encode("destroyAllEnemiesOrStructureAfterTurn", forKey: .type)
            try container.encode(maxTurn, forKey: .maxTurn)
        }
    }
}

public struct ScenarioRuleset: Codable, Sendable, Equatable {
    public var overheatAllowed: Bool
    public var physicalAttacksAllowed: Bool
    public var forcedWithdrawal: Bool
    public var maxTurns: Int?
    public var victory: VictoryRule

    public init(
        overheatAllowed: Bool,
        physicalAttacksAllowed: Bool,
        forcedWithdrawal: Bool,
        maxTurns: Int?,
        victory: VictoryRule
    ) {
        self.overheatAllowed = overheatAllowed
        self.physicalAttacksAllowed = physicalAttacksAllowed
        self.forcedWithdrawal = forcedWithdrawal
        self.maxTurns = maxTurns
        self.victory = victory
    }

    public static let ridgeLine = ScenarioRuleset(
        overheatAllowed: false,
        physicalAttacksAllowed: false,
        forcedWithdrawal: false,
        maxTurns: 6,
        victory: .destroyAllEnemiesOrStructureAfterTurn(maxTurn: 6)
    )
}
