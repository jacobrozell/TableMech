# Rules Reference Spec

## User story

As a player, I look up turn sequence, modifiers, and abbreviations without digging through the battle UI.

## Screen: `rules.home`

Mode-filtered topic list. Active mode from app settings / Play.

### Alpha Strike topics (`rules.as.*`)

| Topic ID | Title | Source HTML |
|----------|-------|-------------|
| `turn` | The turn | The turn |
| `movement` | Moving | Move |
| `combat` | Shooting checks | Shoot intro |
| `sator` | SATOR reference | Shoot stack |
| `damage` | Damage, criticals, heat | Damage & heat |
| `physical` | Physical attacks | Damage · physical |
| `tables` | Quick tables | Tables |
| `abbr` | Card abbreviations | Tables · abbr |
| `odds` | 2D6 odds | Tables |

Content: **our words** summaries + structured tables in bundled JSON. Link to official Quick-Start PDF for full rules.

### Classic topics (`rules.classic.*`)

Stub list until ClassicModeSpec content packs land (hit location, heat scale, PSR, etc.).

## Behavior

- Offline only
- Search (optional v1.x) scoped to reachable topics
- “Open in battle” deep links: from `tables` → can present SATOR only if match active

## Accessibility

- `rules.home`, `rules.topic.{id}`

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 (AS topics) |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
