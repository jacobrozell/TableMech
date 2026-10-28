# Design system

Tokens live in `DesignSystem/Tokens/`. Components live in `DesignSystem/Components/` and take plain values (no `MatchStore`). Colors are asset-catalog tokens in `Resources/Assets.xcassets/Colors/`, read through `TMColor`.

## Icons

SF Symbols only. Monochrome in chrome, hierarchical in content.

| Concept | Symbol |
|---------|--------|
| Roll dice / initiative | `dice` |
| Move | `figure.walk` (walk), `figure.stand` (still), `figure.run` (sprint), `arrow.up.forward` (jump) |
| Shoot | `scope` |
| Clean up | `checklist` |
| Hit | `checkmark.circle.fill` |
| Miss | `xmark.circle.fill` |
| Critical | `exclamationmark.triangle.fill` |
| Wrecked | `flame.fill` |
| Armor | `shield.fill` |
| Structure | `square.stack.3d.up.fill` |
| Range | `ruler` |
| Event log | `list.bullet.rectangle` |
| More menu | `ellipsis` |

Side A is a circle. Side B is a diamond. Signal amber means “do this now,” not a side color.
