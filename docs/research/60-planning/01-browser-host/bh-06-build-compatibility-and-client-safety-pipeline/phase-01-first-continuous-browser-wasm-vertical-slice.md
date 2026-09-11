---
title: "BH-06 Phase 1 - First Continuous Browser-Wasm Vertical Slice"
kind: note
created: "2026-09-11"
maturity: developing
tags: [atomvm, bh-06, browser, build, implementation-planning, wasm]
aliases: ["BH-06 phase 1"]
---

# BH-06 Phase 1 - First Continuous Browser-Wasm Vertical Slice

Back to the [milestone](README.md).

- [ ] 1 Phase - First Continuous Browser-Wasm Vertical Slice.

  Establish the earliest executable BH-06 gate before broad build-pipeline
  implementation. Package one public Elixir component through AtomVM-in-Wasm
  and exercise the complete interaction lifecycle in both active browsers.

  Work starts from synchronized `main` at
  `aa2a4d8860f05b189a49ca3315d0d3f4a1957826` on
  `codex/bh06-phase1-browser-wasm-vertical-slice`. The owner authorized Phase 1
  on 2026-09-11 with one commit per section, one PR, merge, synchronized-main
  return, and local/remote branch deletion.

  - [x] 1.1 Section - Authorize the milestone and freeze the slice contract.
    - [x] Bind accepted BH-05 Phase 18, the roadmap, active environment policy,
      exact base, ownership, exclusions, and delivery workflow.
    - [x] Activate BH-06 planning, baseline, integration, and evidence indexes.
    - [x] Freeze the required lifecycle: mount, semantic render, browser event,
      Elixir state transition, DOM commit, disposal; reject JS-only substitutes.

  - [x] 1.2 Section - Implement deterministic candidate build primitives.
    - [x] Activate `packages/blazex_build` as an independent Mix project.
    - [x] Validate one explicit entrypoint and assemble content-addressed runtime,
      application bundle, host, HTML, and versioned manifest records.
    - [x] Reject duplicate paths, missing artifacts, path escape, mutable output,
      malformed metadata, and integrity drift with actionable diagnostics.

  - [x] 1.3 Section - Package and execute the continuous browser-Wasm slice.
    - [x] Package a public Elixir root component without private host/renderer imports.
    - [x] Load only manifest-declared assets, verify SHA-256 before startup, and
      execute the same AtomVM bundle in Linux Chrome and Firefox.
    - [x] Retain exact mount/render/event/state/DOM/disposal evidence and prove
      that a broken digest, missing asset, or JS-only result fails closed.

  - [ ] 1.4 Section - Reproduce, reconcile, and publish Phase 1 completion.
    - [ ] Run package, fixture, browser, archive, JSON, dependency, formatting,
      deterministic rebuild, historical, and patch-hygiene gates.
    - [ ] Publish commands, versions, hashes, sizes, browser observations,
      negative cases, limitations, and deferred qualifications.
    - [ ] Mark Phase 1 complete only if both active browsers pass; leave broader
      BH-06 work and BH-07 unauthorized.

## Exit gate

Equivalent inputs must produce byte-equivalent manifests and assets. Chrome
and Firefox must run the actual AtomVM WebAssembly runtime and the same packaged
Elixir component through mount, semantic render, interaction, state transition,
DOM commit, and disposal. Any JS-only component, integrity mismatch, missing
asset, private application import, or active-browser failure blocks completion.

## Connections

- [Browser milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
- [BH-05 Phase 18 completion](../bh-05-component-programming-model-and-lifecycle/phase-18-completion.md)
- [Development environment policy](../../development-environment-and-deferred-qualification-policy.md)
