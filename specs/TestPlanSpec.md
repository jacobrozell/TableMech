# Test Plan Spec — TableMech

## Pyramid

| Layer | Covers |
|-------|--------|
| Unit | SATOR/crit/damage/phases/hotseat/victory/release surface |
| Integration | MatchSession SwiftData round-trip + resume |
| UI smoke | Phase 6 happy path (after UI exists) |
| A11y contracts | Phase 6 ID set present |

## CI

- PR: `TableMechCI` — unit + a11y identifier contracts  
- Nightly: UI smoke when present  

## Domain vectors (required)

Implement cases in [SATORAttackSpec](features/SATORAttackSpec.md) § Golden test vectors (#1–9) plus:

| Test | Expect |
|------|--------|
| Initiative tie | `MatchDomainError.initiativeTied` |
| Winner acts last | After initiative, movement `activeSide == loser` |
| Destroyed pending | Structure 0 → `destroyedPendingEnd`; still `canFire` |
| End removal | `resolveEndPhase` → `removed`; victory if no enemies `canFire`/`active` |
| Turn-6 structure | After End of turn 6 with both sides alive → higher remaining structure wins |
| Sprint attack | `cannotAttack` |
| SchemaV1 save/load | Session equality on reload |

## Launch arguments

| Arg | Effect |
|-----|--------|
| `-skip_onboarding` | Skip intro |
| `-enable_full_product_surface` | Free Battle, Full Lances, Classic tools, etc. |
| `-enable_mul_fetch` | Network MUL |
| `-reset_state` | Wipe local |
| `-open_as_battle` | Resume/open battle |
| `-load_ridge_line` | Prefill mission ready (tests) |

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | *not implemented* |
