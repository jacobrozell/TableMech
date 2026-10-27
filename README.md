# TableMech

BattleTech guided matches for iPhone and iPad (iOS 26). Alpha Strike Ridge Line MVP; Classic Coming soon.

## Build

```bash
xcodegen generate
xcodebuild -scheme TableMechCI -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Open `TableMech.xcodeproj` in Xcode 26+.

## Layout

| Path | Role |
|------|------|
| `App/` | `@main`, tabs, DI |
| `Domain/` | Match math (no SwiftUI) |
| `Data/` + `Persistence/` | Content JSON loaders; SwiftData SchemaV1+ |
| `Features/` | Play / Force / Rules / Settings / Battle |
| `Resources/Content/` | Bundled Alpha Strike JSON |
| `specs/` | Authoritative product specs |

## Docs

Start at [AGENTS.md](AGENTS.md). Owner decisions: [docs/product-readiness.md](docs/product-readiness.md).

Team `7JT2JB89AV` · Bundle `com.jacobrozell.tablemech`
