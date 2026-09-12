---
title: "BH-06 Exact Compatibility Profile Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [atomvm, bh-06, build, compatibility, contract, wasm]
aliases: []
---

# BH-06 Exact Compatibility Profile Contract

Back to the [Phase 4 plan](phase-04-exact-runtime-compatibility-profiles.md).

## Ownership and inputs

The runtime adapter supplies a committed compatibility profile. The build owns
validation, comparison, diagnostics, and manifest binding. Application build
configuration supplies a bounded requirement set. A profile is evidence about
one exact runtime artifact family; it is not a support promise or a range.

Inputs are data only. Validation must not create atoms, execute callbacks, use
paths as identity, perform network discovery, or infer compatibility from an
unlisted version. LiveView and LocalLiveView are not compatibility inputs.

## Exact comparison

Runtime ID, runtime version, and ABI are exact strings. Each required protocol
ID must occur once in both documents and its version must match exactly. Each
required feature ID must occur once in both documents and the profile must mark
it `supported`. Extra profile protocols and features are retained in the result
as unused provider declarations; they do not reject a candidate because a
runtime profile describes a reusable provider rather than one application.

Unknown fields, malformed or duplicate records, a runtime mismatch, ABI
mismatch, absent protocol, protocol-version mismatch, absent feature, or a
feature marked `unsupported` rejects before AVM assembly. Reports and failures
are deterministically ordered and include bounded actionable reasons.

## Result and manifest

The result binds canonical SHA-256 identities for the normalized profile and
requirements, records each comparison, retains unused provider capabilities,
and summarizes the decision. Only a report with `compatible: true` may reach
assembly. The output manifest binds that report as an immutable,
content-addressed JSON artifact and exposes the exact profile ID and digest.

This phase makes no claim about secret absence, licensing, payload size,
production readiness, browser support, or compatibility beyond the exact
declared profile.
