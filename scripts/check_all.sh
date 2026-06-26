#!/usr/bin/env bash
# check_all.sh — one-command verification for the l4s-disprove-benchmark.
#
# Builds the project, asserts EVERY certified term's `#print axioms` report lies
# within the whitelist {propext, Classical.choice, Quot.sound} — a whitelist (not a
# blocklist) catches `Lean.ofReduceBool` (native_decide), `sorryAx`, and any other
# unexpected axiom — and validates results.json against the live #print axioms output.
#
# Single source of truth for humans and CI: run `bash scripts/check_all.sh`
# locally; `.github/workflows/lean_action_ci.yml` invokes this same script.
set -euo pipefail

cd "$(dirname "$0")/.."

ALLOWED='propext|Classical\.choice|Quot\.sound'        # 3 standard axioms (dots escaped)
FILES=(Benchmark BaselineDecide EasyBad MediumBad HardBad SmtBad)
EXPECTED_REPORTS=21    # Benchmark: 17 #prints + per-shape: 4. Bump if the suite changes.

log="$(mktemp "${TMPDIR:-/tmp}/check_all.XXXXXX")" || { echo "FAIL: could not create a temp file" >&2; exit 1; }
trap 'rm -f "$log"' EXIT

echo ">> lake exe cache get  (prebuilt mathlib; falls back to a source build)"
lake exe cache get || true

echo ">> lake build"
lake build

echo ">> elaborating ${#FILES[@]} files; collecting #print axioms"
: > "$log"
for f in "${FILES[@]}"; do
  lake env lean "L4sDisproveBenchmark/$f.lean" 2>&1 | tee -a "$log"
done

echo ">> axiom-whitelist check"
# A violation = a "depends on axioms: [...]" line whose bracket contents are NOT
# all whitelisted, so any non-standard axiom (ofReduceBool, sorryAx, …) trips it.
bad="$(grep -E 'depends on axioms: \[' "$log" \
       | grep -vE "depends on axioms: \[((${ALLOWED})(, ?)?)+\]" || true)"
if [ -n "$bad" ]; then
  echo "FAIL: non-whitelisted axiom(s) in a certified term:" >&2
  printf '%s\n' "$bad" | sed 's/^/  /' >&2
  exit 1
fi

reports="$(grep -cE 'depends on axioms|does not depend on any axioms' "$log" || true)"
if [ "$reports" -lt "$EXPECTED_REPORTS" ]; then
  echo "FAIL: expected >= $EXPECTED_REPORTS '#print axioms' reports, got $reports" >&2
  echo "      (a '#print axioms' directive may have been removed)." >&2
  exit 1
fi

echo ">> results.json consistency check"
if command -v python3 >/dev/null 2>&1; then
  python3 scripts/validate_results.py "$log"
else
  echo "WARN: python3 not found — skipping the results.json cross-check (the Lean axiom whitelist above still ran)."
fi

echo "PASS: $reports certified terms; all axioms within {propext, Classical.choice, Quot.sound}."
