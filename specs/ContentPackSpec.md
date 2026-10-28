# Content Pack Spec — Scaling modes & rules

Long-term rule: **adding a mode or scenario is data + one engine registration**, not 25 feature `switch` arms.

## Concepts (do not conflate)

| Concept | Example | Owns |
|---------|---------|------|
| `GameModeId` | `alpha-strike`, `classic-tw` | Namespace for content + sessions |
| `PlayEngineId` | `alphaStrikePhased`, `classicTWPhased` | Turn/phase behavior family |
| `PlayCapabilities` | booleans / optionals | What UI may show |
| `ContentPack` | `as-quickstart-v1` | Bundled JSON version |
| `ScenarioId` | `ridge-line` | Guided mission definition |
| `ScenarioRuleset` | flags | Which optional rules are on |

## Manifest (`game-modes-manifest.json`)

```json
{
  "modes": [
    {
      "id": "alpha-strike",
      "displayName": "Alpha Strike",
      "playEngine": "alphaStrikePhased",
      "availability": "shipped",
      "catalogBundle": "as-quickstart-v1",
      "capabilities": {
        "showsGuidedMission": true,
        "showsSATOR": true,
        "showsArmorStructurePips": true,
        "showsHitLocations": false,
        "showsHeatScale": true,
        "showsPVBalance": true,
        "showsPhysicalAttacks": true,
        "allowsMULPasteImport": true
      }
    }
  ]
}
```

`availability`: `shipped` | `gated` | `stub`. Release surface may further hide `shipped` items for lean cuts.

## PlayEngine protocol (Domain)

```swift
public protocol PlayEngine: Sendable {
    var id: PlayEngineId { get }
    var phaseOrder: [PhaseId] { get }
    func advance(from phase: PhaseId) -> PhaseId?
    func prompt(for context: PhaseContext) -> PhasePrompt
}

public protocol CombatResolver: Sendable {
    // Mode-specific; AS implements SATOR path, Classic implements weapon+location
}
```

Features ask the registry for `any PlayEngine` / capabilities. **Never** `if modeId == "alpha-strike"` in Views.

## ScenarioRuleset

```swift
public struct ScenarioRuleset: Sendable, Equatable, Codable {
    public var overheatAllowed: Bool
    public var physicalAttacksAllowed: Bool
    public var forcedWithdrawal: Bool
    public var maxTurns: Int?          // e.g. 6 for Ridge Line tiebreak
    public var victory: VictoryRule
}
```

Ridge Line: OV/physical/withdrawal = `false`. Free Battle defaults: all `true` (subject to release surface).

## Add a new mode checklist

1. Add engine implementation under `Domain/Engines/<Name>/` + unit tests  
2. Add manifest entry + content pack JSON  
3. Add capabilities; extend `PlayCapabilities` only if a **new UI family** appears  
4. Add screen IDs to ScreenCatalog + feature specs  
5. Gate in ReleaseSurface until QA matrix passes  
6. Update PRODUCT_SCOPE + feature inventory  

**Forbidden:** copying an entire Features folder and swapping strings.

## Content versioning

- Packs carry `schemaVersion` + `contentVersion`
- App refuses unknown schema (fail soft → empty state + telemetry)
- User data references `GameModeId` + pack version at write time for migrations

## Rules topics

`RulesTopicDTO` (`Data/Content/ContentDTOs.swift`) and `as-rules-topics.json` include two optional fields:

| Field | When present | When omitted |
|-------|----------------|--------------|
| `summary` | One-line row subtitle on Rules | First sentence of the first section (`RulesGroup.summary`) |
| `group` | `start`, `during`, or `reference` | `RulesGroup.resolve` maps by topic id |

Sections stay `{ heading, body }`. The pack has no structured table block.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-10-28 |
| Commit | `b9acebb` (tag `0.2.0`) |
| Code paths | `Data/Content/ContentDTOs.swift` (`RulesTopicDTO.summary`, `RulesTopicDTO.group`), `Resources/Content/AlphaStrike/as-rules-topics.json`, `Features/Play/RulesHomeView.swift` (`RulesGroup`) |
