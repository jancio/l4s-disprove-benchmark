import Mathlib

/-- False at n = 11: 11² = 121 > 110 = 11·10.  Holds for n ≤ 10. -/
theorem medium_bad : ∀ n : Nat, n^2 ≤ n * 10 := by sorry
/-- Refutation of `medium_bad`: witness n = 11 (11^2 = 121 > 110 = 11*10). -/
theorem T_counterexample : ∃ n : Nat, ¬ (n ^ 2 ≤ n * 10) := ⟨11, by norm_num⟩
#print axioms T_counterexample
