import Mathlib

/-- Holds for all n in any reasonable bound; if it's actually true, disprove will bail INCONCLUSIVE.
    (n² ≤ 1000n holds for all n ≤ 1000, so any bound <1001 won't find a witness.) -/
theorem hard_bad : ∀ n : Nat, n^2 ≤ n * 1000 := by sorry
/-- Refutation of `hard_bad`: witness n = 1001 found by cycle-2 enumerate
    widening to [64,1024); 1001^2 = 1002001 > 1001000 = 1001*1000. -/
theorem T_counterexample : ∃ n : Nat, ¬ (n ^ 2 ≤ n * 1000) := ⟨1001, by norm_num⟩
#print axioms T_counterexample
