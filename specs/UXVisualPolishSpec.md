# UX / Visual Polish Spec — TableMech

**Status:** Authoritative for visual and interaction polish.  
**Companion:** [DesignSystemSpec](DesignSystemSpec.md) · [IOS26PlatformSpec](IOS26PlatformSpec.md) · [AccessibilitySpec](AccessibilitySpec.md)

Principle: **tableside glanceability** + **iOS 26 content-first chrome**. Brand lives in content (TN, pips, prompts); navigation stays system Liquid Glass. Do not rebuild the HTML walkthrough as full-screen cockpit chrome.

---

## Tier legend

| Tier | Meaning |
|------|---------|
| **MVP** | Required for 1.0 Ridge Line vertical slice feel |
| **1.x** | Ship when surface ungates or after first TestFlight feedback |
| **Later** | Delight / marketing — not a release blocker |

Every MVP item needs a non-color cue and Dynamic Type path (see AccessibilitySpec).

---

## MVP (1.0)

### SATOR / combat

| ID | Improvement | Notes |
|----|-------------|-------|
| `ux.tnHero` | Large TN numeral + odds bar as hero content | Not glass; content layer |
| `ux.hitMiss` | Hit/miss: text label + semantic color + haptics | VoiceOver announces result |
| `ux.satorRunningTN` | Announce / show running TN after each SATOR letter change | Less-is-more labels |

### Roster / damage

| ID | Improvement | Notes |
|----|-------------|-------|
| `ux.pipTrack` | Arm’s-length pip tracks (armor vs structure) with counts | e.g. “3/5”; ≥44pt grouping |
| `ux.sideIdentity` | Side A/B: badge color **and** text (“Lance A”) | Consistent on list, focus, battle |

### Battle table

| ID | Improvement | Notes |
|----|-------------|-------|
| `ux.phasePrompt` | One-line coach prompt primary; chips secondary | Phase selected state not color-only |
| `ux.phaseDockGlass` | Phase dock in `GlassEffectContainer` | Morph sheets from Attack / My Unit |
| `ux.resumeCard` | Play home resume: scenario · turn · phase | Primary CTA when session active |

### Platform (free with correct APIs)

| ID | Improvement | Notes |
|----|-------------|-------|
| `ux.tabMinimize` | `.tabBarMinimizeBehavior(.onScrollDown)` on root lists | Force / Rules |
| `ux.sidebarAdaptable` | `.tabViewStyle(.sidebarAdaptable)` | iPad |
| `ux.defaultSheets` | System sheet glass; no custom `presentationBackground` | Unless documented exception |
| `ux.brandInContent` | Brand fills inside scroll content for glass sampling | Per IOS26PlatformSpec |

### Motion (MVP, Reduce Motion aware)

| ID | Improvement | Notes |
|----|-------------|-------|
| `ux.motionDice` | Short feedback on 2D6 resolve | Skip flourish if Reduce Motion |
| `ux.motionPhase` | Discrete phase change feedback | No continuous shimmer |
| `ux.motionApply` | Feedback when damage applies to pips | |

### Explicit non-goals (MVP)

- Full-bleed mech-cockpit chrome on every screen  
- Stacked neon panels / multiple competing brand moments per screen  
- Licensed ’Mech art or scanned record sheets  
- Decorative particle / heat-haze effects  

---

## 1.x polish

| ID | Improvement | Notes |
|----|-------------|-------|
| `ux.moveModeTokens` | Standstill / ground / jump / sprint chips on Unit Focus | Mirrors table tokens |
| `ux.heatScale` | Vertical 0–4 heat with shutdown state | Not number-only |
| `ux.critCard` | Large 2D6 + crit name + confirm apply | |
| `ux.pvMeter` | Side A vs B PV bar + gap warning | Force list |
| `ux.emptyStates` | Illustrated empty CTAs (load roster / start Ridge Line) | DesignSystem `EmptyState` |
| `ux.landscapeSplit` | Phone landscape: unit strip \| tool | BattleTableSpec Phase 7 |
| `ux.symbolEffects` | SF Symbol bounce/variable on dice & phase | Gated by Reduce Motion |
| `ux.hapticsSetting` | Settings toggle already in SettingsSpec — wire to all feedback | |

---

## Later (delight / marketing)

| ID | Improvement | Notes |
|----|-------------|-------|
| `ux.weightGlyph` | Abstract weight-class silhouette per unit | Not licensed art |
| `ux.commTapeLog` | Compact match log styling | |
| `ux.rulesShare` | Share / print-friendly Rules tables | |
| `ux.turnWidget` | Home-screen widget: Turn N · phase | Post–App Intents readiness |
| `ux.customDisplayFont` | Optional condensed display for TN only | Must scale with Dynamic Type; exception in DesignSystem Verification |

---

## Per-screen brand budget

One primary brand moment per screen:

| Screen | Primary moment |
|--------|----------------|
| `as.sator` | TN gauge |
| `as.battle` | Phase prompt (+ dock as glass UI) |
| `force.as.list` / Unit Focus | Pip tracks |
| `as.modeHome` | Resume / primary CTA (signal tint on button only) |
| Rules topics | Tables — minimal brand; readable first |

---

## Verification checklist (before claiming polish done)

- [ ] Outdoor / bright ambient: TN and pips readable  
- [ ] Dark Mode + Light Mode: glass samples content without mud  
- [ ] Reduce Transparency + Reduce Motion: no illegible custom glass  
- [ ] AXXXL: TN and dock usable (alternate layout OK)  
- [ ] VoiceOver: hit/miss, phase, pip counts announced  

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 (MVP tier) / 1.x (polish tier) |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
