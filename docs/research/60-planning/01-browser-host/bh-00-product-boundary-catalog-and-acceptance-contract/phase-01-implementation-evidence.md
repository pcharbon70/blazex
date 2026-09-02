---
title: "Phase 1 Terminology and Architecture Decision Baseline Evidence"
kind: note
created: "2026-09-02"
maturity: developing
tags:
  - bh-00
  - implementation-evidence
  - implementation-planning
  - terminology
aliases:
  - "BH-00 phase 1 evidence"
---

# Phase 1 Terminology and Architecture Decision Baseline Evidence

## Section 1.1 — Canonical vocabulary

### Delivered artifacts

- [BlazeX canonical vocabulary](../../../20-notes/blazex-canonical-vocabulary.md)
  defines the independent architecture dimensions, product terms, rendering
  modes, WebAssembly terms, forbidden equivalences, composition examples, and
  accepted contextual uses.
- Current synthesis and boundary documents use *server integration*,
  *execution host*, *browser profile*, and *capability provider* where the prior
  wording collapsed architecture dimensions.
- The note, home map, host-neutral map, and notes index expose one navigable
  vocabulary source.

### Audit method

The section uses repeatable case-insensitive searches for overloaded phrases
including `Phoenix host`, `Plug host`, `LiveView host`, `reference host`,
`runtime host`, `hosted by Phoenix`, `DOM backend`, `component model`, and
`WebAssembly component`. Findings are reviewed in context because qualified
uses, upstream terminology, source titles, and explicit WebAssembly Component
Model references are valid.

### Section result

The canonical terms and correction ledger cover every Section 1.1 subtask.
Source notes remain historical evidence; the audit changes only current BlazeX
terminology where an architecture claim would otherwise be ambiguous.

## Remaining Phase 1 evidence

- Section 1.2 repository ownership and dependency evidence: pending.
- Section 1.3 architecture decision governance evidence: pending.
- Section 1.4 integration and phase completion evidence: pending.

## Connections

- [Phase 1 plan](phase-01-terminology-and-architecture-decision-baseline.md)
- [BH-00 plan](README.md)

## Sources

- [Host-neutral BlazeX architecture and native control backends](../../../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Elixir WebAssembly component framework for Phoenix and Plug](../../../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
