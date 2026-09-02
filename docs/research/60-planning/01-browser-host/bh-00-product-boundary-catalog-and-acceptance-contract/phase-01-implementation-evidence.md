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

## Section 1.2 — Repository ownership and dependency direction

### Delivered artifacts

- [BlazeX repository ownership and dependency
  map](../../../10-maps/blazex-repository-ownership-and-dependency-map.md)
  assigns all eighteen package boundaries, three executable profiles, the
  browser JavaScript bridge, three integration suites, and the bounded native
  experiment one primary responsibility.
- The map defines class-level dependency rules, valid browser/Phoenix,
  browser/Plug, and headless graphs, ten invalid edges or collapses, future
  package admission requirements, and experiment promotion/retirement rules.
- The repository root, home map, host-neutral map, and maps index link the
  ownership record without duplicating it as a second source of truth.

### Inventory consistency method

The package table is compared with the direct child directories of `packages/`;
the profile table is compared with `profiles/`; and every integration,
JavaScript, and experiment path is checked for existence. Review also exercises
the three valid composition graphs and each invalid edge in the map.

### Section result

Every current monorepo boundary has exactly one primary owner. Profiles remain
outer compositions, standalone DOM remains independent from LiveView, the Plug
graph excludes Phoenix/LiveView transitively, and future native or non-browser
packages remain illustrative.

## Section 1.3 — Durable architecture decision governance

### Delivered artifacts

- The [architecture decision
  register](../../../20-notes/architecture-decisions/README.md) assigns eight
  permanent IDs to the BH-00 architecture baseline and records every decision
  as accepted.
- [ADR-0001](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md),
  [ADR-0002](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md),
  [ADR-0003](../../../20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md),
  [ADR-0004](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md),
  [ADR-0005](../../../20-notes/architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md),
  [ADR-0006](../../../20-notes/architecture-decisions/adr-0006-profile-composition.md),
  [ADR-0007](../../../20-notes/architecture-decisions/adr-0007-native-control-portability-gate.md),
  and [ADR-0008](../../../20-notes/architecture-decisions/adr-0008-no-dotnet-compatibility-contract.md)
  record scope, owners, status, rationale, consequences, alternatives,
  compatibility, security, accessibility, packaging, cross-backend impact,
  unresolved evidence, and supersession metadata.
- The reusable [ADR
  template](../../../templates/architecture-decision.md) and corpus governance
  rules establish one durable location and format for later decisions.

### Governance and review method

Decision IDs are permanent and never reused. Proposed, under-review, accepted,
rejected, deprecated, superseded, and archived states preserve history.
Acceptance requires named architecture, product, and specialist role owners,
linked evidence, the complete impact review, resolved blocking findings, and a
register update. A material change supersedes an accepted ADR rather than
silently rewriting it.

Changes to a decision update affected roadmaps, catalog and support records,
maps, package/profile boundaries, schemas, provenance records, and acceptance
evidence in the same reviewed change. Review is triggered when executable
evidence contradicts an assumption, an architecture axis is added, a support
promise changes, an impact changes, or a forbidden dependency is proposed.

### Section result

Every boundary assumed by later BH-00 phases now has a permanent decision ID,
accepted status, accountable role owners, explicit impact analysis, unresolved
proof obligations, and a review/supersession path. The records describe the
architecture baseline without claiming that runtime or component code exists.

## Remaining Phase 1 evidence

- Section 1.4 integration and phase completion evidence: pending.

## Connections

- [Phase 1 plan](phase-01-terminology-and-architecture-decision-baseline.md)
- [BH-00 plan](README.md)

## Sources

- [Host-neutral BlazeX architecture and native control backends](../../../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Elixir WebAssembly component framework for Phoenix and Plug](../../../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
