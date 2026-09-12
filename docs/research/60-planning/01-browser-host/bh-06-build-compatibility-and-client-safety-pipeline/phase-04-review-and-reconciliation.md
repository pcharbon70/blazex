---
title: "BH-06 Phase 4 Review and Reconciliation"
kind: note
created: "2026-09-12"
maturity: developing
tags: [atomvm, bh-06, build, compatibility, reconciliation, wasm]
aliases: []
---

# BH-06 Phase 4 Review and Reconciliation

Back to the [plan](phase-04-exact-runtime-compatibility-profiles.md) and
[completion evidence](phase-04-completion.md).

## Decision

The decision is **accept** for the bounded exact-compatibility gate. The
candidate matches `atomvm-wasm` version `0.6.6-dev`, ABI `atomvm.avm/1`, three
protocol versions, and two required features. The report retains the one
unrequired provider feature, `browser-worker`, as explicitly unsupported.

## Enforcement review

Profiles and requirements are bounded data with exact fields; validation does
not create atoms, execute code, consult paths as identities, perform discovery,
or infer version ranges. Canonical ordering makes declaration order irrelevant.
Missing and unsupported values are distinct deterministic failures.

Client safety runs first, compatibility second, and AVM assembly only after both
pass. Unit tests observe that the assembly callback is not invoked after either
rejection. The output manifest binds both canonical input identities and the
content-addressed compatibility report. Chrome and Firefox repeat the complete
existing AtomVM/Wasm lifecycle exactly, so compatibility enforcement does not
regress the continuous vertical slice.

The corpus-wide `check_all.py` sweep remains red on inherited historical source
bindings, superseded-phase assumptions, and pre-existing kernel leakage checks;
its 559-test run reported 52 failures and 9 errors. The Phase 4 validator and
mutation suite, inherited BH-06 Phase 1–3 validators, archive validator, build
package tests, runtime contract tests, JavaScript runtime tests, demo tests, and
active browser gate pass. This phase does not rewrite historical evidence to
manufacture a green corpus-wide result.

## Boundary

This evidence applies only to the exact committed runtime artifact family and
does not grant browser, runtime, or product support. It does not claim semantic
version compatibility, probe arbitrary runtime behavior, or qualify worker use.
Secret/configuration scanning, license inventory, payload budgets, production
release manifests, and BH-07 remain separately authorized work.

LiveView and LocalLiveView remain **[DEFERRED]** and are not requirements,
profile features, build inputs, or acceptance gates.
