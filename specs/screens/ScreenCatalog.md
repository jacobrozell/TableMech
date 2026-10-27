# Screen Catalog — TableMech (mobile)

Master inventory of **every user-visible screen / sheet / dock**. Authoritative for IA. Feature specs own detailed behavior.

**Layout principle:** organize by tableside jobs, not by the nine HTML tabs.

```
Root tabs
├── Play
│   ├── Mode picker (if >1 reachable mode)
│   ├── Mode home
│   ├── Getting Started
│   ├── Scenario catalog
│   ├── Guided mission setup
│   ├── Battle table (+ sheets)
│   └── Match summary / history
├── Force
│   ├── Roster list
│   ├── Unit editor / Unit Focus
│   └── Import (MUL paste)
├── Rules
│   ├── Topic list (mode-filtered)
│   └── Topic detail / tables
└── Settings
    ├── Preferences
    └── Legal / delete data
```

---

## Root chrome

| ID | Screen | Type | Modes | Spec |
|----|--------|------|-------|------|
| `root.tabs` | Root `TabView` (Liquid Glass) | Screen | Both | [AppShellSpec](../AppShellSpec.md), [IOS26PlatformSpec](../IOS26PlatformSpec.md) |
| `play.home` | Play **shell** (resume + routes to mode home) | Screen | Both | [ModeHomeSpec](../features/ModeHomeSpec.md) |
| `force.roster` | Force **shell** → mode-specific list | Screen | Both | [RosterSpec](../features/RosterSpec.md) |
| `rules.home` | Rules browser home | Screen | Both | [RulesReferenceSpec](../features/RulesReferenceSpec.md) |
| `settings.home` | Settings | Screen | Both | [SettingsSpec](../features/SettingsSpec.md) |

---

## Play — shared

| ID | Screen | Type | Primary job | Release |
|----|--------|------|-------------|---------|
| `play.modePicker` | Choose Alpha Strike or Classic | Screen | Pick ruleset | Classic gated |
| `play.resumeBanner` | Resume in-progress match | Banner on home | Continue | MVP |
| `play.matchHistory` | Past matches list | Screen | Review | Planned |
| `play.matchDetail` | Match summary | Screen | Review | Planned |

---

## Play — Alpha Strike

| ID | Screen | Type | Maps from HTML | Spec |
|----|--------|------|----------------|------|
| `as.modeHome` | Alpha Strike home | Screen | (new) | ModeHome |
| `as.gettingStarted` | Pre-game checklist + card literacy | Screen | Set up | GettingStarted |
| `as.howToPlay` | Ridge Line app-flow walkthrough | Screen | (new) | ModeHome |
| `as.scenarios` | First games catalog | Screen | First games | GuidedMission |
| `as.mission.ridgeLine.setup` | Ridge Line setup (forces + table) | Screen | Mission steps 1–2 | GuidedMission |
| `as.mission.fullLances.setup` | Full Lances setup | Screen | First games G2 | GuidedMission (v1.x) |
| `as.battle` | Battle table | Screen | Mission step 3 + turn bar | BattleTable |
| `as.battle.phaseDock` | Phase / Unit / Attack / Score dock | Chrome | Sticky turn bar | BattleTable |
| `as.initiative` | Initiative roller / coach | Sheet | Turn · Initiative | BattleTable |
| `as.moveCoach` | Movement mode coach | Sheet / panel | Move | BattleTable |
| `as.sator` | SATOR attack resolver (+ apply damage on hit) | Sheet | Shoot | SATORAttack |
| `as.critRoll` | Critical table roller (after structure bite / natural 12) | Sheet | Damage crit table | BattleTable / SATORAttack |
| `as.heatCoach` | Heat effects reference | Sheet | Damage · Heat | Rules / UnitFocus |
| `as.physicalCoach` | Physical attack helper | Sheet | Damage · Physical | Planned (Game 2) |
| `as.victory` | Victory / end match | Screen | Mission winning | GuidedMission |
| `as.unitFocus` | Unit Focus sheet | Sheet | Roster unit card | UnitFocus |

---

## Force — Alpha Strike

| ID | Screen | Type | Maps from HTML | Spec |
|----|--------|------|----------------|------|
| `force.as.list` | Lance roster + PV bar | Screen | Roster | Roster |
| `force.as.unitEdit` | Edit stats / flip variant | Screen or push | Roster unit | Roster |
| `force.as.import` | MUL paste import | Sheet | Roster import | Roster |
| `force.as.addUnit` | Add blank / pick template | Sheet | Add a 'Mech | Roster |

---

## Rules — Alpha Strike

| ID | Screen | Type | Maps from HTML | Spec |
|----|--------|------|----------------|------|
| `rules.as.home` | Topic list | Screen | Tables + coaching tabs | RulesReference |
| `rules.as.turn` | Turn sequence | Detail | The turn | RulesReference |
| `rules.as.movement` | Movement modes & terrain | Detail | Move | RulesReference |
| `rules.as.combat` | LOS / arc / range | Detail | Shoot intro | RulesReference |
| `rules.as.satorRef` | SATOR field reference | Detail | Shoot stack labels | RulesReference |
| `rules.as.damage` | Armor / structure / crits / heat | Detail | Damage & heat | RulesReference |
| `rules.as.tables` | Compact modifier tables | Detail | Tables | RulesReference |
| `rules.as.abbreviations` | Card abbreviations | Detail | Tables · abbreviations | RulesReference |

---

## Classic mode (planned / gated)

Screen map only until `PlayCapabilities` for Classic ship. Full behavior: [ClassicModeSpec](../features/ClassicModeSpec.md).

| ID | Screen | Type | Job |
|----|--------|------|-----|
| `classic.modeHome` | Classic home | Screen | Entry |
| `classic.gettingStarted` | Hex / record-sheet orientation | Screen | Onboarding |
| `classic.battle` | Classic battle table | Screen | Phases |
| `classic.phaseDock` | Classic phase dock | Chrome | Init→Heat |
| `classic.recordSheet` | Record sheet (hit locations) | Screen/Sheet | Damage |
| `classic.heatScale` | Heat scale tracker | Sheet | Heat |
| `classic.weaponAttack` | Weapon TN + location | Sheet | Fire |
| `classic.hitLocation` | Hit location table roller | Sheet | Location |
| `classic.critical` | Critical hit (location) | Sheet | Crits |
| `classic.piloting` | Piloting skill roll helper | Sheet | PSR |
| `classic.physical` | Kick / punch / charge / DFA | Sheet | Physical |
| `classic.unitFocus` | Unit Focus (weapons + heat) | Sheet | Unit |
| `force.classic.list` | Classic force list | Screen | Roster |
| `force.classic.sheetEdit` | Edit record sheet | Screen | Setup |
| `rules.classic.*` | Classic rules topics | Detail | Reference |

---

## Settings

| ID | Screen | Type | Spec |
|----|--------|------|------|
| `settings.home` | Appearance, haptics, defaults | Screen | Settings |
| `settings.legal` | Privacy / support / accessibility / disclaimer | Links | Settings |
| `settings.deleteData` | Confirm delete all local data | Alert | Settings |

---

## Shared components (not screens, but named)

| ID | Component | Used by |
|----|-----------|---------|
| `chrome.empty` | Empty state | Lists |
| `chrome.errorBanner` | Recoverable error | All |
| `chrome.diceResult` | 2D6 readout | Initiative, SATOR, Crit |
| `chrome.pipTrack` | Armor/structure pips | Roster, Unit Focus |
| `chrome.phaseChip` | Phase selector | Battle table |

---

## HTML → mobile remapping (summary)

| HTML tab | Mobile destination |
|----------|-------------------|
| Mission | `as.mission.*.setup` + `as.battle` |
| Set up | `as.gettingStarted` |
| The turn | `rules.as.turn` + battle phase dock prompts |
| Move | `rules.as.movement` + `as.moveCoach` |
| Shoot | `as.sator` sheet from battle |
| Damage & heat | SATOR apply + `as.critRoll` / rules topics |
| First games | `as.scenarios` |
| Roster | Force tab |
| Tables | Rules tab |

---

## Accessibility identifiers

Convention: `{area}.{screen}.{control}` — e.g. `as.sator.roll`, `force.as.list.unit.{id}`, `as.battle.phaseDock.next`.

Per-screen VoiceOver scripts live under `accessibility/` once UI exists.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 (AS subset) |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *catalog only* |

**IA note:** `play.home` / `force.roster` are shells; do not implement a second competing “home” without updating AppShellSpec.
