import Mathlib

/-!
# Disprove benchmark — the 16 evaluation targets for `/lean4:disprove`

Authoritative catalog of the paper's evaluation benchmark (*Lean Disprove: Certified
Counterexample Search for AI-Assisted Formal Mathematics*, §5): **16 hand-built targets
= 15 false + 1 true control**, spanning the shape taxonomy (Table 1) and a difficulty
gradient that exercises successively more of the tool's machinery.

Each false target carries the *certified refutation* the tool's rank-1 method cascade
emits (a Lean term of the shape-appropriate negation). The lone TRUE control carries no
refutation: the tool must report no counterexample (no false positive).

Difficulty regimes (paper §5):
  * decidable-finite (10) — bare `decide` certifies the negation directly.
  * bounded-ℕ        (3)  — a finite `enumerate` scan finds the witness (n = 11, 40, 5).
  * out-of-window    (1)  — witness beyond the default scan, reached by multi-cycle
                            widening (n = 1001; confirmed here with the explicit witness).
  * nonlinear-ℤ      (1)  — `decide`/`omega`/1-D `enumerate` miss it; an `external` SMT
                            search supplies the model (x,y) = (-4,3), kernel-rechecked.
  * true control     (1)  — `∀ n : Fin 5, n.val < 5` (TRUE; must NOT be refuted).

Shapes follow the paper's normalization table (Table 1):
  1: ∀ x, P x        2: ∀ x, P x → Q x      3: ∃ x, P x
  6: a = b / a ≤ b   7: decidable atom P

Baseline note per target: [decide] = bare decide/native_decide certifies it with
no search; [search] = needs a witness (infinite domain) that bare decide cannot find;
[external] = needs an untrusted external (SMT) search whose model the kernel re-checks.

The two showcase runs (out-of-window widening and nonlinear external SMT) are driven
end-to-end on their own source files — `HardBad.lean` and `SmtBad.lean`, the exact
sources of the paper's Listings 2–3; `EasyBad.lean` is the source of Listing 1. See
`RUNS.md` for the genuine run transcripts and `#print axioms` reports.
-/

namespace L4sDisproveBenchmark.Benchmark

-- ============================================================
-- Shape 1: ∀ x, P x   (disprove goal: ∃ x, ¬ P x)
-- ============================================================

/-- easy_bad: `∀ n : Fin 5, n.val < 3`. False at n = 3. [decide] -/
theorem easy_bad_refutation : ¬ (∀ n : Fin 5, n.val < 3) := by decide

/-- fin10_ne7: `∀ n : Fin 10, n.val ≠ 7`. False at n = 7. [decide] -/
theorem fin10_ne7_refutation : ¬ (∀ n : Fin 10, n.val ≠ 7) := by decide

/-- fin8_even: `∀ n : Fin 8, n.val % 2 = 0`. False at n = 1. [decide] -/
theorem fin8_even_refutation : ¬ (∀ n : Fin 8, n.val % 2 = 0) := by decide

/-- medium_bad: `∀ n : ℕ, n^2 ≤ n*10`. False at n = 11 (121 > 110). [search] -/
theorem medium_bad_refutation : ¬ (∀ n : ℕ, n ^ 2 ≤ n * 10) := by
  intro h; have := h 11; norm_num at this

/-- euler: `∀ n : ℕ, Nat.Prime (n^2+n+41)`. Prime for n ≤ 39, false at
    n = 40 (40²+40+41 = 1681 = 41²). The classic "validated then false". [search] -/
theorem euler_refutation : ¬ (∀ n : ℕ, Nat.Prime (n ^ 2 + n + 41)) := by
  intro h; have := h 40; norm_num at this

/-- hard_bad: `∀ n : ℕ, n^2 ≤ n*1000` is false only at n ≥ 1001, OUTSIDE the default
    search window (range_end = 64), so cycle 1 is INCONCLUSIVE; the tool refutes it
    only after evidence-driven widening reaches the witness n = 1001. -/
theorem hard_bad_is_false : ¬ (∀ n : ℕ, n ^ 2 ≤ n * 1000) := by
  intro h; have := h 1001; norm_num at this

/-- fin5_lt5: `∀ n : Fin 5, n.val < 5`. TRUE — no counterexample exists; the
    tool must return no-witness (INCONCLUSIVE), i.e. no false positive. -/
theorem fin5_lt5_true : ∀ n : Fin 5, n.val < 5 := by decide

-- ============================================================
-- Shape 2: ∀ x, P x → Q x   (disprove goal: ∃ x, P x ∧ ¬ Q x)
-- ============================================================

/-- fin12_div: `∀ n : Fin 12, 2 ∣ n.val → 3 ∣ n.val`. False at n = 2. [decide] -/
theorem fin12_div_refutation :
    ¬ (∀ n : Fin 12, 2 ∣ n.val → 3 ∣ n.val) := by decide

/-- natle5_sq: `∀ n : ℕ, n ≤ 5 → n^2 ≤ 20`. False at n = 5 (25 > 20). [search] -/
theorem natle5_sq_refutation : ¬ (∀ n : ℕ, n ≤ 5 → n ^ 2 ≤ 20) := by
  intro h; have := h 5 (by norm_num); norm_num at this

-- ============================================================
-- Shape 3: ∃ x, P x   (disprove goal: ∀ x, ¬ P x)
-- ============================================================

/-- fin5_gt10: `∃ n : Fin 5, n.val > 10`. False (no such element). [decide] -/
theorem fin5_gt10_refutation : ¬ (∃ n : Fin 5, n.val > 10) := by decide

/-- fin6_succ: `∃ n : Fin 6, n.val = n.val + 1`. False. [decide] -/
theorem fin6_succ_refutation : ¬ (∃ n : Fin 6, n.val = n.val + 1) := by decide

-- ============================================================
-- Shape 6: a = b / a ≤ b   (disprove goal: a ≠ b / ¬ a ≤ b)
-- ============================================================

/-- pow2: `(2:ℕ)^10 = 1000`. False (1024 ≠ 1000). [decide] -/
theorem pow2_refutation : (2 : ℕ) ^ 10 ≠ 1000 := by decide

/-- fact5: `Nat.factorial 5 ≤ 100`. False (120 > 100). [decide] -/
theorem fact5_refutation : ¬ (Nat.factorial 5 ≤ 100) := by decide

/-- div7: `7 ∣ 100`. False. [decide] -/
theorem div7_refutation : ¬ (7 ∣ 100) := by decide

-- ============================================================
-- Shape 7: decidable atom P   (disprove goal: ¬ P)
-- ============================================================

/-- prime91: `Nat.Prime 91`. False (91 = 7·13). [decide] -/
theorem prime91_refutation : ¬ Nat.Prime 91 := by decide

-- ============================================================
-- Nonlinear-ℤ (regime iv): external SMT.
-- Goal `∀ x y : ℤ, 2x²−3y² ≠ 5`; `decide` (ℤ infinite), `omega` (nonlinear), and
-- 1-D `enumerate` (two free variables) all miss it. Z3 (untrusted) returns the model
-- (x,y) = (−4,3), re-checked by the kernel. The end-to-end run lives in `SmtBad.lean`
-- (paper Listing 3 / §6); this catalog entry records the same target's refutation.
-- ============================================================

/-- smt_bad: `∀ x y : ℤ, 2x²−3y² ≠ 5`. False at (x,y) = (−4,3) (32 − 27 = 5). [external] -/
theorem smt_bad_refutation : ¬ (∀ x y : ℤ, 2 * x ^ 2 - 3 * y ^ 2 ≠ 5) := by
  intro h; have := h (-4) 3; norm_num at this

-- ============================================================
-- Illustrative recipe form — NOT one of the 16 targets.
-- The ∃-witness form referenced by the paper's Listing 1 caption: the search methods
-- build `∃ x, ¬ P x := ⟨witness, by atom⟩` rather than the `¬ ∀` form `decide` returns.
-- Kept here only as a runnable illustration of that recipe.
-- ============================================================

/-- The Shape-1 recipe form used in the case-study listing: existential witness
    n = 40 with the residual discharged by `norm_num`. -/
theorem euler_refutation' : ∃ n : ℕ, ¬ Nat.Prime (n ^ 2 + n + 41) :=
  ⟨40, by norm_num⟩

-- Axiom hygiene: no certified term may pull in `Lean.ofReduceBool` (it appears only under
-- `native_decide`, which we do not use) or `sorryAx`. Every report below is
-- ⊆ {propext, Classical.choice, Quot.sound}; the CI workflow greps these and fails on either.
#print axioms easy_bad_refutation
#print axioms fin10_ne7_refutation
#print axioms fin8_even_refutation
#print axioms medium_bad_refutation
#print axioms euler_refutation
#print axioms hard_bad_is_false
#print axioms fin5_lt5_true
#print axioms fin12_div_refutation
#print axioms natle5_sq_refutation
#print axioms fin5_gt10_refutation
#print axioms fin6_succ_refutation
#print axioms pow2_refutation
#print axioms fact5_refutation
#print axioms div7_refutation
#print axioms prime91_refutation
#print axioms smt_bad_refutation
#print axioms euler_refutation'

end L4sDisproveBenchmark.Benchmark
