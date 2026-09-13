---
title: "BH-07 Phase 2 - Public Bootstrap Envelope"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, bootstrap, phoenix, trust-boundary]
aliases: ["BH-07 phase 2"]
---

# BH-07 Phase 2 - Public Bootstrap Envelope

Back to the [milestone](README.md).

- [x] 2 Phase - Public Bootstrap Envelope.
  - Need: Phase 1 delivers an attested browser artifact set, but the browser
    has no bounded server-owned document describing which accepted manifest,
    entrypoint, route, capabilities, and explicitly public initial values apply.
  - Outcome: a deterministic `/bh07/bootstrap.json` response binds public
    bootstrap data to the accepted delivery identity without projecting secrets,
    authorization, session state, or mutation authority into the browser.
  - Boundary: no sessions, authentication projection, CSRF, commands, pushes,
    reconnect, routing ownership, deployment coordination, production support,
    LiveView, LocalLiveView, or BH-08 work is authorized.

  - [x] 2.1 Section - Authorize Phase 2 and freeze the bootstrap boundary.
    - [x] Bind Phase 1 completion, exact base, owner authorization, workflow, and deferrals.
    - [x] Freeze envelope identity, value vocabulary, size/shape, secret-exclusion,
      caching, method, conditional-request, and failure semantics.
    - [x] Activate Phase 2 planning, baseline, integration, and evidence indexes.

  - [x] 2.2 Section - Implement the reusable public-bootstrap contract.
    - [x] Bind bootstrap output to the accepted manifest and entrypoint attestation.
    - [x] Normalize only bounded JSON-compatible public values without atom creation.
    - [x] Reject secret-like keys, authority claims, invalid shapes, excess depth,
      excess counts, oversized output, and stale delivery identities.

  - [x] 2.3 Section - Integrate the Phoenix bootstrap route.
    - [x] Add public GET/HEAD `/bh07/bootstrap.json` delivery with `no-store`,
      strong ETag, exact length, `nosniff`, and conditional response behavior.
    - [x] Source only explicitly configured public values and reuse the Phase 1
      validated-delivery cache without adding per-request retained state.
    - [x] Prove accepted output, binding, HEAD/conditional behavior, unsupported
      methods, secret rejection, invalid configuration, and unchanged deferrals.

  - [x] 2.4 Section - Reproduce, review, and publish completion.
    - [x] Run package/profile tests, validator mutations, archive, dependency,
      JSON, formatting, and patch-hygiene gates.
    - [x] Publish evidence, limitations, inherited corpus status, and decision.
    - [x] Accept only when bootstrap is bounded, public-only, delivery-bound,
      non-authoritative, and independent of LiveView and LocalLiveView.

## Exit gate

The Phoenix profile returns one deterministic, bounded, public-only bootstrap
envelope tied to the accepted BH-06 manifest and attestation. It exposes no
session, secret, authorization, command, or server-mutation authority and adds
no LiveView or LocalLiveView coupling.
