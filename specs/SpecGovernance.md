# Spec Governance

## Source-of-truth hierarchy

1. **ArchitectureSpec** + **IOS26PlatformSpec** (platform/structure)
2. System specs (Tech, Design, Data, A11y, Localization, Test, ReleaseSurface, ContentPack)
3. Feature / screen specs
4. `docs/feature-inventory.md` (what the build exposes)
5. `docs/brainstorm.md` / `FutureIdeas/` (non-authoritative)

On conflict, higher wins. Update the higher doc in the same PR as behavior changes.

## PR rules

| Change | Required docs |
|--------|----------------|
| User-visible behavior | Feature or screen spec + Verification touch |
| New screen ID | ScreenCatalog row |
| New mode / scenario | ContentPackSpec + PRODUCT_SCOPE + inventory |
| New analytics event | TelemetrySpec allowlist |
| Lean ship gate | ReleaseSurfaceSpec + inventory |
| Platform/nav pattern | IOS26PlatformSpec and/or AppShellSpec |

## Verification block format

Every feature/system spec ends with:

| Field | Value |
|-------|-------|
| Target release | |
| Last verified | |
| Commit | |
| Code paths | |

Use `*not implemented*` until code exists.

## Promotion

`FutureIdeas/` or brainstorm → locked spec → implement → inventory `shipped`/`gated`.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *governance only* |
