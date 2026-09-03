---
title: "Taffy and Yoga embeddable UI layout engines"
kind: source
created: "2026-09-03"
authors:
  - "Dioxus Labs and Taffy contributors"
  - "Meta and Yoga contributors"
published: null
citation_key: "dioxuslabs-meta-2026-taffy-yoga-layout"
container: "Taffy and Yoga documentation and source"
edition: "Taffy 0.14.0; Yoga 3.2.1"
isbn: null
doi: null
url: "https://docs.rs/crate/taffy/0.14.0"
accessed: "2026-09-03"
tags:
  - desktop
  - layout
  - rust
  - ui-framework
aliases:
  - "Cross-platform layout engine evidence"
---

# Taffy and Yoga embeddable UI layout engines

## Reference

Dioxus Labs and Taffy contributors. [Taffy
0.14.0](https://docs.rs/crate/taffy/0.14.0) and [project
repository](https://github.com/DioxusLabs/taffy). Meta and Yoga contributors.
[Yoga project](https://github.com/facebook/yoga) and [Yoga
documentation](https://www.yogalayout.dev/). Evidence baseline: Taffy 0.14.0,
released 2026-08-24, and Yoga 3.2.1. Accessed 2026-09-03.

## Research question or contribution

Can BlazeX reuse a cross-platform engine for renderer-local layout and
intrinsic measurement rather than inventing complete geometry rules?

## Findings

- Taffy is a Rust UI-layout library that implements CSS-derived Block,
  Flexbox, and Grid algorithms. It accepts a tree, styles, available space,
  and measurement callbacks, and returns positions and sizes. Its low-level
  API is intended for embedding in frameworks with their own node storage.
- Taffy explicitly does not perform text layout; the embedding framework must
  supply measurement callbacks and cache invalidation. C and Wasm bindings
  were still described as works in progress at the evidence baseline.
- Yoga is an embeddable C++20 Flexbox engine with multiple language bindings
  and generated layout tests. Its scope is narrower than Taffy's Block/Grid
  coverage.
- Neither engine supplies scrolling behavior, hit testing, pointer capture,
  focus traversal, virtualized realization, accessibility, native-control
  intrinsic sizing, or window integration.

## Relevance

Taffy is the leading Rust layout spike for the custom-scene host; Yoga is the
leading narrower C++ comparison. BlazeX still needs its own semantic layout
vocabulary and a renderer-local geometry/hit-test layer so CSS-derived engine
types do not become the portable component ABI.

## Limits

No layout engine was built or compared with native toolkit geometry. The
projects evolve quickly; the recorded versions, not mutable `main`, are the
evidence baseline. Web-derived conformance does not guarantee native-control
measurement or platform typography parity.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Native renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md)

