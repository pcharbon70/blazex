---
title: "BH-06 Phase 4 Completion Evidence"
kind: note
created: "2026-09-12"
maturity: developing
tags: [atomvm, bh-06, build, compatibility, completion, evidence, wasm]
aliases: []
---

# BH-06 Phase 4 Completion Evidence

Back to the [plan](phase-04-exact-runtime-compatibility-profiles.md) and
[review](phase-04-review-and-reconciliation.md).

## Outcome

Phase 4 is complete with decision **accept**. The Popcorn runtime adapter now
owns an exact data-only compatibility profile. Application requirements are
validated and compared before AVM assembly, and the manifest binds the profile,
requirements, and content-addressed decision report.

## Reproduction

Two Elixir 1.18.4 builds produced byte-identical eight-artifact trees totaling
8,494,999 bytes. The manifest SHA-256 is
`658c864fb30f3eb09504fe0d542accb3d21c09501414f2c2583f8722c0168762`.
The canonical profile, requirements, and report SHA-256 values are respectively
`64dd2a93b260a28c5734bc34fafc8802b0ee938f696404d9baae8c07734112a7`,
`1c29c1badc04bde71ddab09831dcbec67496185600d23eb70c2a2f93c1f42d16`,
and `ab3c6c67c9a74bef59588c6c7e4796e3c4df98a91c6f6369a0a2d1ac1648ab7e`.

The accepted decision matches all three runtime identity fields, three protocol
versions, and two required features, with zero violations. Runtime, version,
ABI, missing/wrong protocol, missing/unsupported feature, malformed/duplicate
declaration, manifest mutation, and pre-assembly rejection cases fail closed.

Chrome 140 and Firefox 153 produced byte-identical raw reports with SHA-256
`8acec066ef5c7bad724cea4e3602809e81a47de8a1b073810a8ebf9754f3feea`.
Both completed the AtomVM/Wasm lifecycle with zero page errors; integrity
corruption failed before runtime startup.

## Bound evidence

- Runtime profile evidence SHA-256: `b5a454c692138f95f828a49bd75bb090ae5fd74c18429885977903121e7e5497`.
- Requirements evidence SHA-256: `3feb9a4675e1c66cdd38a268e1f67f9b1e3ee35e058aaa753fa9f5d7e81cc2e6`.
- Compatibility evidence SHA-256: `ab3c6c67c9a74bef59588c6c7e4796e3c4df98a91c6f6369a0a2d1ac1648ab7e`.
- Browser replay evidence SHA-256: `12e72bd5fff5e84a8cc28f22f8b88b0bf212fcd85ca01c55a28c6ebd12a890cf`.
- Compatibility implementation SHA-256: `329ab14f48d4d472c88a08ac708a3f62476b838bf8cadbebae61bab9f83e30ed`.
- Section 4.3 revision: `7593f69aadb5cca9b1deb2b8bb187e7d680229fb`.

Further BH-06 decomposition requires separate planning and authorization.
LiveView and LocalLiveView remain deferred; no production support or BH-07
authority is implied.
