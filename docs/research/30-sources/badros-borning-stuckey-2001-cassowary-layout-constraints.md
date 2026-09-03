---
title: "The Cassowary Linear Arithmetic Constraint Solving Algorithm"
kind: source
created: "2026-09-03"
authors:
  - "Greg J. Badros"
  - "Alan Borning"
  - "Peter J. Stuckey"
published: 2001
citation_key: "badros-borning-stuckey-2001-cassowary"
container: "ACM Transactions on Computer-Human Interaction"
edition: null
isbn: null
doi: "10.1145/504704.504705"
url: "https://constraints.cs.washington.edu/solvers/cassowary-tochi.pdf"
accessed: "2026-09-03"
tags:
  - constraints
  - layout
  - research-paper
  - ui-framework
aliases:
  - "Cassowary UI layout paper"
---

# The Cassowary Linear Arithmetic Constraint Solving Algorithm

## Reference

Greg J. Badros, Alan Borning, and Peter J. Stuckey. “The Cassowary Linear
Arithmetic Constraint Solving Algorithm.” *ACM Transactions on Computer-Human
Interaction* 8, no. 4 (2001): 267–306.
[doi:10.1145/504704.504705](https://doi.org/10.1145/504704.504705).
[Author PDF](https://constraints.cs.washington.edu/solvers/cassowary-tochi.pdf).

## Research question or contribution

How can a UI system incrementally maintain required and preferred linear
equalities and inequalities at interactive speed?

## Method

The paper develops an incremental dual-simplex constraint algorithm, defines
constraint strengths/preferences, describes implementations, and reports
performance on UI-oriented workloads.

## Findings

- Linear equalities and inequalities naturally express relationships such as
  alignment, containment, minimum size, and relative position.
- Incremental solving avoids recomputing an unrelated full geometry system
  after each edit and supports required versus preferred constraints.
- Cassowary is a constraint solver, not a complete block, flex, grid, text,
  scrolling, or hit-testing engine.

## Relevance

Cassowary is a credible specialized option for panes, splitters, overlays, and
relationships that do not fit stack/grid rules. It should not silently become
BlazeX's universal layout algorithm; the renderer still owns measurement,
flow, scrolling, clipping, and hit testing.

## Limits

The original implementations and measurements are old relative to current
hardware and UI stacks. The paper does not compare Taffy, Yoga, modern
toolkits, or complex text and does not select a BlazeX implementation.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Native renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md)
