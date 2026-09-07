---
title: "BH-03 Phase 9 Implementation Evidence"
kind: note
created: "2026-09-07"
maturity: stable
tags:
  - bh-03
  - runtime-lifecycle
  - implementation-evidence
aliases: []
---

# BH-03 Phase 9 Implementation Evidence

## Accepted with bounded conditions

BH-03 is accepted for internal experimental development. BH-04 is eligible,
not authorized. This supersedes the downstream consequence of Phase 8's revise
decision without rewriting its findings or historical evidence.

The blocking runtime-loss finding is closed by ready-handle loss observation
owned by the registry, not by the profile event logger. Startup latches failure
for late subscribers, validates attempt/manifest generations, releases its
transport, and notifies the registry before emitting diagnostics. Registry
observers are bound to a specific handle, removed during stop/replacement, and
cannot report a previous generation as current.

A known loss immediately removes ready access. One replacement may replay
retained roots through their existing handles. A second loss, a failed replay,
or loss during replacement converges to fallback without partial readiness.
The fallback gate also closes root registration if loss occurs on the final
replay acknowledgement. Intentional stop clears observers before transport
cleanup, and a closing scope rejects new opens.

## Source-bound evidence

The complete observed candidate is `72d398017d9fe67b7017d71bfb65356ce7f7b73a`.
[Acceptance](../../../assets/bh-03-baseline/blazex-bh-03-phase-09-acceptance-v0.1.0.json)
binds 117 current runtime, test, package, profile and integration files to that
git tree and to SHA-256. It carries all nine required outputs and 31 inherited
obligations, with explicit overlays for the corrected lifecycle and historical
provenance finding. Seven review lenses were performed by the implementing
agent; they are not independent external review.

- JavaScript build and 21 test files passed, including eight new loss-observation cases.
- Pinned Elixir 1.17.3 / OTP 26: 39 tests across four projects; three configured format checks passed.
- Runtime build verification and nine Python tests passed.
- Chrome 140.0.7339.80 and Firefox 153.0 passed five new recovery scenarios each.
- Both browsers repeated five inherited profile scenarios and five retained ten-root lifecycle samples plus three declared failures.
- Research validation, mutation tests, generated artifacts, archive links, JSON and patch hygiene passed; exact counts are in the validation log.

[Recovery evidence](../../../assets/bh-03-baseline/blazex-bh-03-phase-09-recovery-v0.1.0.json)
uses test-response-only instrumentation to invoke the real runtime's onExit
and onAbort callbacks. It exercises actual Wasm frame transport and AVM root
replay, but is **not** an OS crash, browser termination, worker hang or
memory-pressure qualification. The injection hook is never shipped in profile
assets. Replay yields twelve real acknowledgements (eight original, four
replayed) and one surviving runtime iframe; terminal stop/fallback yields zero.

[Profile repetitions](../../../assets/bh-03-baseline/blazex-bh-03-phase-09-profile-v0.1.0.json)
and [measurement repetitions](../../../assets/bh-03-baseline/blazex-bh-03-phase-09-measurements-v0.1.0.json)
use the same exact final candidate. Runs captured before the final replay-race
fix were discarded and rerun, not relabeled.

## Historical and current validation

Run from the repository root:

```sh
python3 docs/research/validate_bh03_correction.py
node --test js/blazex_runtime/test/runtime-loss-observation.test.js
```

The new validator checks CURRENT source hashes; historical exceptions cannot
satisfy it. Earlier validators retain historical phase semantics. The Phase 8
validator with `--require-accepted` deliberately continues to reject its old
revise record; it is not the latest gate. Its old loss probe also belongs to
the historical source snapshot, not the corrected runtime.

Only exact paths named by the hash-bound Phase 9 authorization may use the
prior git blob in historical completion validation. Phase 9 separately binds
the current helper, changed validators, sources, tests and evidence. Original
completion decisions, raw evidence, integration indexes, canonical acceptance
registry and package activation metadata remain historical, unchanged records.

## Retained boundaries and handoff

Five fresh contexts and coarse Chrome heap measurements do not prove long-lived
page leak freedom. Firefox's missing governed heap API gets no pass credit.
[DEFERRED] platform/device, second-host and manual AT qualification remains
owned by qualification owners and due by BH-22. Native gaps, private API pins,
upgrade reruns, production security and release controls remain inherited
obligations. No support, public API stability or release budget is granted.

The browser-host milestone may now hand its internal lifecycle baseline to
BH-04 once separately authorized. No BH-04 rendering or interaction transport
was implemented here.

- [Validation log](../../../assets/bh-03-baseline/blazex-bh-03-phase-09-validation-log-v0.1.0.txt)
- [Completion record](../../../assets/bh-03-baseline/blazex-bh-03-phase-09-completion-v0.1.0.json)
- [Phase plan](phase-09-runtime-loss-correction-and-renewed-acceptance.md)
- [Milestone](README.md)
