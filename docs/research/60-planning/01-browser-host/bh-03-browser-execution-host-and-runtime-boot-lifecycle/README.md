---
title: "BH-03 Browser Execution-Host and Runtime Boot Lifecycle"
kind: map
created: "2026-09-05"
tags:
  - archive-navigation
  - bh-03
  - browser-host
  - directory-index
  - implementation-planning
  - runtime-lifecycle
aliases:
  - "BH-03 implementation plan"
---

# BH-03 Browser Execution-Host and Runtime Boot Lifecycle

## Purpose

This plan turns the accepted internal BH-02 contracts and the disposable BH-01
runtime proof into reusable browser-host lifecycle behavior. It must support
multiple independent roots through one compatible runtime instance, validate
every manifest and artifact before activation, and make startup, readiness,
shutdown, mismatch, and fallback behavior explicit.

BH-03 does not implement the reference DOM interaction transport, Phoenix
commands, Plug integration, product components, production support, or public
API stability. Those remain BH-04 and later work.

## Authorization status

The repository owner explicitly authorized Phase 1 on 2026-09-05, and its
activation gate passed on 2026-09-06. The accepted handoff, milestone plan,
lifecycle vocabulary, existing reusable boundaries, empty integration suite,
and fail-closed validation are now recorded. Phase 2 completed its compatibility
identity, discovery, prerequisite, and strict manifest gate on 2026-09-06.
Phase 3 is eligible but remains unauthorized; artifact acquisition and runtime
startup are still unimplemented.

## What belongs here

- Runtime and host compatibility identities, manifests, prerequisite checks,
  discovery, artifact validation, startup, readiness, and shutdown contracts.
- Shared runtime-instance and independent root-registration lifecycles.
- Intentional mismatch, unsupported-browser, failure, fallback, diagnostics,
  and resource ownership behavior.
- Active Linux Chrome/Firefox development evidence and explicit deferred
  qualification records.
- Versioned integration fixtures and acceptance evidence for BH-03.

Renderer patching, server command authority, product components, and native
host delivery do not belong here.

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — Authorization, Handoff Reconciliation, and Boundary Activation](phase-01-authorization-handoff-reconciliation-and-boundary-activation.md) | complete — gate passed | Bound BH-02 acceptance and inherited conditions, froze the eight-phase plan, activated reusable boundaries and empty evidence locations, and proved the initial dependency/evidence boundary. | Accepted BH-02 and explicit authorization |
| [2 — Compatibility Identity, Discovery, Prerequisites, and Manifest Contract](phase-02-compatibility-identity-discovery-prerequisites-and-manifest.md) | complete — gate passed | Defined and implemented versioned runtime/host/profile identities, deterministic discovery, prerequisite detection, and fail-closed manifest validation. | Phase 1 |
| 3 — Artifact Acquisition, Runtime Startup, and Readiness | planned — unauthorized | Validate and acquire exact artifacts, start the pinned runtime, load the application bundle, and expose bounded readiness. | Phase 2 |
| 4 — Shared Runtime Registry and Independent Root Lifecycle | planned — unauthorized | Reuse one compatible runtime while roots register, mount, update, move, dispose, and remount independently. | Phase 3 |
| 5 — Shutdown, Runtime Loss, Mismatch, and Fallback | planned — unauthorized | Implement deterministic shutdown and intentional recovery/fallback paths without partial activation. | Phases 3–4 |
| 6 — Browser Profile Integration and Active-Matrix Conformance | planned — unauthorized | Compose reusable boundaries in the Phoenix development profile and execute Chrome/Firefox integration scenarios. | Phases 2–5 |
| 7 — Resource, Reliability, and Startup Measurements | planned — unauthorized | Measure root counts, readiness, memory growth, cleanup, repetition, and declared failure scenarios without promoting release budgets. | Phase 6 |
| 8 — Reconciliation, Review, and BH-03 Acceptance | planned — unauthorized | Reconcile outputs and obligations, run the complete gate, and accept, revise, or block BH-04 eligibility. | Phases 1–7 |

## Shared delivery rules

1. Obtain separate authorization before each phase.
2. Start from synchronized `main` on a `codex/` feature branch.
3. Deliver each section as one commit and each phase through one PR.
4. Preserve BH-01 and BH-02 evidence as immutable inputs.
5. Keep the reusable runtime adapter, browser host, JavaScript loader, and
   executable profile as distinct ownership boundaries.
6. A compatible page shares an appropriate runtime; roots never own or
   duplicate the runtime and cannot dispose another root.
7. Reject unknown versions, missing prerequisites, stale generations,
   integrity failures, and incompatible builds before partial activation.
8. Treat browser/runtime state as untrusted and keep renderer/server/component
   behavior outside the host lifecycle contract.
9. Keep APIs experimental and browsers unsupported until later qualification.
10. Apply the development-environment policy: unavailable platforms, devices,
    Safari, second-host, and manual assistive-technology work remains deferred.

## Milestone exit

BH-03 exits only when multiple independent roots mount, update, move, dispose,
and remount through one compatible runtime without leaked ownership; manifest,
artifact, prerequisite, startup, readiness, runtime-loss, shutdown, and
fallback paths fail intentionally; active Chrome/Firefox evidence and resource
observations reproduce; and review accepts or rejects BH-04 eligibility without
making a support or public-stability claim.

## Index

### Subdirectories

- None yet.

### Documents

- [Phase 1 — Authorization, Handoff Reconciliation, and Boundary Activation](phase-01-authorization-handoff-reconciliation-and-boundary-activation.md)
- [Phase 1 implementation evidence](phase-01-implementation-evidence.md)
- [Phase 2 — Compatibility Identity, Discovery, Prerequisites, and Manifest Contract](phase-02-compatibility-identity-discovery-prerequisites-and-manifest.md)
- [Phase 2 implementation evidence](phase-02-implementation-evidence.md)

## Maintaining this index

Add a phase document only after explicit authorization. Preserve historical
inputs, keep every acceptance condition and deferral visible, and update this
index whenever phase status or ownership changes.
