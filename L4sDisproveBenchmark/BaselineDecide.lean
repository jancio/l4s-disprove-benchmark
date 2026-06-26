import Mathlib

/-!
Baseline probe: what does a BARE `decide` (no search, no orchestration) certify?
Finite/decidable negations close; infinite-domain (ℕ) universals have no Decidable
instance, so `decide` fails — exactly the gap the tool's witness search fills.
Lines that should FAIL are marked; comment/uncomment to reproduce the errors.
-/

namespace L4sDisproveBenchmark.BaselineDecide

-- Finite, decidable: bare `decide` SUCCEEDS.
theorem b_easy : ¬ (∀ n : Fin 5, n.val < 3) := by decide
theorem b_prime91 : ¬ Nat.Prime 91 := by decide
theorem b_fin12 : ¬ (∀ n : Fin 12, 2 ∣ n.val → 3 ∣ n.val) := by decide

-- Infinite domain (ℕ): bare `decide` FAILS (no Decidable instance for the ∀).
-- Uncomment to confirm "failed to synthesize Decidable":
-- theorem b_medium : ¬ (∀ n : ℕ, n ^ 2 ≤ n * 10) := by decide
-- theorem b_euler  : ¬ (∀ n : ℕ, Nat.Prime (n ^ 2 + n + 41)) := by decide

end L4sDisproveBenchmark.BaselineDecide
