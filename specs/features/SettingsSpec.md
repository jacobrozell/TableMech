# Settings Spec

## Screen: `settings.home`

| Row | Behavior |
|-----|----------|
| Appearance | System / Light / Dark |
| Haptics | On / Off (dice + phase advance) |
| Default rules mode | Alpha Strike / Classic (Classic gated → hidden) |
| Default MechWarrior skill | 2–5 (default 4) |
| Tip / donate | **Hidden** — owner: no tip jar (`nil`) |
| Privacy Policy | `AppLinks.privacy` |
| Support | `AppLinks.support` |
| Accessibility statement | `AppLinks.accessibility` |
| Disclaimer | Unofficial fan aid; trademarks |
| Delete all local data | Confirm → wipe sessions, rosters, checklist |

## AppLinks pattern

```swift
enum AppLinks {
    static let privacy = URL(string: "https://jacobrozell.github.io/TableMech/privacy.html")!
    static let support = URL(string: "https://jacobrozell.github.io/TableMech/support.html")!
    static let accessibility = URL(string: "https://jacobrozell.github.io/TableMech/accessibility.html")!
    static let tipJar: URL? = nil  // locked: no tip jar
}
```

## Accessibility

- `settings.home`, `settings.deleteAll`

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
