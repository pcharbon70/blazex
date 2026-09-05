---
title: "BH-01 Compatibility and Limitations Index"
kind: map
created: "2026-09-05"
tags:
  - bh-01
  - generated-index
  - feasibility
aliases:
  - "BH-01 Compatibility and Limitations Index generated view"
---

# BH-01 Compatibility and Limitations Index

> Generated from `BX-BH01-FEASIBILITY-BASELINE-0.1.0` (`2e8f96b2afe2e139543c898249161b8e5794a4876eccd8bac679a4347e1134ff`). Edit canonical evidence, not this view.

## Active observed environments

- `BX-BH01-ENV-LINUX-CHROME` — Chrome for Testing 152.0.7977.75: observed-unsupported
- `BX-BH01-ENV-LINUX-FIREFOX` — Playwright Firefox 153 development build: observed-unsupported

## Limitations

- Both authoritative clean executions used one physical Linux x86-64 host.
- Chrome and the Firefox development binary are observed development environments and remain unsupported.
- The unpruned application AVM fails decoded and compressed application payload budgets.
- Firefox development timer-event p95 exceeds the active local-event target.
- Representative Chrome timing reruns retain scheduler-sensitive drift.
- Private LiveView and LocalLiveView compatibility is exact-pins-only with standalone DOM fallback.
- Popcorn requires unsafe-eval and production security controls are not implemented.
- Physical mobile, Safari, Windows, second-machine, and manual assistive-technology qualification is deferred to BH-22.
- Mobile viability, accessibility conformance, production deployment, native compatibility, and release readiness are not established.
- BH-01 fixtures and protocols are disposable evidence rather than stable BlazeX APIs.

## Connections

- [BH-01 plan](../../60-planning/01-browser-host/bh-01-reproducible-browser-feasibility-baseline/README.md)
