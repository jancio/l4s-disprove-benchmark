# Genuine `/lean4:disprove` runs — artifact log

Environment: Lean 4 `v4.29.1`, mathlib (built); Z3 `4.15.4`; gate = `lake env lean`.
Protocol: scripted rank-1 operator (take the top-ranked method/config per Target Profile).
All witnesses, certified terms, and `#print axioms` reports below are real outputs.

## medium_bad : ∀ n:ℕ, n²≤10n  — enumerate
- Profile: shape 1, binder ℕ (unbounded), decidable = no.
- rank-1 = enumerate; scan finds first witness **n = 11** (121 > 110).
- Certify: `⟨11, by norm_num⟩` (MediumBad.lean `T_counterexample`); `lake env lean`: OK.
- `#print axioms` → `[propext, Classical.choice, Quot.sound]`.  Outcome: **REFUTED** (cycle 1).

## hard_bad : ∀ n:ℕ, n²≤1000n  — enumerate + multi-cycle widening
- Profile: decidable = no; rank-1 = enumerate.
- Cycle 1: window `[5,64)` (registry default `range_start=5, range_end=64`) → **exhausted, no witness**.
  Accumulate records the exhausted range.
- Cycle 2: widen to non-overlapping `[64,1024)` → first witness **n = 1001** (1001² = 1002001 > 1001000).
- Certify: `⟨1001, by norm_num⟩`; `lake env lean`: OK.
- `#print axioms` → `[propext, Classical.choice, Quot.sound]`.  Outcome: **REFUTED** (cycle 2, evidence-driven widening).

## smt_bad : ∀ x y:ℤ, 2x²−3y²≠5  — external (Z3)
- Profile: decidable = no (ℤ infinite); decide/omega/1-D enumerate inapplicable.
- rank-1 = external, language = smt-z3; emitted query `2x²−3y² = 5`.
- **Z3 4.15.4 (untrusted): sat, model (x,y) = (−4, 3)** (verbatim Z3 output).
- Lift + kernel re-check: `⟨-4, 3, by norm_num⟩` (SmtBad.lean `T_counterexample`); `lake env lean`: OK.
- `#print axioms` → `[propext, Quot.sound]`.  Outcome: **REFUTED** (untrusted solver, kernel-certified).

## Axiom ground truth — representative refutations (across methods and axiom profiles)
| theorem | axioms |
|---|---|
| easy_bad (Fin, decide) | none |
| fin12_div (Fin, decide) | propext |
| medium_bad (ℕ, norm_num) | propext, Classical.choice, Quot.sound |
| euler (ℕ, norm_num) | propext |
| prime91 (Nat.Prime, decide) | propext, Classical.choice, Quot.sound |
| smt_bad (ℤ, norm_num) | propext, Quot.sound |

All ⊆ {propext, Classical.choice, Quot.sound}; none use `Lean.ofReduceBool` (native_decide left off).
