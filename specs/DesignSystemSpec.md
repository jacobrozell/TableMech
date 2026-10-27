# Design System Spec — TableMech

Companion: [IOS26PlatformSpec](IOS26PlatformSpec.md) · [UXVisualPolishSpec](UXVisualPolishSpec.md).

## Two-layer visual model

| Layer | Materials | Brand |
|-------|-----------|-------|
| UI (tabs, toolbars, sheets, menus) | System Liquid Glass | Monochrome symbols; tint sparingly for meaning |
| Content (lists, cards, TN, pips) | Opaque / semantic surfaces that glass can sample | Signal amber, coolant teal, damage/structure reds |

Do **not** rebuild the Alpha Strike HTML’s full-screen “hull chrome” as the app chrome. The walkthrough aesthetic informs **content** readouts (TN gauge, pip tracks, phase labels), not a custom tab bar.

## Token layers

1. **Brand (content)** — `signal`, `coolant`, `damage`, `structure`
2. **Semantic** — `textPrimary`, `textSecondary`, `danger`, `success`, `warning`, `surface`, `surfaceGrouped`
3. **Game** — `armorPip`, `structurePip`, `heatLevel`, `phaseActive`, `sideA`, `sideB`

Non-color cues required for hit/miss, side, phase, heat.

## Typography

Prefer **system fonts** for body/UI (Dynamic Type + iOS 26 familiarity). Brand moments:

- TN / turn numerals: system rounded or condensed **in content**
- Stats: `Font.system(.body, design: .monospaced)` or SF Mono

Custom display fonts only if they still scale with Dynamic Type; document exception in Verification when added.

## Components (content layer)

| Component | Notes |
|-----------|-------|
| `PipTrack` | Armor/structure; large-text layout variant |
| `DiceReadout` | 2D6 |
| `TNGauge` | Large TN + odds (hero content, not glass) |
| `PhasePromptBanner` | Text-first coach line |
| `EmptyState` | Title + CTA |
| `ForceUnitCard` | Roster row content |

## Components (UI layer)

| Component | Notes |
|-----------|-------|
| Phase dock | `GlassEffectContainer` + glass controls; interactive only on tappable controls |
| Toolbars | System; monochrome |

Apply `glassEffect` **after** layout modifiers. Match container spacing to layout spacing.

## Touch targets

Minimum 44×44 pt. Primary Roll / Apply larger.

## Motion

Respect Reduce Motion: skip morph flourishes; keep discrete state updates.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
