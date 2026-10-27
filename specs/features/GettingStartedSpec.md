# Getting Started Spec — Alpha Strike

## User story

As a new box owner, I complete a one-time checklist and learn how to read AS cards before my first game.

## Screen: `as.gettingStarted`

Maps HTML **Set up** tab.

### Sections

1. **Before your first game** — checklist (persisted booleans)
2. **What’s on the eight cards** — front/back/size table (read-only content)
3. **Reading a unit card** — field glossary (MV, TMM, SZ, S/M/L, OV, A/S, Skill)
4. **Table size** — 3'×4'–4'×4' vs box maps; hex conversion note (1 hex ≈ 2")

### Checklist items (v1)

Content source: `Resources/Content/AlphaStrike/as-getting-started.json`.

| ID | Label | Notes |
|----|-------|-------|
| `dl_qs` | Download Alpha Strike Quick-Start Rulebook | Link out |
| `cards` | Dig out the eight Alpha Strike cards | |
| `dice` | Grab 2D6 per player | Physical primary |
| `tape` | Flexible measuring tape (inches) | |
| `maps` | Lay out maps / play surface | |
| `roster` | Confirm Force roster matches cards | Deep link Force |

Progress: `N / 6` in nav subtitle. Completing all unlocks emphasis on **Play Ridge Line** on mode home (soft — never hard-block).

### Non-goals

- Live PDF viewer
- Purchasing / store links beyond official free downloads

## Accessibility

- `as.gettingStarted.screen`
- `as.gettingStarted.check.{id}`
- External links announce “Opens in Safari”

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
