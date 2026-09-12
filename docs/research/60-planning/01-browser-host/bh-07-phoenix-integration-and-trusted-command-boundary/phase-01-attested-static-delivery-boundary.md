---
title: "BH-07 Phase 1 - Attested Static Delivery Boundary"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, phoenix, static-delivery, wasm]
aliases: ["BH-07 phase 1"]
---

# BH-07 Phase 1 - Attested Static Delivery Boundary

Back to the [milestone](README.md).

- [ ] 1 Phase - Attested Static Delivery Boundary.
  - Need: BH-06 produces an accepted attested browser artifact set, but the
    Phoenix profile does not yet expose that set as a current governed route;
    it also retains historical LiveView/LocalLiveView dependencies contrary to
    their explicit deferral from current host work.
  - Outcome: a reusable manifest-driven delivery contract and `/bh07/` Phoenix
    route serve only public attested artifacts with exact headers and integrity.
  - Boundary: no sessions, bootstrap state, commands, pushes, reconnect,
    routing ownership, deployment coordination, production support, LiveView,
    LocalLiveView, or BH-08 work is authorized.

  - [x] 1.1 Section - Activate BH-07 and freeze the delivery boundary.
    - [x] Bind accepted BH-06, exact base, owner authorization, workflow, and deferrals.
    - [x] Freeze route, manifest, attestation, public/private, header, integrity,
      path, method, scaling, and failure semantics.
    - [x] Activate BH-07 planning, baseline, integration, and evidence indexes.

  - [ ] 1.2 Section - Implement reusable attested-delivery validation.
    - [ ] Validate the BH-06 manifest/attestation pair without Phoenix or atom creation.
    - [ ] Resolve only declared public paths and return exact content type,
      Cache-Control, ETag, byte count, and integrity metadata.
    - [ ] Reject private, missing, escaping, stale, malformed, duplicate, or over-limit input.

  - [ ] 1.3 Section - Integrate the Phoenix route and remove deferred coupling.
    - [ ] Add `/bh07/` GET/HEAD delivery backed by validated output and deny private evidence.
    - [ ] Remove LiveView, LocalLiveView, and renderer-LiveView dependencies and
      current health capability coupling while preserving historical evidence files.
    - [ ] Prove redirects, public delivery, headers, conditional/HEAD behavior,
      denial, traversal, unsupported methods, and package/profile boundaries.

  - [ ] 1.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package/profile tests, schemas, validator mutations, archive,
      dependency, formatting, and patch-hygiene gates.
    - [ ] Publish evidence, limitations, inherited corpus status, and decision.
    - [ ] Accept only when the attested artifact is served and all deferred
      LiveView/LocalLiveView coupling is absent from the active profile.

## Exit gate

The Phoenix profile serves every and only BH-06-manifest public artifact under
`/bh07/`, denies private evidence, preserves exact cache/integrity identities,
and passes GET/HEAD/conditional/negative tests. Active source and dependencies
contain no LiveView or LocalLiveView coupling.
