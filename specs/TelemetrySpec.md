# Telemetry Spec (stub)

**Default:** Off in Debug/CI/Release until Phase 14 owner decision.

## Facade

All logging via `AppLog` / `AppLogger` — never call Analytics/Crashlytics from Features.

## When enabled later

| Rule | Detail |
|------|--------|
| Event names | snake_case catalog in this spec |
| Parameters | Allowlisted keys only; no unit names / PII |
| Breadcrumbs | `[category] eventName` only |
| Mapping tests | Required for every Analytics event |

## Placeholder funnel (document only)

`app_open` → `mode_selected` → `mission_started` → `battle_phase_advanced` → `attack_resolved` → `match_completed`

Do not implement sinks until Release decision flips.

## Verification

| Field | Value |
|-------|-------|
| Target release | post-1.0 / Phase 14 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
