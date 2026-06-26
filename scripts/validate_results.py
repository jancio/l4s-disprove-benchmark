#!/usr/bin/env python3
"""Validate results.json against the Lean `#print axioms` output and its own
summary aggregates, so the manifest is CI-verified ground truth (not just docs).

Usage:
  python3 scripts/validate_results.py [AXIOM_LOG]

AXIOM_LOG is the captured `#print axioms` output (scripts/check_all.sh passes it).
Without it, only the structural/summary checks run (no Lean cross-check).

Checks:
  * `summary` aggregates are derivable from `targets`: target count, the false-target
    count (targets whose regime != "true-control"), the true-control count, per-regime
    counts, and the cumulative escalation;
  * every false target is expected REFUTED and the true control is not — the design
    invariant behind "certifies 15/15 false targets" (truth value vs outcome kept apart);
  * names and decls are unique;
  * every target's `axioms` is within the whitelist; and
  * (with a log) every target's `axioms` exactly matches what Lean reports for its
    `decl` — the anti-drift check.
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RESULTS = ROOT / "results.json"
WHITELIST = {"propext", "Classical.choice", "Quot.sound"}

_NONE = re.compile(r"'([^']+)' does not depend on any axioms")
_DEPS = re.compile(r"'([^']+)' depends on axioms: \[([^\]]*)\]")


def parse_axiom_log(text: str) -> dict[str, frozenset[str]]:
    """Map each declaration name to its axiom set from `#print axioms` lines."""
    out: dict[str, frozenset[str]] = {}
    for line in text.splitlines():
        m = _NONE.search(line)
        if m:
            out[m.group(1)] = frozenset()
            continue
        m = _DEPS.search(line)
        if m:
            out[m.group(1)] = frozenset(a.strip() for a in m.group(2).split(",") if a.strip())
    return out


def main() -> int:
    errors: list[str] = []
    data = json.loads(RESULTS.read_text(encoding="utf-8"))
    targets = data["targets"]
    summary = data["summary"]

    log = {}
    if len(sys.argv) > 1:
        log = parse_axiom_log(Path(sys.argv[1]).read_text(encoding="utf-8"))

    # --- structural / summary aggregates (all derivable from `targets`) ---
    if len(targets) != summary["targets"]:
        errors.append(f"summary.targets={summary['targets']} but {len(targets)} target rows")

    # summary.false is the size of the false-statement test set — a property of the
    # benchmark, derived structurally (every target except the true control is false),
    # NOT from the tool's outcome. Keeps truth value decoupled from the REFUTED verdict.
    n_false = sum(1 for t in targets if t["regime"] != "true-control")
    if n_false != summary["false"]:
        errors.append(f"summary.false={summary['false']} but {n_false} non-control targets")

    # Design invariant (and the paper's "certifies 15/15 false targets"): every false
    # target is expected REFUTED, and the true control is not — the one place truth value
    # and outcome meet, asserted per-target rather than inferred from matching counts.
    for t in targets:
        is_control = t["regime"] == "true-control"
        refuted = t["expected_outcome"] == "REFUTED"
        if not is_control and not refuted:
            errors.append(f"{t['name']}: false target expected REFUTED, got {t['expected_outcome']!r}")
        if is_control and refuted:
            errors.append(f"{t['name']}: true control must not be REFUTED")

    n_ctrl = sum(1 for t in targets if t["regime"] == "true-control")
    if n_ctrl != summary["true_control"]:
        errors.append(f"summary.true_control={summary['true_control']} but {n_ctrl} control rows")

    reg = Counter(t["regime"] for t in targets)
    for k, v in summary["regimes"].items():
        if reg.get(k, 0) != v:
            errors.append(f"summary.regimes[{k}]={v} but {reg.get(k, 0)} rows")

    derived_cum = {
        "decide": reg["decidable-finite"],
        "+enumerate": reg["decidable-finite"] + reg["bounded-N"],
        "+widening": reg["decidable-finite"] + reg["bounded-N"] + reg["out-of-window"],
        "+external": reg["decidable-finite"] + reg["bounded-N"] + reg["out-of-window"] + reg["nonlinear-Z"],
    }
    if summary["cumulative_certified_of_15_false"] != derived_cum:
        errors.append(
            f"summary.cumulative_certified mismatch: json="
            f"{summary['cumulative_certified_of_15_false']} derived={derived_cum}"
        )

    names = [t["name"] for t in targets]
    if len(set(names)) != len(names):
        errors.append("duplicate target names")
    decls = [t["decl"] for t in targets]
    if len(set(decls)) != len(decls):
        errors.append("duplicate decls")

    # --- per-target axioms: within whitelist, and matching Lean reality ---
    for t in targets:
        ax = set(t["axioms"])
        outside = ax - WHITELIST
        if outside:
            errors.append(f"{t['name']}: axioms {sorted(outside)} not in whitelist")
        if log:
            decl = t["decl"]
            if decl not in log:
                errors.append(f"{t['name']}: decl {decl!r} not found in #print axioms output")
            elif log[decl] != frozenset(ax):
                errors.append(
                    f"{t['name']}: axioms drift — json={sorted(ax)} lean={sorted(log[decl])}"
                )

    if errors:
        print("FAIL: results.json validation:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    where = "axioms match Lean; " if log else ""
    print(f"PASS: results.json consistent ({len(targets)} targets; {where}summary derivable).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
