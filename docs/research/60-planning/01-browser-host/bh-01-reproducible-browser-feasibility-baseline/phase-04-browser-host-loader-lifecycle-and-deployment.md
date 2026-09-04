---
title: "Phase 4 - Browser Host Loader, Lifecycle, and Deployment"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - bh-01
  - browser-host
  - implementation-planning
  - runtime-lifecycle
aliases:
  - "BH-01 phase 4"
---

# Phase 4 - Browser Host Loader, Lifecycle, and Deployment

Back to milestone: [README](README.md)

- [ ] 4 Phase - Browser Host Loader, Lifecycle, and Deployment.

  Load the governed runtime/bundle artifacts in a real browser, define explicit
  browser-host messaging and lifecycle behavior, detect prerequisites before
  activation, and document the feasibility deployment contract.

  - [x] 4.1 Section - Implement manifest-driven browser loading.

    The JavaScript loader must fetch and verify declared artifacts without
    becoming an implicit component renderer, state store, or authority layer.

    - [x] 4.1.1 Task - Build artifact acquisition and integrity checks.

      Browser loading should be controlled by the canonical manifest rather
      than hard-coded paths or opportunistic network requests.

      - [x] 4.1.1.1 Subtask - Implement manifest fetch/version validation, base URL resolution, declared asset selection, MIME/content checks, integrity verification, timeout, cancellation, and correlation.
      - [x] 4.1.1.2 Subtask - Load Wasm through the selected streaming/buffered path, verify imports/exports/features, and transfer the declared BEAM/AVM bundle and startup arguments.
      - [x] 4.1.1.3 Subtask - Reject stale/unknown manifests, undeclared redirects/assets, integrity mismatch, duplicate IDs, unsupported schema, cache poisoning, partial fetch, and post-cancel completion.

    - [x] 4.1.2 Task - Implement runtime instantiation and readiness.

      Readiness needs one observable definition that separates network,
      instantiation, bundle loading, runtime startup, and application startup.

      - [x] 4.1.2.1 Subtask - Wire only declared runtime imports, initialize memory/worker context, load the bundle, start the fixture, and emit typed lifecycle events.
      - [x] 4.1.2.2 Subtask - Record fetch, instantiate, bundle-load, runtime-ready, application-ready, and root-ready boundaries with runtime/artifact/environment identities.
      - [x] 4.1.2.3 Subtask - Fail on missing imports, trap, memory failure, bundle rejection, startup crash/timeout, readiness protocol mismatch, or duplicate readiness.

    - [x] 4.1.3 Task - Keep loader ownership narrow.

      Loader code must expose browser facilities without absorbing product
      behavior or future portable contracts.

      - [x] 4.1.3.1 Subtask - Add source/API guards against component state, DOM mutation, Phoenix authorization, LiveView data, arbitrary script execution, and unbounded host calls.
      - [x] 4.1.3.2 Subtask - Document each JavaScript operation, artifact, global/listener/worker, browser API, cleanup owner, capability prerequisite, and future replacement boundary.

  - [ ] 4.2 Section - Implement the explicit browser-host bridge.

    Browser facilities and runtime messages need schemas, generations, bounds,
    cancellation, and disposal before UI events use them.

    - [ ] 4.2.1 Task - Define host request/event protocols.

      Only the minimal BH-01 operations should cross the boundary, using
      values rather than browser object references.

      - [ ] 4.2.1.1 Subtask - Define versioned request, response, event, error, cancel, readiness, shutdown, and diagnostic envelopes with scenario/generation/correlation identity.
      - [ ] 4.2.1.2 Subtask - Bound operation allowlists, payload schema/size/depth, timeout, concurrency, sequence, backpressure, retry, and diagnostic fields.
      - [ ] 4.2.1.3 Subtask - Reject DOM/JavaScript object handles, functions/code, arbitrary URL/fetch, credentials/secrets, unknown operations, stale generations, malformed values, and late results.

    - [ ] 4.2.2 Task - Implement bridge lifecycle and observability.

      Requests and subscriptions must have deterministic ownership from start
      through cancellation, error, or disposal.

      - [ ] 4.2.2.1 Subtask - Implement correlation, timeout, cancel acknowledgement, generation invalidation, idempotent cleanup, bounded queues, and redacted traces on both sides.
      - [ ] 4.2.2.2 Subtask - Instrument pending requests, bytes/messages, listeners, workers, timers, failures, retries, stale drops, and cleanup convergence per generation.

  - [ ] 4.3 Section - Define browser-host lifecycle, failure, and teardown.

    Repeated start/stop and failure recovery must not leave hidden browser or VM
    state that makes later scenarios irreproducible.

    - [ ] 4.3.1 Task - Implement a monotonic lifecycle state machine.

      Activation transitions and legal retries need one source of truth.

      - [ ] 4.3.1.1 Subtask - Define not-started, checking, fetching, instantiating, loading, starting, ready, failed, stopping, and stopped states with legal transitions.
      - [ ] 4.3.1.2 Subtask - Assign monotonic generations, owned artifacts/resources, readiness/failure reason, retry eligibility, and observable transition traces.

    - [ ] 4.3.2 Task - Implement failure containment and retry.

      A partial activation must converge to stopped or a reviewed retry state,
      never a half-ready application.

      - [ ] 4.3.2.1 Subtask - Handle fetch/integrity/instantiate/bundle/startup/worker/bridge/runtime/application failures with one terminal outcome and bounded diagnostics.
      - [ ] 4.3.2.2 Subtask - Define which failures are retryable, required backoff/reset, cache eviction, generation change, user action, and attempt limits.
      - [ ] 4.3.2.3 Subtask - Verify stale workers/listeners/messages/artifacts cannot reanimate a stopped or replaced generation.

    - [ ] 4.3.3 Task - Implement complete teardown.

      Disposal must release browser and runtime resources even during failure or
      navigation.

      - [ ] 4.3.3.1 Subtask - Cancel pending fetches/requests/timers, detach listeners/observers, terminate workers/runtime, invalidate generations, remove owned roots, and release references.
      - [ ] 4.3.3.2 Subtask - Exercise explicit stop, page navigation/unload, profile restart, runtime crash, startup cancellation, and repeated mount/unmount.
      - [ ] 4.3.3.3 Subtask - Assert idempotence, bounded completion time, late-result rejection, and resource convergence.

  - [ ] 4.4 Section - Define prerequisites, fallback, and deployment contracts.

    Browser and server assumptions must be detected and recorded before boot so
    unsupported environments fail intentionally rather than partially.

    - [ ] 4.4.1 Task - Detect browser prerequisites before activation.

      Capability checks should identify exact missing facilities and avoid
      conflating one failed prerequisite with a supported browser claim.

      - [ ] 4.4.1.1 Subtask - Detect WebAssembly/features, workers, modules, memory/isolation, streaming, integrity, JavaScript availability, secure context, and required policies.
      - [ ] 4.4.1.2 Subtask - Map each prerequisite outcome to proceed, alternate loading, static/server fallback, explicit unavailability, or unsupported result with accessible messaging.

    - [ ] 4.4.2 Task - Specify the feasibility deployment contract.

      Hosting inputs need exact requirements even though production deployment
      support remains later work.

      - [ ] 4.4.2.1 Subtask - Record content types, compression, caching/validation, streaming/range, CSP, CORS, origin, worker, HTTPS, cross-origin isolation, integrity, source-map, and rollback requirements.
      - [ ] 4.4.2.2 Subtask - Implement profile-local verification of headers, asset reachability, manifest/artifact consistency, and stale-cache behavior before activation.
      - [ ] 4.4.2.3 Subtask - Distinguish development/test/release, direct Phoenix, reverse-proxy/CDN, unsupported hosting, and browser-managed cache differences.

  - [ ] 4.5 Section - Phase 4 Integration Tests and Completion Evidence.

    Prove repeated real-browser boot, intentional unsupported failure, lifecycle
    cleanup, and deployment checks before DOM behavior is added.

    - [ ] 4.5.1 Task - Execute boot, lifecycle, and fallback tests.

      Integration must traverse the actual profile, loader, Wasm, bundle,
      runtime, bridge, and browser state machine.

      - [ ] 4.5.1.1 Subtask - Run cold/warm/repeated boot-to-ready and stop loops in the controlled browser, verifying identities, transitions, messages, resource counts, and timing observations.
      - [ ] 4.5.1.2 Subtask - Run missing prerequisite, policy/header, network, integrity, cache, instantiate, startup, bridge, crash, navigation, retry, and disposal negative scenarios.
      - [ ] 4.5.1.3 Subtask - Evaluate the runtime-boot proof provisionally and the initial browser-fallback proof without promoting support.

    - [ ] 4.5.2 Task - Validate artifacts and publish phase evidence.

      Browser-added artifacts and deployment requirements must join the
      canonical manifest with no unexplained output or hidden fetch.

      - [ ] 4.5.2.1 Subtask - Validate loader/worker/JavaScript/maps/manifests/licenses, artifact hashes/sizes/reachability, network logs, headers, caches, and deterministic generation.
      - [ ] 4.5.2.2 Subtask - Publish Phase 4 evidence with revisions, commands, browser/profile fingerprint, lifecycle/fallback traces, deployment contract, artifacts, findings, risks, and stop/go decision.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase only after the final integration section passes or records a
truthful stop decision. Do not begin DOM behavior on a loader that cannot fail
and dispose deterministically.

## Connections

- [BH-01 plan](README.md)
- [Phase 3](phase-03-runtime-build-and-beam-packaging.md)
- [Browser trust, deployment, and fallback policy](../../../20-notes/blazex-browser-trust-deployment-and-fallback-policy.md)

## Sources

- [Browser product envelope](../../../assets/browser-product-envelope-v0.1.json)
