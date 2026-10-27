# Battle Table Spec — Alpha Strike

## Hotseat

One-device play. See [HotseatSpec](HotseatSpec.md). Header shows **Playing: {side}**; dock **My Unit** uses `activeSide`.

## Design principle

Organize by **tableside jobs** (phase → unit → attack → apply), not by reference tabs. Presentation: `fullScreenCover` per [AppShellSpec](../AppShellSpec.md) / [IOS26PlatformSpec](../IOS26PlatformSpec.md).

```
Battle table
  → glass phase dock (whose turn / what phase / next)
  → tap unit → Unit Focus sheet
  → Resolve attack → SATOR sheet (apply damage in-sheet)
  → optional Crit sheet
```

## Screen: `as.battle`

### Sticky header (content layer)

- Turn number
- Active phase chips: Initiative | Movement | Combat | End
- Short prompt line (mission coach or generic)

### Body

| Segment | Content |
|---------|---------|
| Status | Initiative winner, units remaining, VP if any |
| Forces | Compact list both sides — tap → Unit Focus |
| Log | Optional match event log (collapsed by default) |

Honor `ScenarioRuleset`: hide OV / physical CTAs when flags false; End-phase heat prompt only if overheat allowed or unit already has heat from Free Battle.

### Phase dock: `as.battle.phaseDock`

Bottom chrome **inside** the battle cover — `GlassEffectContainer` + glass controls (not root `tabViewBottomAccessory`):

| Control | Action |
|---------|--------|
| **Phase** | Jump / next phase |
| **My Unit** | Unit Focus for last selected unit on **`activeSide`** |
| **Attack** | Present SATOR (prefills attacker if selected) |
| **Done / Next side** | Combat: finish current side’s attacks / advance hotseat |

Landscape phone: **unit strip | active tool** when `verticalSizeClass == .compact` **and** phone idiom (Phase 7).

## Sheets

| Sheet ID | When |
|----------|------|
| `as.initiative` | Phase initiative or dock |
| `as.moveCoach` | Movement help / set mode |
| `as.sator` | Combat resolve |
| `as.critRoll` | After Apply when needsCritical |
| `as.unitFocus` | Unit tap |

### Initiative sheet (`as.initiative`)

| Field | Control |
|-------|---------|
| Lance A die1, die2 | Steppers 1…6 |
| Lance B die1, die2 | Steppers 1…6 |
| Confirm | Computes totals; on tie show error and clear |

Winner = higher total; acts **last**. Persist `initiativeRolls` + `initiativeWinner`. Set `activeSide` to loser for Movement.

### Phase Next vs jump

See [MatchSessionSpec](MatchSessionSpec.md) AdvancePhase rules. Dock **Next** = legal advance only; phase chips = jump with confirm if incomplete.

### Unit row badges

| State | Badge text |
|-------|------------|
| destroyedPendingEnd | Fires until End |
| sprint this turn | Sprinted |
| pending crit | Crit owed |

## Domain rules (engine)

`PlayEngineId.alphaStrikePhased`:

1. Initiative — both roll; higher acts last; re-roll ties
2. Movement — loser first; alternating; proportional if uneven counts
3. Combat — loser resolves all, then winner; damage marked immediately; effects at End
4. End — remove destroyed; heat; victory check

Movement modes on unit state: `standstill | ground | sprint | jump` — feed SATOR.

## Exit

Dismiss cover → autosave (see MatchSessionSpec / AppShell). **Abandon** / **End match** are explicit confirms.

## Acceptance criteria (battle)

- Given initiative entered, When Next, Then phase is Movement and Playing shows loser  
- Given structure reduced to 0, Then unit shows “Fires until End” and can still be attacker until End  
- Given End resolves with no living enemies, Then Victory presents  

## Accessibility

- `as.battle.screen`, `as.battle.phaseDock`, `as.battle.phase.{id}`, `as.battle.unit.{id}`
- Announce phase changes via accessibility announcement

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
