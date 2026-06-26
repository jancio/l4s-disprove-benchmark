# l4s-disprove-benchmark

The evaluation benchmark for **`/lean4:disprove`**, the certified counterexample-search
command in the [`lean4-skills`](https://github.com/cameronfreer/lean4-skills) package.

Every target here is a Lean 4 proposition together with the **kernel-certified refutation**
the tool emits (or, for the lone true control, the absence of one). Nothing is trusted on a
solver's say-so: a counterexample counts only when Lean typechecks a term of the negation
under `lake env lean`.

This is the benchmark referenced by the paper:

> **Lean Disprove: Certified Counterexample Search for AI-Assisted Formal Mathematics.**
> Jan Ondras and Cameron Freer. 3rd AI for Math Workshop: Toward Self-Evolving Scientific Agents (ICML 2026).
> <https://openreview.net/forum?id=5ck1jRE65S>

## The benchmark

**16 hand-built targets = 15 false + 1 true control**, spanning the shape taxonomy and a
difficulty gradient in which each successive tier of the tool is load-bearing (paper §5):

| Regime | Count | Method | Witness(es) |
|---|---|---|---|
| decidable-finite | 10 false | `decide-cascade` (bare `decide`) | — |
| bounded-ℕ | 3 false | `enumerate` over `[5, 64)` | n = 11, 40, 5 |
| out-of-window | 1 false | multi-cycle `enumerate` widening → `[64, 1024)` | n = 1001 |
| nonlinear-ℤ | 1 false | `external` Z3 (model re-checked by the kernel) | (x, y) = (−4, 3) |
| true control | 1 true | must **not** be refuted (no false positive) | — |

Cumulative capability escalation (paper §5): bare `decide` certifies **10**/15, `+ enumerate`
**13**, `+ widening` **14**, `+ external` **15**; the true control is correctly never refuted.

**Axiom hygiene.** Every certified term passes `#print axioms` with nothing beyond Lean/mathlib's
three standard axioms — `propext`, `Classical.choice`, `Quot.sound` — and **never** `Lean.ofReduceBool`
(`native_decide` is left off). The simplest `decide` over a small `Fin` needs no axioms at all.

## Layout

```
L4sDisproveBenchmark/
  Benchmark.lean       -- authoritative catalog of all 16 targets (paper §5)
  BaselineDecide.lean  -- bare-`decide` baseline: what `decide` alone can / cannot close
  EasyBad.lean         -- source of paper Listing 1 (decidable-finite artifact)
  MediumBad.lean       -- bounded-ℕ artifact (witness n = 11); RUNS.md `medium_bad`
  HardBad.lean         -- source of paper Listing 2 (out-of-window, n = 1001) — `HardBad.lean:5`
  SmtBad.lean          -- source of paper Listing 3 (nonlinear-ℤ external Z3) — `SmtBad.lean:8`
RUNS.md                -- genuine run transcripts + `#print axioms` ground truth (paper §6)
results.json           -- machine-readable per-target manifest (regime/method/witness/axioms)
scripts/check_all.sh   -- one-command build + axiom-whitelist + results.json check (run by CI)
scripts/validate_results.py  -- results.json ↔ Lean axiom-drift + structural check (called above)
```

`Benchmark.lean` is the single place that maps 1:1 onto the paper's 16 targets. The per-shape
files (`EasyBad`/`MediumBad`/`HardBad`/`SmtBad`) are the exact sources behind the paper's
listings and the `RUNS.md` case studies: each holds the original conjecture as
`theorem … := by sorry` (the disprove *input*) followed by the appended, kernel-certified
`T_counterexample` — the tool's append-only artifact format. Their filenames and line numbers
are referenced verbatim by the paper, so they are kept fixed.

## Build & reproduce

One command builds the benchmark and checks every certified term's axioms — exactly what CI runs:

```bash
bash scripts/check_all.sh
```

- It runs `lake exe cache get` + `lake build`, elaborates all library files, and **fails** unless
  every `#print axioms` report is within `{propext, Classical.choice, Quot.sound}` — catching
  `Lean.ofReduceBool` (`native_decide`), `sorryAx`, or any other unexpected axiom. It then validates
  [`results.json`](results.json) — a per-target manifest (regime, method, witness, axioms) — against
  that live output, so the manifest can never drift from the Lean source.
- Lower level: `lake build` alone checks the artifacts; `lake env lean L4sDisproveBenchmark/Benchmark.lean`
  checks one file. `Benchmark.lean` ends with `#print axioms` on **every** catalog target, and each
  per-shape file prints its own `T_counterexample`.
- Toolchain is pinned in `lean-toolchain` (`leanprover/lean4:v4.29.1`); mathlib is pinned in
  `lake-manifest.json`. The first build fetches the prebuilt mathlib cache (a multi-GB `.lake/`
  cache, a few minutes); afterwards a full check is seconds.
- **Z3** (`4.15.4`) is needed only to *reproduce* the `smt_bad` external search; the resulting
  Lean term re-checks without it. See `RUNS.md` for the recorded transcripts.

### Reproduce the search (vs. verify the artifacts)

`lake build` **verifies** that the committed `T_counterexample` terms typecheck with clean
axioms — it does **not** re-run the search. Those terms are outputs of **`/lean4:disprove`**, the
command in the [`lean4-skills`](https://github.com/cameronfreer/lean4-skills) package. To re-run
the tool on a target, install that package and invoke it on the conjecture's file:line — e.g.
`/lean4:disprove L4sDisproveBenchmark/HardBad.lean:5` (multi-cycle widening, n = 1001) or
`/lean4:disprove L4sDisproveBenchmark/SmtBad.lean:8` (external Z3, model (−4, 3)). The Z3 method
needs **Z3 4.15.4** on `PATH` (`apt install z3` / `brew install z3`, or the
[z3-4.15.4 release](https://github.com/Z3Prover/z3/releases/tag/z3-4.15.4)).

## Citation

```bibtex
@inproceedings{
ondras2026lean,
title={Lean Disprove: Certified Counterexample Search for {AI}-Assisted Formal Mathematics},
author={Jan Ondras and Cameron Freer},
booktitle={3rd AI for Math Workshop: Toward Self-Evolving Scientific Agents},
note={Workshop at ICML 2026},
year={2026},
url={https://openreview.net/forum?id=5ck1jRE65S}
}
```

## License

[MIT](LICENSE) © 2026 Jan Ondras and Cameron Freer.
