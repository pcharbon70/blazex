---
title: "BH-06 Phase 8 Review and Reconciliation"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, brotli, build, payload, reconciliation]
aliases: []
---

# BH-06 Phase 8 Review and Reconciliation

Back to the [plan](phase-08-payload-budgets-and-public-artifact-accounting.md)
and [completion evidence](phase-08-completion.md).

## Decision

The implementation decision is **complete** and the candidate decision is
**revision-required**. Measurement is closed-world and reproducible; promotion
is correctly blocked by the one failed runtime budget.

## Review

The policy classifies every manifest role. Seven public artifacts, including
the manifest, are measured; six reports are retained as private evidence. The
engine verifies decoded hashes and sizes, rejects undeclared files and exposure
drift, repeats quality-11 Brotli three times, compares complete compressed byte
strings, writes content-stable sidecars, and recomputes each budget result.

An explicit evidence-only switch is required to retain a rejected build for
browser replay. It does not change the report decision. The active server denies
private paths and negotiates Brotli; browser Web APIs transparently decode the
response before the existing SHA-256 checks, so transport encoding cannot bypass
content integrity.

The application, decoded application, loader, and public-source-map budgets pass.
The base AVM remains deliberately broad and causes the runtime owner to exceed
its compressed threshold by 1,051,398 bytes. Reclassifying those bytes as
application or omitting standard-library code from accounting would conceal the
problem and is rejected.

## Reconciliation

Scoped package, browser, schema, validator, mutation, deterministic-repeat,
archive, runtime, JavaScript, demo, syntax, and patch-hygiene checks pass. Phase
8 does not repair historical corpus-wide bindings or claim production serving.
A corrective closure-reduction phase requires separate authorization.
