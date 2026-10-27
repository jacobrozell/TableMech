# App Shell Spec — TableMech

Companion: [IOS26PlatformSpec](IOS26PlatformSpec.md) · [MatchSessionSpec](features/MatchSessionSpec.md).

## Root information architecture

Four tabs (phone + iPad via `.sidebarAdaptable`):

| Tab | SF Symbol | Entry ID | Notes |
|-----|-----------|----------|-------|
| Play | `flag.checkered` | `play.home` | AS home + Classic Coming soon |
| Force | `shield.lefthalf.filled` | `force.roster` | → `force.as.list` |
| Rules | `book` | `rules.home` | AS topics |
| Settings | `gearshape` | `settings.home` | Always |

### Tab behavior (iOS 26)

- `.tabBarMinimizeBehavior(.onScrollDown)` on list tabs  
- No UIKit tab appearance proxies  
- No search tab in 1.0  

## Play routing

```
play.home
  ├─ Resume (if active MatchSession)
  ├─ as.modeHome actions (Getting Started, How to play, Ridge Line, Scenarios)
  ├─ Classic Coming soon → info sheet
  └─ fullScreenCover → as.battle
```

Free Battle hidden in Release (1.1).

## Battle immersion

| Rule | Detail |
|------|--------|
| Presentation | `fullScreenCover` from Play |
| Phase dock | Glass inside cover |
| Dismiss to Play | **Autosave** active session — no discard prompt |
| Abandon / End match | Explicit buttons with confirm |

## Sheet stack rules

| Sheet | Detent | Stacking |
|-------|--------|----------|
| `as.unitFocus` | medium → large | Base tool sheet |
| `as.sator` | **large** | Replaces or stacks on Unit Focus; if stacked, dismiss Focus after Apply or keep — **prefer:** dismiss Focus when opening SATOR from Resolve |
| `as.critRoll` | medium | **On top of** SATOR after Apply; must confirm before dismissing SATOR |
| `as.initiative` | medium | Exclusive |
| `as.moveCoach` | medium | Exclusive / from Focus |
| Classic coming soon | medium | Exclusive |
| Import | large | From Force |

Only one “tool” flow at a time aside from crit-on-sator. Cancel crit returns to SATOR with damage already applied (crit still owed flag on unit until resolved — store `pendingCriticalUnitId` on session if needed).

## Deep links

| URL | Behavior |
|-----|----------|
| `tablemech://play` | Play home |
| `tablemech://as/battle` | Resume battle or AS home |
| `tablemech://force` | Force tab |
| `tablemech://rules/{topicId}` | Rules detail |

Gated → Play home.

## Onboarding vs Getting Started

| Flow | When | Persist |
|------|------|---------|
| First-launch intro | `!preferences.hasSeenIntro` | Skip sets flag |
| Getting Started checklist | Manual from home | ChecklistStore keys |

Intro ≠ checklist. Intro can deep-link to Getting Started.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
