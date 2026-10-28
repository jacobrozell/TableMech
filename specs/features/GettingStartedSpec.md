# Getting Started Spec — Alpha Strike

## User story

As a new box owner, I complete a one-time checklist and see how to read an Alpha Strike card before my first game.

## Screen: `as.gettingStarted`

Pushed from Play (**New here?**, `as.modeHome.gettingStarted`) and from Settings (**New here checklist**). Scroll view, not a form.

### Sections

1. Progress capsule and a one-line intro
2. **Before you sit down** — checklist (persisted booleans)
3. **Reading a unit card** — sample Shadow Hawk card (`StatStrip`, `HealthReadout`) and a six-line legend (MV, TMM, Armor, Structure, Skill, S/M/L)
4. Bottom call to action — **Play Ridge Line**

### Checklist items

Content source: `Resources/Content/AlphaStrike/as-getting-started.json`.

The view treats `roster` as the bottom call to action (`GettingStartedCatalog.playCueID`). It is not a checklist row. Progress counts the other six items: “N of 6 ready” in the navigation subtitle and the capsule.

| ID | Title | On screen |
|----|-------|-----------|
| `what` | This app is a helper — the game is on the table | Check row. Detail expands |
| `dl_qs` | Optional: download the free Quick-Start PDF | Check row. Link opens in Safari |
| `minis` | Get four miniatures and their cards | Check row |
| `dice` | Get two six-sided dice | Check row |
| `tape` | Get a measuring tape that shows inches | Check row |
| `maps` | Clear a table about 3 feet across | Check row |
| `roster` | Then tap Play Ridge Line | Bottom copy under the button. Not a check |

Checks persist in `AppPreferences.gettingStartedChecks`. Completing all six shows **You’re ready** and a checkmark on the button. The button is always available. It starts Ridge Line (`onPlay`). It does not open Force.

### Non-goals

- Live PDF viewer
- Purchasing / store links beyond the official downloads link on `dl_qs`

## Accessibility

- `as.gettingStarted.screen`
- `as.gettingStarted.check.{id}` for `what`, `dl_qs`, `minis`, `dice`, `tape`, `maps`
- External links announce “Opens in Safari”

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-10-28 |
| Commit | `b9acebb` (tag `0.2.0`) |
| Code paths | `Features/Play/GettingStartedView.swift`, `Features/Play/PlayForceMath.swift` (`playCueID`), `Resources/Content/AlphaStrike/as-getting-started.json`, `App/AppPreferences.swift` |
