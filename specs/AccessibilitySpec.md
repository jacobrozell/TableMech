# Accessibility Spec — TableMech

## Target

WCAG 2.1 AA for Ridge Line happy path. Platform: [IOS26PlatformSpec](IOS26PlatformSpec.md).

## Requirements

| Area | Rule |
|------|------|
| VoiceOver | Labels + hints; TN/phase/side announced |
| Dynamic Type | Through AXXXL on battle + SATOR |
| Contrast | Content tokens; glass uses system adaptation |
| Touch | ≥44×44 pt |
| Motion / transparency | Respect Reduce Motion / Transparency |
| Non-color | Hit/miss, side, phase |

## Identifier convention

`{area}.{screen}.{control}` — use **ScreenCatalog** IDs. Unit ids: `as.battle.unit.{uuid}`.

### Phase 6 minimum ID set (UI / a11y contract tests)

```
play.home
as.modeHome.resume
as.modeHome.ridgeLine
as.modeHome.gettingStarted
as.modeHome.howToPlay
as.howToPlay.screen
play.classicComingSoon
as.mission.setup
as.mission.loadForces
as.mission.tableReady
as.mission.startBattle
as.battle.screen
as.battle.phaseDock
as.battle.phase.initiative
as.battle.phase.movement
as.battle.phase.combat
as.battle.phase.end
as.battle.phaseDock.next
as.battle.phaseDock.myUnit
as.battle.phaseDock.attack
as.battle.phaseDock.doneSide
as.battle.activeSide
as.battle.unit.{id}
as.initiative.sheet
as.initiative.lanceA.die1
as.initiative.lanceA.die2
as.initiative.lanceB.die1
as.initiative.lanceB.die2
as.initiative.confirm
as.sator.sheet
as.sator.attacker
as.sator.target
as.sator.tn
as.sator.die1
as.sator.die2
as.sator.resolve
as.sator.apply
as.crit.sheet
as.crit.die1
as.crit.die2
as.crit.confirm
as.unitFocus.sheet
as.victory.screen
as.victory.done
force.as.list
settings.home
```

## Release gate

No 1.0 with open **critical** a11y failures on Ridge Line path.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
