---
title: "BH-06 Phase 9 Review and Reconciliation"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, pruning, reconciliation]
aliases: []
---

# BH-06 Phase 9 Review and Reconciliation

Back to the [plan](phase-09-audited-runtime-closure-reduction.md) and
[completion evidence](phase-09-completion.md).

## Decision

The implementation and candidate decisions are both **complete — accept**.
The corrective phase repairs Phase 8's one failed runtime budget without moving
the threshold, changing ownership, or hiding bytes.

## Review

Policy loading is closed-world, bounded, deterministic, and creates no atoms.
The reducer requires the exact 692-module input identity, removes the build-only
Mix task before client accounting, follows the complete BEAM import graph, and
uses pinned Popcorn 0.3.3 for function-level analysis. Additions, empty output,
missing roots, changed opaque BEAMs, malformed removal evidence, and input drift
all fail closed.

The first real replay exposed stripped Elixir/OTP BEAMs. Treating them as
analyzable would have been false, so the implementation records them as opaque
and copies each unchanged. It also promotes direct opaque-to-analyzable imports
to reported whole-module bridge roots. That rule repaired application-startup
callbacks generally; the explicit dynamic roots retain the AtomVM logger,
kernel application callback, Elixir configuration, Jason, and browser entrypoint.

The closure report is content-addressed private evidence in the manifest. The
payload engine sees thirteen manifest assets but still measures exactly seven
public artifacts. The accepted build follows the ordinary promotion path.

## Reconciliation

Package, browser-Wasm, schema, validator, mutation, independent deterministic
repeat, archive, runtime, JavaScript syntax, scoped Mix tests, and patch-hygiene
gates pass. The local browser proof is intentionally bounded to Chrome 140 and
Firefox 153 on active Linux. No claim is made for arbitrary applications,
production delivery, LiveView, or LocalLiveView.

The corpus-wide `70-tools/check_all.py` sweep was also run and remains red on
inherited stale BH-00/BH-01 roadmap bindings, superseded BH-02 leakage checks,
historical BH-05 source closures, and missing ignored BH-05 cleanup evidence.
Every BH-06 validator, including Phases 1 through 9, passes in that sweep. These
unrelated historical failures were neither rewritten nor counted as Phase 9
acceptance. The standalone runtime Mix project additionally requires its pinned
Elixir 1.17.3 rather than the installed 1.18.4; its generated runtime was tested
through both required browsers instead.
