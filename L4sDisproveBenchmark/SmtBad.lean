import Mathlib

/-- Nonlinear over ℤ (Shape 2/atom): `decide` (ℤ infinite), `omega` (nonlinear),
    and 1-D `enumerate` (two free variables) all fail to refute this.
    The `external` method emits an SMT query; Z3 supplies a witness that is then
    lifted into a Lean term and re-checked by the kernel.
    False: e.g. 2·(-4)² − 3·3² = 32 − 27 = 5. -/
theorem smt_bad : ∀ x y : ℤ, 2 * x ^ 2 - 3 * y ^ 2 ≠ 5 := by sorry
/-- Refutation of `smt_bad`: witness (x,y) = (-4,3), the model returned by Z3
    (untrusted) and re-checked by the kernel; 2*(-4)^2 - 3*3^2 = 32 - 27 = 5. -/
theorem T_counterexample : ∃ x y : ℤ, 2 * x ^ 2 - 3 * y ^ 2 = 5 := ⟨-4, 3, by norm_num⟩
#print axioms T_counterexample
