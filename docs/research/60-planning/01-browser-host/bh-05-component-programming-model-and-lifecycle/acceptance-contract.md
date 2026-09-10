---
title: "BH-05 Final Measurement and Acceptance Contract"
kind: note
created: "2026-09-10"
maturity: developing
tags:
  - acceptance
  - benchmarks
  - bh-05
aliases: []
---

# BH-05 Final Measurement and Acceptance Contract

Back to [milestone](README.md) and [Phase 12](phase-12-reliability-measurement-review-and-bh-05-acceptance.md).

## Frozen candidate

Phase 12 starts at merged Phase 11 revision
`23446e711d5791eb6eea0b23dd6fdcde3bebc62e`. The generated
[authorization](../../../assets/bh-05-baseline/acceptance-authorization-v0.1.0.json)
binds all eleven predecessor completion/gate records, the canonical quality and
acceptance inputs, public conformance corpus/results, roadmap, host-neutral ADR,
dependency map, and deferral policies. The canonical acceptance registry is an
immutable planned input; Phase 12 publishes a versioned outcome overlay.

## Measurements

The six budgets retain their canonical thresholds: event backlog maximum 256,
pending effects maximum 128, simultaneous leases maximum 512, automatic
restarts maximum three in any five-second window, disposal-to-release p95 at
most 1000 ms, and unexpected live-process growth exactly zero after one hundred
root lifecycle cycles. Count/restart series require at least 20 samples, cleanup
requires 100, and process growth requires ten independent 100-cycle samples.

Each series performs one unmeasured warmup. Every subsequent sample is retained.
Counts use the maximum; cleanup uses nearest-rank p95. Durations use monotonic
milliseconds from disposal request through the last terminal owner release.
Inventories are correlated by root, generation, action/resource identity and
terminal state. The measurement runner, one LocalView supervisor, and the
browser's shared AtomVM/Popcorn service are declared persistent baseline
services; component workers, timers, requests, leases and renderer surfaces are
never excluded.

ERTS/headless is the controlled quantitative reference. Linux Chrome and
Firefox execute the applicable fixed AtomVM observations and must agree on
portable counts, terminal state and failure behavior. Browser wall-clock and
process implementation details remain diagnostic variation, not product
performance qualification. GTK remains a portability-only row.

## Decision rule

Acceptance requires all six budgets, both named failure gates, and the BH-05
roadmap outcome to pass with fresh evidence and no active blocker. A bounded
condition must name its owner, due milestone, trigger and forbidden inference.
Any active leak, unbounded admission/retry, stale mutation, cross-root impact,
private public-fixture dependency or semantic ERTS/AtomVM divergence forces
`revise` or `block`. Thresholds, fixtures, samples and scopes cannot be changed
after measurement to manufacture a pass.

An accepted outcome makes BH-06 eligible but never authorized. General build
reachability, component families/forms/navigation, Phoenix/Plug transport,
prerender/activation, public 1.0 stability and release support remain later work.
Windows, macOS, Safari/WebKit product qualification, physical mobile devices and
unavailable manual assistive-technology pairings remain `[DEFERRED]` to BH-22.
LiveView and LocalLiveView remain separately deferred by owner direction.
