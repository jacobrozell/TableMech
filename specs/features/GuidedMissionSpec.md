# Guided Mission Spec — Alpha Strike

## User story

As a first-night player, I load Ridge Line forces, set the table from a short list, then get phase-by-phase coaching until a winner is decided.

## Scenarios: `as.scenarios`

| Scenario ID | Title | Forces | Est. time | Rules subset | Release |
|-------------|-------|--------|-----------|--------------|---------|
| `ridge-line` | Ridge Line | 2v2 | ~40 min | Move, shoot, damage only | **1.0** |
| `full-lances` | Full Lances | 4v4 | ~90 min | + OV, physical, Forced Withdrawal | 1.x |

### Ridge Line defaults

| Side | Units |
|------|-------|
| Lance A | Shadow Hawk SHD-2H, Commando COM-2D |
| Lance B | Wolverine WVR-6M, Locust LCT-1V |

Skill 4 all. Bundled AS stats (user-editable).

**Victory (locked):** Destroy both enemy ’Mechs. If both sides still have living ’Mechs after turn **6**, higher remaining **structure** wins (tie → draw UI).  

**ScenarioRuleset:** `overheatAllowed`, `physicalAttacksAllowed`, `forcedWithdrawal` = **false**. (Catalog copy must not say “cripple” for Ridge Line — that wording is Full Lances / later.)

### Full Lances (planned)

Forces and VP rules per walkthrough. Awesome vs BattleMaster card conflict → prompt to track one on Force roster.

## Setup screen: `as.mission.ridgeLine.setup`

### Step 1 — Forces

- **Load Ridge Line forces** → writes four units into match roster (and optionally Force tab)
- Editable quick grid (PV, MV, TMM, SZ, S/M/L, OV, A, S, skill)
- Optional: MUL paste import sheet (live network fetch **gated**)

### Step 2 — Table

Read-only checklist:

- Maps grassland side; ~36"×22" or equivalent
- Measure in inches (hexes decorative)
- Woods only terrain (+1" move, +1 to hit in/behind)
- Ignore elevation, water, buildings
- Deploy within 6" of own short edge; initiative loser places first

Mark step complete manually (“Table ready”).

### Step 3 — Play

Primary CTA **Start battle** → `as.battle` with mission coach enabled.

## Acceptance criteria (Ridge Line)

| # | Given / When / Then |
|---|---------------------|
| 1 | Given fresh install, When Load Ridge Line forces, Then four units appear with bundled fixtures + skill 4 |
| 2 | Given forces loaded but table not ready, When Start battle, Then CTA disabled or alert |
| 3 | Given table ready, When Start battle, Then battle cover opens turn 1 initiative |
| 4 | Given both enemies structure 0 and End resolved, When victory check, Then winner is the surviving side |
| 5 | Given turn 6 End and both sides have living ’Mechs, When victory check, Then higher remaining structure wins (equal → draw) |
| 6 | Given active battle, When kill app and relaunch Resume, Then turn/phase/pips/`activeSide` restore |

Rematch → new session id; no Force library write-back.

**DoD:** [phase-6-vertical-slice.md](../../docs/development/phase-6-vertical-slice.md)

## Victory: `as.victory`

- Show winner or draw, turns played, remaining structure totals  
- Actions: **Rematch**, **Done** (history gated off in 1.0)  
- Rematch = new `MatchSession` with fresh Ridge Line armor/structure  

## Mission coach (during battle)

Phase prompts (examples):

| Phase | Prompt intent |
|-------|----------------|
| Initiative | Both roll 2D6; winner acts **last** |
| Movement | Loser moves first; alternate; set movement mode tokens |
| Combat | Loser resolves **all** attacks, then winner; destroyed still shoot until End |
| End | Apply destruction; heat if enabled; check victory |

## Persistence

- `MatchSession` keyed by mode (+ scenario id) — see [MatchSessionSpec](MatchSessionSpec.md)
- Survive app relaunch; resume from Play home
- Battle mutates session **snapshots**, not Force library alone

## Accessibility

- `as.mission.setup`, `as.mission.loadForces`, `as.mission.startBattle`, `as.victory.screen`

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 (Ridge Line) |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
