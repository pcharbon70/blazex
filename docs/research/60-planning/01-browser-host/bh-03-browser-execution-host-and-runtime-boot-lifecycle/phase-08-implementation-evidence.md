---
title: "BH-03 Phase 8 Implementation Evidence"
kind: note
created: "2026-09-07"
maturity: developing
tags:
  - bh-03
  - acceptance
  - implementation-evidence
aliases: []
---

# BH-03 Phase 8 Implementation Evidence

## Decision: revise

Phase 8 review is complete; **BH-03 is not accepted and BH-04 is ineligible**.
The review found a reproducible active lifecycle defect, not an unavailable
platform qualification item. No runtime behavior was changed in this phase.

The real startup and registry classes were composed with an injected frame as
in the executable profile. After a correlated post-readiness runtime exit,
startup becomes failed and releases its transport, but the registry remains
ready with zero loss reports. A subsequent compatible open returns the same
stale scope. The profile's event recorder only records events; it does not call
the registry's explicit loss-reporting API.

Reproduce from the repository root:

```sh
node js/blazex_runtime/test/review/bh03-phase8-runtime-loss.mjs
python3 docs/research/validate_bh03_acceptance.py
python3 docs/research/validate_bh03_acceptance.py --require-accepted
```

The first command returns **blocker-reproduced**, not a recovery pass. The
second validates the truthful review record. The third intentionally exits 1
until a separately authorized corrective implementation and superseding review
resolve the blocker. This probe uses an injected frame, not a real browser crash.

## Reconciliation and review

[Authorization](../../../assets/bh-03-baseline/blazex-bh-03-phase-08-authorization-v0.1.0.json)
binds seven immutable completion decisions and the original entry/policy.
[Reconciliation](../../../assets/bh-03-baseline/blazex-bh-03-phase-08-reconciliation-v0.1.0.json)
maps nine outputs, 31 inherited/acceptance/deferral identities, five ownership
boundaries, and 116 candidate source/test/integration files.
[Review](../../../assets/bh-03-baseline/blazex-bh-03-phase-08-review-v0.1.0.json)
records seven analytical lenses from one implementing agent, not independent
reviewer approval.

The Phase 7 raw revision names an earlier instrumentation commit rather than
the complete final harness. Historical records remain immutable. This phase
binds the complete merged candidate revision and fresh browser repetitions.
Five fresh contexts and coarse Chrome heap observations are not long-lived
page leak proof; Firefox exposes no governed heap API.

## Executed evidence

- Pinned Elixir 1.17.3 / OTP 26: four projects, 39 tests; three configured formatter checks.
- JavaScript syntax/build and 20 test files passed.
- Active Linux Chrome 140.0.7339.80 and Firefox 153.0: five inherited browser scenarios each passed.
- Both browsers: one discarded warm-up, five retained ten-root lifecycle samples, and three declared failure scenarios each passed.
- Runtime build verification and nine Python tests passed.
- Research suite: 293 tests; 23 validators; four deterministic generators passed.
- JSON parsing and patch hygiene passed.

Exact commands, setup retries, versions, and result boundaries are in the
[validation log](../../../assets/bh-03-baseline/blazex-bh-03-phase-08-validation-log-v0.1.0.txt).
Fresh [browser evidence](../../../assets/bh-03-baseline/blazex-bh-03-phase-08-browser-repeat-v0.1.0.json)
and [measurements](../../../assets/bh-03-baseline/blazex-bh-03-phase-08-measurement-repeat-v0.1.0.json)
repeat existing suites; they do not cover automatic runtime-loss propagation.

## Corrective handoff and completion

The browser-host owner must connect active-generation runtime exit/failure to
registry-owned recovery or fallback, excluding intentional shutdown and stale
generations. Add active Chrome/Firefox tests covering one replacement, root
replay, repeated failure convergence, and no stale-ready reuse, then repeat
acceptance. This is required before BH-04, not deferred to release.

[Completion decision](../../../assets/bh-03-baseline/blazex-bh-03-phase-08-completion-v0.1.0.json)
binds the four section commits and final evidence. Public APIs remain
experimental; browsers remain unsupported. [DEFERRED] platform, physical-device,
second-host, and manual AT obligations retain owners and BH-22 due points.
No canonical acceptance registry, historical runtime source, toolkit boundary,
or production dependency was changed.

Back to [plan](phase-08-reconciliation-review-and-bh-03-acceptance.md) and
[milestone](README.md).
