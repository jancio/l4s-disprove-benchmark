import Mathlib

/-- A false statement decidable in one shot: `n.val < 3` fails at n = 3 and n = 4. -/
theorem easy_bad : ∀ n : Fin 5, n.val < 3 := by sorry
/-- Refutation of `easy_bad` (∀ n : Fin 5, n.val < 3): false at n = ⟨3, _⟩ (n.val = 3 ≥ 3).
    Negation is decidable on the finite type `Fin 5`. -/
theorem T_counterexample : ¬ (∀ n : Fin 5, n.val < 3) := by decide
#print axioms T_counterexample
