---
title: "Phase 2 - Browser Product and Support Envelope"
kind: note
created: "2026-09-02"
maturity: developing
tags:
  - bh-00
  - browser
  - implementation-planning
  - product-contract
aliases:
  - "BH-00 phase 2"
---

# Phase 2 - Browser Product and Support Envelope

Back to milestone: [README](README.md)

- [ ] 2 Phase - Browser Product and Support Envelope.

  Define exactly which browser product BlazeX intends to prove, what each
  rendering and server-integration claim means, and which prerequisites,
  fallbacks, and trust boundaries constrain those claims before BH-01 selects
  and measures exact dependency builds.

  - [x] 2.1 Section - Define the initial browser and toolchain support policy.

    Establish a bounded candidate envelope that BH-01 can prove or reject
    without presenting unverified version combinations as supported releases.

    - [x] 2.1.1 Task - Specify browser and device support claims.

      The product contract must identify browser families, version-policy
      semantics, device classes, and evidence freshness without promising every
      WebAssembly-capable environment.

      - [x] 2.1.1.1 Subtask - Define candidate Chromium, Firefox, and WebKit support policies using stable release channels, minimum-version rules, and explicit review cadence.
      - [x] 2.1.1.2 Subtask - Define representative desktop, mobile, memory, CPU, network, input, zoom, contrast, direction, and assistive-technology evidence classes.
      - [x] 2.1.1.3 Subtask - Define unsupported, best-effort, preview, and supported statuses plus the evidence required to promote or remove a browser configuration.

    - [x] 2.1.2 Task - Specify the candidate toolchain envelope.

      Toolchain scope must name every moving layer and distinguish a candidate
      range from the exact reproducible pins that BH-01 will establish.

      - [x] 2.1.2.1 Subtask - Inventory Phoenix, LiveView, LocalLiveView, Popcorn, AtomVM, Elixir, Erlang/OTP, Mix, JavaScript tooling, browser, and operating-system inputs that affect the profile.
      - [x] 2.1.2.2 Subtask - Define candidate, pinned, tested, supported, deprecated, and blocked meanings for toolchain combinations and private API dependencies.
      - [x] 2.1.2.3 Subtask - Define lockfile, artifact, provenance, rebuild, security-update, and support-matrix records BH-01 must produce before any candidate becomes supported.

  - [x] 2.2 Section - Define rendering and server-integration modes.

    Give every output and activation term an observable meaning while keeping
    browser rendering independent from Phoenix, Plug, and LiveView.

    - [x] 2.2.1 Task - Specify rendering and activation claims.

      Each mode must state where component logic runs, who owns the rendered
      surface, what output exists before activation, and how failure appears.

      - [x] 2.2.1.1 Subtask - Define static fallback, server-rendered output, prerendered output, browser-local interactive output, activated output, and headless output.
      - [x] 2.2.1.2 Subtask - Specify identity, public state, effects, event ownership, focus, accessibility, mismatch, replacement, and disposal expectations for each mode.
      - [x] 2.2.1.3 Subtask - Define which modes are BH-00 vocabulary, which are browser 1.0 commitments, and which remain conditional on later milestone evidence.

    - [x] 2.2.2 Task - Specify profile and server-adapter claims.

      Phoenix-first delivery must not redefine the browser as a Phoenix host or
      make the standalone DOM renderer depend on LiveView.

      - [x] 2.2.2.1 Subtask - Define the browser/Phoenix profile, Phoenix server adapter, optional LiveView DOM adapter, browser/Plug profile, Plug server adapter, and headless profile independently.
      - [x] 2.2.2.2 Subtask - Publish a capability matrix for static delivery, bootstrap, sessions, CSRF, typed commands, pushes, realtime, uploads, navigation, prerender, activation, and telemetry by profile.
      - [x] 2.2.2.3 Subtask - State which Phoenix facilities are absent, optional, or separately replaceable in Plug and require a transitive-dependency audit for the Plug claim.

  - [ ] 2.3 Section - Define trust, deployment, and fallback boundaries.

    Product support must include the security and deployment conditions under
    which local browser execution is allowed, denied, or degraded intentionally.

    - [ ] 2.3.1 Task - Establish the browser and server trust contract.

      Client code, state, manifests, commands, and capability results remain
      untrusted even when the component logic is authored in Elixir.

      - [ ] 2.3.1.1 Subtask - Define public bootstrap state, trusted server state, local events, remote commands, authentication projection, authorization, validation, audit, and replay or idempotency boundaries.
      - [ ] 2.3.1.2 Subtask - Define capability grants, origin and CSRF policy, content integrity, secret exclusion, command schema, server revalidation, and safe diagnostic redaction claims.
      - [ ] 2.3.1.3 Subtask - State that local visibility, disabled state, cached state, or WebAssembly execution never constitutes authorization or trusted mutation evidence.

    - [ ] 2.3.2 Task - Establish deployment prerequisites and fallback policy.

      Hosts need deterministic behavior when browser, header, transport, asset,
      runtime, or build requirements are unavailable or incompatible.

      - [ ] 2.3.2.1 Subtask - Inventory HTTPS, MIME, CSP, cross-origin isolation, COOP/COEP, caching, compression, integrity, worker, storage, and transport prerequisites by claimed mode.
      - [ ] 2.3.2.2 Subtask - Define capability detection, incompatible-build, no-JavaScript, unsupported-browser, unavailable-runtime, network-loss, and server-loss fallback categories.
      - [ ] 2.3.2.3 Subtask - Require every fallback to preserve bounded content, accessibility, security, diagnostics, retry, cleanup, and truthful support messaging.

  - [ ] 2.4 Section - Phase 2 Integration Tests.

    Prove that support, rendering, profile, trust, deployment, and fallback
    records form one bounded browser-product envelope without claiming BH-01
    feasibility evidence.

    - [ ] 2.4.1 Task - Validate support matrices and cross-record consistency.

      Machine checks and scenario review must reject missing cells, contradictory
      mode definitions, adapter conflation, and unsupported implied guarantees.

      - [ ] 2.4.1.1 Subtask - Validate every browser, toolchain, rendering mode, profile, server feature, deployment prerequisite, and fallback status against its declared vocabulary and evidence state.
      - [ ] 2.4.1.2 Subtask - Exercise paper scenarios for Phoenix, Plug, headless, unsupported browser, missing cross-origin isolation, network loss, incompatible deployment, and no-JavaScript output.
      - [ ] 2.4.1.3 Subtask - Audit the matrices for accidental native-host, full OTP, general Wasm AOT, WebAssembly Component Model, or .NET compatibility claims.

    - [ ] 2.4.2 Task - Record completion evidence and deliver the phase.

      Phase completion requires reviewed product records and explicit unknowns,
      not successful local execution or speculative version recommendations.

      - [ ] 2.4.2.1 Subtask - Record support-envelope revisions, matrix validation output, security review, deployment review, unresolved feasibility risks, and assumptions assigned to BH-01.
      - [ ] 2.4.2.2 Subtask - Confirm no dependency was selected as supported, no runtime artifact was built, and no browser demonstration was counted as Phase 2 completion evidence.
      - [ ] 2.4.2.3 Subtask - Complete one commit per coherent section and open the Phase 2 PR without starting the catalog inventory.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase; do not merge without a later request.
