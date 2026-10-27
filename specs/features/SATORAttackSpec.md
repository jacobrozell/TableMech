# SATOR Attack Spec — Alpha Strike

Types: [DomainModelSpec](../DomainModelSpec.md).

## User story

Mid-Combat, pick attacker/target, build TN with SATOR, **enter physical 2D6**, apply damage, roll crit if owed.

### Damage resolver

After attacker, target, and table insights are set, the sheet **previews before dice**:

- Target number and hit odds  
- Damage at this range (S/M/L of the attacker, plus rear if marked)  
- Armor → leftover, Structure → leftover  
- Whether a critical is owed / whether the target is wrecked this turn  

Enter 2D6; the CTA becomes **Apply hit** or **Apply miss**. Natural 12 that hits always previews a critical (through armor).

## Screen: `as.sator` (sheet)

Large detent (`.large` preferred; `.medium` minimum). Presented from battle **Solve a shot**.

### Preconditions (coach, dismissible, not enforced)

1. LOS  2. Firing arc  3. Range base-to-base  4. Not base-to-base (physical instead)

### Pickers

Attacker: `canFire && !hasAttackedThisTurn` (and not sprint). Target: any non-`removed` enemy (including `destroyedPendingEnd` for completeness — usually active).

### SATOR modifiers (numeric)

| Letter | Control | Δ TN |
|--------|---------|------|
| **S** | skill 2…5 | base = skill |
| **A** | standstill | −1 |
| | ground / unset | +0 |
| | jump | +2 |
| | sprint | **illegal** → `cannotAttack` |
| **T** | immobile | −4 |
| | standstill | +0 |
| | groundUsesTMM | +targetTMM |
| | jumpedUsesTMMPlus1 | +targetTMM+1 |
| **O** | woods | +1 |
| | partialCover | +1 |
| | chargeOrDFA | +1 |
| | targetHasSTL | +1 if medium, +2 if long, +0 if short |
| | each fireControlHits | +2 |
| | attackerHeat | +heat (0…4) |
| **R** | short | +0 |
| | medium | +2 |
| | long | +4 |
| | outOfRange | no shot |

### Range from inches

| Inches `d` | Bracket |
|------------|---------|
| `d ≤ 6` | short |
| `6 < d ≤ 24` | medium |
| `24 < d ≤ 42` | long |
| `d > 42` | outOfRange |

### TN & odds

```
tn = S + A + T + O + R
autoMiss = tn > 12
```

2D6 ways totaling ≥ tn (36 faces): use map  
`WAYS_AT_LEAST = [2:36,3:35,4:33,5:30,6:26,7:21,8:15,9:10,10:6,11:3,12:1]`  
`odds% = tn<=2 ? 100 : (tn>12 ? 0 : round(WAYS_AT_LEAST[tn]/36*100))`

Natural 12 is **not** auto-hit. If the entered roll is 12 **and** it hits (12 ≥ tn), critical is owed **even if no structure was marked** (through armor).

### Enter 2D6 (primary)

- Prefer **two steppers** die1 & die2 each 1…6 (validated)  
- Alternate: total stepper 2…12 (less preferred — cannot detect natural 12 as two sixes; if total-only UI used, treat total==12 as natural 12 for crit-through-armor rule)  
- Primary CTA label: **Enter roll** / **Resolve**  
- In-app random roll: hidden under Advanced  

Hit if `total >= tn && !autoMiss`.

### Damage

```
base = damage for active bracket (S/M/L field)
delivered = base + (rearHit ? 1 : 0) + overheatUsed
```

`overheatUsed` only if `ruleset.overheatAllowed` and bracket is short/medium, or long when card has OVL (`ovlAllowsLong`). Ridge Line: always 0 UI.

### Apply damage

1. Subtract from armor until 0, remainder to structure  
2. `needsCritical` if any structure increased **or** (hit && natural12)  
3. If structure full → `combatStatus = .destroyedPendingEnd`  
4. Mark attacker `hasAttackedThisTurn = true`  
5. If `needsCritical` → present `as.critRoll` (must complete or dismiss with “skip” only if user cancels — prefer required confirm)

---

## Critical table (`as.critRoll`)

Enter physical 2D6 (same control pattern). Apply to **target**:

| Roll | Result | Effect |
|------|--------|--------|
| 2 | Ammo hit | Destroyed (`destroyedByCrit`) unless abilities contain `ENE`, `CASE`, or `CASEII` (CASE/CASEII: survive; optional +1 structure dmg later — v1: survive, no extra) |
| 3 | Engine | `engineHits += 1`; if ≥2 → `destroyedByCrit` |
| 4 | Fire control | `fireControlHits += 1` |
| 5 | No critical | — |
| 6 | Weapon | `weaponHits += 1`; reduce s,m,l by 1 (floor 0) |
| 7 | MP | `mpHit = true`; halve printed TMM (floor); MV display note |
| 8 | Weapon | same as 6 |
| 9 | No critical | — |
| 10 | Fire control | same as 4 |
| 11 | Engine | same as 3 |
| 12 | Destroyed | `destroyedByCrit = true` |

---

## Golden test vectors (must pass)

| # | Input summary | Expected TN | Odds% | Notes |
|---|---------------|-------------|-------|-------|
| 1 | skill4, ground, tgt ground TMM2, no other, short | 6 | 72 | 4+0+2+0+0 |
| 2 | skill4, standstill, tgt standstill, short | 3 | 97 | 4−1+0 |
| 3 | skill4, jump, tgt jump TMM2, med | 11 | 8 | 4+2+(2+1)+0+2 |
| 4 | skill4, ground, TMM2, woods+FC1, long | 13 | 0 | 4+0+2+1+2+4 autoMiss |
| 5 | skill5, ground, TMM3, heat2, short | 10 | 17 | 5+0+3+2 |
| 6 | tn computed 13 | autoMiss | 0 | |
| 7 | Damage: armor5/0, struct5/0, dmg3 | armor2 left | needsCrit false | |
| 8 | armor0, struct5/0, dmg2 | struct 2 dmg | needsCrit true | |
| 9 | Hit natural 12, armor only | needsCrit true | through armor | |

More vectors welcome; these are the CI floor.

---

## Accessibility

- `as.sator.sheet`, `.attacker`, `.target`, `.skill`, `.atkMove`, `.tgtMove`, `.other`, `.range`  
- `as.sator.tn`, `.die1`, `.die2`, `.resolve`, `.apply`  
- `as.crit.sheet`, `.die1`, `.die2`, `.confirm`  

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0.0 |
| Last verified | 2026-08-21 |
| Commit | — |
| Code paths | `CombatSolver` + `CombatSolverSheet` |
