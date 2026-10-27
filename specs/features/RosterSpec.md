# Roster Spec — Force tab (Alpha Strike)

## User story

As a player, I keep my box’s eight cards (and match forces) on-device: stats, armor/structure pips, heat, crits, side assignment, and PV balance — so Shoot/SATOR never depends on dry-erase alone.

## Screens

| ID | Role |
|----|------|
| `force.roster` | Shell — hosts mode-specific list |
| `force.as.list` | Alpha Strike roster UI |
| `force.as.unitEdit` | Edit stats / flip variant |
| `force.as.import` | MUL paste |
| `force.as.addUnit` | Add blank / template |

Maps HTML **Roster** tab.

## `force.as.list`

### Chrome

- PV balance bar (Side A vs Side B totals; warn if gap large)
- Actions: **Add ’Mech**, **Repair all**, **Reset to box roster**
- **Import** → `force.as.import`

### Unit row → Unit Focus / edit

- Name (editable), Flip variant (front/back)
- Side A/B toggle
- Stat strip: PV, MV, TMM, SZ, S/M/L, OV, Skill
- Armor / structure **pip tracks**
- Heat level 0–4
- Crit flags: ammo, engine×N, fire control×N, weapon×N, MP, destroyed
- Special abilities text (ENE, CASE, STL, …)
- Dead state when structure exhausted (still listable until End Phase removal in match)

### Box roster seed

Eight double-sided cards from the walkthrough. Reset restores names + default stats; Ridge Line load upserts the four mission units from bundled stats.

## Import: `force.as.import`

- MUL QuickList URL pattern + paste JSON → upsert
- **No network in Release by default**; `-enable_mul_fetch` for dogfood

## Heat vs ScenarioRuleset

Roster **may** store heat always. Scenarios with `overheatAllowed == false` must not offer OV push in SATOR or End-phase heat coaching. Free Battle defaults allow heat tools when release surface permits.

## Domain type (library record)

```swift
struct AlphaStrikeUnit: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var variantBack: String?
    var side: ForceSide
    var pv, skill, sz: Int
    var mv: String          // e.g. "10\"j6\""
    var tmm, s, m, l, ov: Int
    var armorCap, structureCap: Int
    var armorDamage, structureDamage: Int
    var heat: Int           // 0...4
    var crits: CritFlags
    var abilities: String
}
```

Match play copies these into `MatchSession.units` — see [MatchSessionSpec](MatchSessionSpec.md).

## Accessibility

- `force.as.list`, `force.as.unit.{id}`, `force.as.pips.armor.{id}`, `force.as.import`

Pip buttons: “Armor bubble 3 of 5, filled/empty”.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
