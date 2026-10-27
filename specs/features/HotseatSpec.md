# Hotseat Spec — one-phone play

**Owner (2026-08-21):** One device shared (**hotseat**). No networked multiplayer in v1.

## Model

| Concept | Behavior |
|---------|----------|
| `activeSide` | Side the UI emphasizes for the current micro-step |
| Sides | Lance A / Lance B |
| Chrome | Header **Playing: Lance A\|B** |

### Phase behavior

| Phase | Hotseat |
|-------|---------|
| Initiative | Both enter 2D6 on one sheet (Lance A fields + Lance B fields). Winner acts **last**. Tie → clear and re-enter (`MatchDomainError.initiativeTied`). `activeSide` unused until resolved. |
| Movement | `activeSide = initiativeLoser` first. After that side finishes its **batch** for the current alternating step, flip. See algorithm below. |
| Combat | `activeSide = initiativeLoser` until **Done attacking**; then `initiativeWinner`; then End. |
| End | No side ownership; shared checklist. |

### Dock **My Unit**

Unit Focus for last-selected unit on `activeSide`, else first `combatStatus == .active` unit on that side.

### Prompts

Use side names (“Lance A moves next”), not “you”. Announce `activeSide` changes to VoiceOver.

---

## Movement alternating algorithm

Let `needMove(side)` = active units on side with `hasMovedThisTurn == false`.

1. Start movement: `activeSide = initiativeLoser`.  
2. While any side has units needing move:  
   - Let `a = needMove(activeSide).count`, `b = needMove(otherSide).count`.  
   - If `a == 0`: flip `activeSide` and continue.  
   - Units this impulse = `max(1, floor(a / max(b,1)))` when `a > b`, else `1` (standard AS proportional: side with more remaining moves moves multiple).  
   - Simpler **v1 acceptable approximation** (document in code): alternate **one unit at a time** starting with loser; if one side has no remaining, the other moves all remaining. Prefer full proportional when implementing Domain tests; UI can still be one-unit-at-a-time selection.  
3. User selects a unit on `activeSide`, sets optional `movementMode`, marks moved (`markMoved`).  
4. When both sides `needMove == 0` → enable Advance to Combat.

**Pass:** `skipRemainingMoves` marks all remaining active units `hasMovedThisTurn=true` with `movementMode` left `.unset` (SATOR defaults ground).

**Destroyed mid-movement:** `destroyedPendingEnd` units still need a move marker if they started the phase active; if already destroyed before Movement, they do not move.

---

## Combat hotseat

1. `activeSide = initiativeLoser`.  
2. That side may open SATOR for any `canFire` unit that has not `hasAttackedThisTurn` (sprint cannot).  
3. **Done attacking** → if active was loser, switch to winner; if winner, `AdvancePhase` to End.  
4. Units with `destroyedPendingEnd` remain eligible until End.

---

## Accessibility

- `as.battle.activeSide`  
- `as.battle.playingAs.lanceA` / `.lanceB`  
- Announce on change  

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | `MatchReducer` movement flip + combat `activeSide`; `BattleFlowView` Playing chrome / move filter / SATOR `canAttackThisTurn` |
