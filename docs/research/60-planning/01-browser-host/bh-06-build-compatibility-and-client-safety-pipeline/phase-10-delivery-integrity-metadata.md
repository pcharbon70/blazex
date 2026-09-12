---
title: "BH-06 Phase 10 - Delivery Integrity Metadata"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, cache, integrity, sri]
aliases: ["BH-06 phase 10"]
---

# BH-06 Phase 10 - Delivery Integrity Metadata

Back to the [milestone](README.md).

- [ ] 10 Phase - Delivery Integrity Metadata.
  - Need: content-addressed filenames and internal SHA-256 verification exist,
    but the candidate manifest does not yet provide browser-standard integrity
    tokens or a closed cache-header contract for a delivery adapter.
  - Outcome: every manifest artifact carries verified SHA-384 SRI metadata and
    its exact Cache-Control value; the manifest binds the normalized policy.
  - Boundary: this phase specifies and proves metadata consumed by a future
    delivery adapter. It does not serve production traffic, implement Phoenix,
    route orchestration, predictive prefetch, support promotion, LiveView,
    LocalLiveView, BH-07, or BH-19.

  - [x] 10.1 Section - Freeze delivery-integrity authority and contract.
    - [x] Bind accepted Phase 9, exact base, ownership, workflow, and deferrals.
    - [x] Freeze SHA-384 SRI encoding, exact role policy, cache values, limits,
      deterministic ordering, and fail-closed diagnostics without creating atoms.
    - [x] Activate schemas, candidate policy, planning, baseline, and evidence indexes.

  - [x] 10.2 Section - Implement and test integrity metadata generation.
    - [x] Validate the closed policy and decorate every artifact from its bytes.
    - [x] Bind the canonical policy digest and reject unknown/missing roles,
      duplicate paths, unsupported algorithms, input drift, and metadata drift.
    - [x] Cover deterministic output and focused negative mutations in package tests.

  - [x] 10.3 Section - Integrate and replay the browser-Wasm candidate.
    - [x] Apply delivery metadata before manifest publication and payload accounting.
    - [x] Serve exact declared Cache-Control headers and verify SHA-384 before startup.
    - [x] Prove Chrome/Firefox parity plus tampered integrity and header negatives.

  - [ ] 10.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package, browser-Wasm, schema, validator, mutation, deterministic-repeat,
      JavaScript, scoped Mix, historical BH-06, and patch-hygiene gates.
    - [ ] Publish exact policy/manifest/browser identities, observations,
      limitations, deferrals, and the honest completion decision.
    - [ ] Accept only when every artifact is covered and both active browsers pass.

## Exit gate

Equivalent authorized inputs produce byte-equivalent manifests whose artifact
records each carry a recomputable `sha384-<base64>` token and exact declared
Cache-Control value. Missing, altered, duplicate, unknown-role, or over-limit
metadata fails closed. Chrome and Firefox must observe the declared public
headers and complete the existing AtomVM lifecycle with SRI verified before boot.

## Connections

- [Phase 9 completion](phase-09-completion.md)
- [Delivery-integrity contract](delivery-integrity-contract.md)
- [Payload-accounting contract](payload-accounting-contract.md)
