# Phase 6 — Ridge Line vertical slice (definition of done)

**In scope for “first playable”:** Alpha Strike Ridge Line on one device (hotseat), iPhone primary, iPad must launch and complete the same path (layout may be stacked).

## Happy path (acceptance)

Given a fresh install:

1. Launch → Play (AS home); Classic shows Coming soon only  
2. Getting Started optional (skippable)  
3. Play Ridge Line → Load forces (four units, bundled stats, skill 4)  
4. Mark Table ready  
5. Start battle → fullScreenCover battle  
6. Initiative: enter both sides’ 2D6; higher acts last; ties re-enter  
7. Movement: loser moves first; set modes optionally; advance when both sides done  
8. Combat: loser attacks (SATOR enter dice → apply); then winner; destroyed-pending still listed as can fire  
9. End: remove destroyed; victory check  
10. Kill app mid-battle → relaunch → Resume restores turn/phase/pips/`activeSide`  
11. Reach victory (destroy both or turn-6 structure) → Victory screen → Done  

## Explicitly out of Phase 6

- Free Battle, Full Lances playable, Classic tools  
- MUL network fetch, match history, tip jar  
- Physical attacks / OV / Forced Withdrawal UI  
- Write-back to Force library on victory  
- Landscape split polish (Phase 7 OK after slice green)

## Must have Domain tests (green in CI)

- SATOR TN + odds vectors in [TestPlanSpec](../../specs/TestPlanSpec.md)  
- Apply damage armor→structure + needsCritical  
- Crit table 2–12 mutations (ENE/CASE ammo immunity)  
- Phase advance End → next turn Initiative  
- Victory: both destroyed; turn-6 structure tiebreak; draw  
- Hotseat: initiative winner acts last; combat loser-all-then-winner  

## Must have UI identifiers (minimum)

See [AccessibilitySpec](../../specs/AccessibilitySpec.md) § Phase 6 ID set.

## Persistence

- `SchemaV1` MatchSession round-trip  
- One active AS session; starting new Ridge Line confirms abandon  

## Release surface during slice

Use Release defaults (Free Battle off). Dogfood may use `-enable_full_product_surface` but Phase 6 sign-off is **without** that arg.

## Sign-off

| Check | Owner |
|-------|-------|
| Unit tests above green | Agent |
| Manual Ridge Line once on iPhone sim | Agent |
| Spec Verification blocks dated | Agent |
| Inventory: vertical slice → partial/shipped docs | Agent |
