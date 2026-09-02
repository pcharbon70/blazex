---
title: "Phase 1 Terminology and Architecture Decision Baseline Evidence"
kind: note
created: "2026-09-02"
maturity: stable
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

## Section 1.4 — Integration and phase completion evidence

### Reproducible verification

| Check | Command or method | Result |
| --- | --- | --- |
| Corpus structure, metadata, indexes, links, and connections | `cd docs/research && python3 validate_archive.py` | Passed: 76 completed documents, 14 directories, 467 local links, and 28 source notes. |
| Validator regression suite | `cd docs/research && python3 -m unittest test_validate_archive.py` | Passed: 8 tests. |
| Patch hygiene | `git diff --check` | Passed with no whitespace errors. |
| Package inventory | Compare direct `packages/` children with the ownership-table package column | Exact 18-to-18 match; no duplicate or missing package. |
| Profile inventory | Compare direct `profiles/` children with the ownership-table profile column | Exact 3-to-3 match; no duplicate or missing profile. |
| Referenced boundary paths | Test every package, profile, bridge, integration, and experiment path named by the ownership map | All 26 paths exist. |
| ADR register | Count `adr-*.md`, accepted status rows, and stable maturity values | 8 files, 8 accepted statuses, and 8 stable records. |
| Project/runtime absence | Search package, profile, JavaScript, integration, and experiment trees for Mix/JavaScript manifests, Elixir/JavaScript/TypeScript sources, Wasm modules, and BEAM files | Zero matches. |

### Terminology audit and exceptions

Case-insensitive searches covered `Phoenix host`, `Plug host`, `LiveView host`,
`reference host`, `runtime host`, `hosted by Phoenix`, `DOM backend`,
`component model`, and `WebAssembly component` across the root, research,
planning, package, profile, integration, JavaScript, and experiment Markdown.
The audit corrected residual positive uses of *Plug hosting*, *LiveView
hosting*, *runtime host contracts*, and unqualified *DOM backend*.

Remaining matches are accepted only when they are:

- explicit anti-examples or correction-ledger entries in the canonical
  vocabulary and this evidence record;
- negative requirements such as “must not redefine the browser as a Phoenix
  host” in a future plan;
- qualified references to the WebAssembly Component Model; or
- historical document titles and upstream terminology retained for traceability.

No positive current-architecture claim collapses Phoenix, Plug, LiveView, a
runtime, or a renderer into the BlazeX execution-host or component contract.

### Dependency-graph review

The review exercised the browser/Phoenix, browser/Plug, and headless valid
graphs plus their forbidden reverse edges. Standalone DOM remains independent;
LiveView lowering remains optional and isolated; Plug excludes Phoenix,
LiveView, LocalLiveView, and the LiveView DOM adapter; headless excludes browser
and server frameworks; and the future native proof remains an experiment with
no production-profile dependency. The future-package gate requires a later ADR,
owner, dependency analysis, profile, capability policy, and conformance proof.

### Review and revision record

- Section 1.1 glossary revision: `e3d0bf3`.
- Section 1.2 ownership/dependency revision: `1f7f1f7`.
- Section 1.3 decision-governance revision: `1cc223d`.
- Phase delivery: [PR #4](https://github.com/pcharbon70/blazex/pull/4), containing
  one final commit for each of Sections 1.1 through 1.4.
- Implementation and consistency review: Codex under the repository owner's
  instruction; the owner authorized one PR and immediate merge for this phase.
- Independent second-party review: not requested for Phase 1; the broader BH-00
  independent-review gate remains in Phase 6.

### Scope confirmation

The phase introduced Markdown research, planning, decisions, templates, maps,
and evidence only. It introduced no Mix project, Mix lockfile, JavaScript
project, package-manager lockfile, Elixir/JavaScript/TypeScript implementation,
Wasm or BEAM artifact, runtime proof, component implementation, or BH-01
dependency/version pin. Phase 2 product-envelope work has not begun.

### Unresolved proof obligations

- BH-01 must pin and prove the actual browser runtime/toolchain stack.
- BH-02 must prove the kernel, semantic tree, effects, and renderer contracts
  through headless, standalone DOM, and actual native controls.
- Later BH-00 phases must define the support envelope, exhaustive catalog,
  capability/fallback classifications, quality budgets, and acceptance matrix.
- Phase 6 must perform the independent contract review and decide whether BH-01
  entry is authorized or blocked.

### Section result

All local integration checks pass, the Phase 1 artifacts agree on one
host-neutral architecture, and the single Phase 1 PR is open without Phase 2
work. Section 1.4 and Phase 1 are complete.

## Connections

- [Phase 1 plan](phase-01-terminology-and-architecture-decision-baseline.md)
- [BH-00 plan](README.md)

## Sources

- [Host-neutral BlazeX architecture and native control backends](../../../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Elixir WebAssembly component framework for Phoenix and Plug](../../../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
