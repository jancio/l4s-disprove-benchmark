-- Root of the `L4sDisproveBenchmark` library: the `/lean4:disprove` evaluation benchmark.
-- `Benchmark` is the authoritative 16-target catalog (paper §5); `BaselineDecide` is the
-- bare-`decide` baseline.
--
-- The per-shape artifact files (EasyBad/MediumBad/HardBad/SmtBad) are the sources of the
-- paper's Listings 1–3. Each is a STANDALONE file carrying its own root-namespace
-- `T_counterexample` (the tool's append-only artifact name), so they are intentionally
-- NOT imported together here — that would clash. `lake build` still compiles them
-- independently via the lakefile `globs`; run one directly with
-- `lake env lean L4sDisproveBenchmark/<File>.lean`.
import L4sDisproveBenchmark.Benchmark
import L4sDisproveBenchmark.BaselineDecide
