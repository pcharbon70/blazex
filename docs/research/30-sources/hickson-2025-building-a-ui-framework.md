---
title: "Building a UI Framework"
kind: source
created: "2026-09-03"
authors:
  - "Ian Hickson"
published: 2025
citation_key: "hickson-2025-building-ui-framework"
container: "Independent technical report"
edition: "First edition"
isbn: null
doi: null
url: "https://software.hixie.ch/ui-frameworks.pdf"
accessed: "2026-09-03"
tags:
  - accessibility
  - architecture
  - performance
  - ui-framework
aliases:
  - "Hixie UI framework report"
---

# Building a UI Framework

## Reference

Ian Hickson. [*Building a UI Framework*](https://software.hixie.ch/ui-frameworks.pdf),
first edition, 2025.

## Research question or contribution

Which system-level tradeoffs matter when creating a graphical UI framework,
beyond selecting a drawing API?

## Method

The report is an expert technical survey organized around developer adoption,
performance, display effects, and power consumption. It examines framework
design choices and implementation consequences rather than evaluating BlazeX
or one toolkit experimentally.

## Findings

- Layout, input, focus, keyboard behavior, text, accessibility, animation,
  rendering, scheduling, and developer tooling form an interdependent system.
- Performance choices include retained data, invalidation, batching, caching,
  frame scheduling, and avoiding unnecessary work—not merely choosing GPU
  APIs.
- Accessibility and keyboard/focus semantics need framework-level ownership
  and platform mapping.
- A framework's supported platforms, extension boundaries, test strategy,
  documentation, and compatibility policy materially affect adoption and
  maintainability.

## Relevance

The report supports treating BlazeX's native host as a collection of explicit
contracts and budgets. It is most useful as a design checklist and
counterweight to a graphics-only architecture.

## Limits

This is not a peer-reviewed comparative study, and its broad recommendations
do not select SDL, Skia, AccessKit, a toolkit, or a BEAM integration path.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
