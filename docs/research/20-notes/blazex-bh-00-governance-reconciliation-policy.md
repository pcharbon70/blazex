---
title: "BlazeX BH-00 Governance and Reconciliation Policy"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - architecture-governance
  - bh-00
  - product-contract
  - reconciliation
aliases:
  - "BH-00 governance policy"
---

# BlazeX BH-00 Governance and Reconciliation Policy

## Decision

BH-00 closes through one source-bound governance contract rather than an
informal assertion that its six phases look complete. The contract binds the
canonical vocabulary, eight accepted ADRs, repository ownership map, browser
support envelope, catalog, classification, quality contract, acceptance graph,
and browser roadmap by path and SHA-256.

Every binding names whether it is an authoritative record or authoritative
index. Generated reports are deliberately excluded as independent authorities;
their freshness is checked against authored sources and generators.

## Reconciliation order

Governance reconciliation proceeds from inner contracts outward:

1. canonical terms and forbidden equivalences;
2. accepted architecture decisions and independent axes;
3. package ownership and dependency direction;
4. profile and adapter composition;
5. browser support, trust, deployment, and fallback claims;
6. source catalog and product classification;
7. quality budgets and cross-cutting gates;
8. acceptance coverage and evidence states; and
9. roadmap and release language.

A derivative report never wins a conflict. The owning authoritative record is
updated, reviewed, versioned, and explicitly superseded first; schemas,
generators, indexes, maps, and acceptance links then change atomically.
Historical rationale is retained.

## Independent architecture axes

The reconciled contract preserves six independent axes:

- **Runtime substrate** executes eligible application logic. AtomVM-in-Wasm
  through Popcorn is one candidate adapter, not the product definition.
- **Execution host** owns process/application lifecycle in a browser, test
  process, native process, or another embedding.
- **Renderer backend** lowers semantic UI to DOM, native widgets, a custom
  scene, or headless output.
- **Capability provider** implements explicitly granted host facilities behind
  opaque effects and resources.
- **Server adapter** connects to Phoenix, Plug, another server, or no server.
- **Profile composition** selects one coherent combination and deployment
  shell without becoming the universal framework root.

No axis may redefine portable component semantics. Runtime, host, renderer,
capability, server, and profile compatibility therefore require separate
identities and evidence.

## Package and profile boundaries

All eighteen package directories remain scaffolds with no `mix.exs`, JavaScript
package, lockfile, dependency installation, or implementation source. Each has
one bounded owner axis recorded in the governance contract.

The critical replaceability constraints are:

- `blazex_core`, `blazex_ui_tree`, and `blazex_effects` contain no browser,
  DOM, JavaScript, Phoenix, Plug, Popcorn, or native-toolkit object contracts;
- `blazex_renderer` defines the backend contract but no concrete backend;
- `blazex_renderer_dom` contains no Phoenix, LiveView, LocalLiveView, or Plug
  dependency;
- all LiveView/LocalLiveView renderer coupling stays in
  `blazex_renderer_dom_liveview`;
- `blazex_host_browser` implements browser capabilities without requiring a
  server framework;
- `blazex_phoenix` and `blazex_plug` remain separate server adapters;
- the Plug package/profile excludes Phoenix, LiveView, LocalLiveView, and the
  LiveView DOM adapter transitively; and
- `blazex_renderer_headless` remains usable without browser/server/native
  packages.

The browser/Phoenix profile is the first reference composition. It is not the
container for reusable behavior. Browser/Plug and headless are separately
identified product/test compositions whose evidence cannot be inherited from
Phoenix.

## Catalog, quality, and acceptance truth

The final reconciled counts are treated as governed invariants:

- 83 locked source families and twelve source-closure exceptions;
- 83 complete product classifications with separate disposition, tier,
  package, capability, fallback, remote, portability, native, visual, and
  future-backend fields;
- 31 proposed/unmeasured budgets, eight failure scenarios, seven unwaivable
  blockers, four cross-cutting gates, and 21 gate requirements; and
- 290 source requirements and 290 reciprocal acceptance conditions covering
  all families, milestones, profiles, packages, budgets, gates, failures,
  blockers, cross-cutting obligations, envelope records, and non-goals.

Accepted classification and planned acceptance are contract states, not
implementation evidence. All implementation, browser, benchmark,
accessibility, security, deployment, and release evidence remains unexecuted.

## Compatibility and support boundaries

BlazeX targets semantically comparable product outcomes, not .NET ecosystem
compatibility. No record may promise .NET, Razor, Blazor binary, MudBlazor API,
NuGet, package, renderer, or visual parity.

Likewise, browser or headless evidence cannot establish desktop, WebView,
native-process, native-control, standalone-Wasm, WASI, or Component Model
support. BH-02's native-control spike is a disposable portability test. A
production host/backend needs a new profile decision and its own conformance,
accessibility, capability, fallback, packaging, and support evidence.

All current browser configurations remain unsupported and unproven. The
toolchain is candidate/unresolved. Quality values are proposed thresholds.
BH-00 acceptance can authorize feasibility work but cannot authorize product
support language.

## Conflict handling

A reconciliation check records stable ID, domain, assertion, authoritative
source references, method, outcome, conflicts, and resolution. A passing check
requires zero unresolved conflict. If a conflict exists:

1. stop the affected acceptance/release decision;
2. identify the authority owner and downstream derivatives;
3. write an explicit correction or superseding decision;
4. regenerate and revalidate every dependent artifact;
5. preserve the prior record and rationale; and
6. record review evidence before changing the check to passed.

Silently editing generated JSON/Markdown, changing only an index, or weakening
a claim to make validators pass is prohibited.

## Stage and evidence semantics

The governance contract advances through four stages:

| Stage | Meaning |
| --- | --- |
| `section-6.1` | Sources, architecture, packages, profiles, and reconciliation are complete; multidisciplinary review has not run. |
| `section-6.2` | Review findings and feasibility risks are dispositioned; release identity and BH-01 decision remain unset. |
| `section-6.3` | Versioned release/index and conditional BH-01 entry decision are prepared. |
| `complete` | Final Phase 1–6 validation and acceptance evidence pass. |

Contract evidence IDs attest only to documentation/reconciliation/review work.
They cannot appear in the Phase 5 runtime/product acceptance conditions and
cannot establish browser or component support.

## Connections

- [Canonical vocabulary](blazex-canonical-vocabulary.md)
- [Repository ownership and dependency map](../10-maps/blazex-repository-ownership-and-dependency-map.md)
- [Browser host implementation milestones](browser-host-implementation-milestones.md)
- [BH-00 Phase 6 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-06-governance-review-and-bh-00-acceptance.md)

## Sources

- [BH-00 governance schema](../assets/bh-00-release/blazex-bh-00-governance.schema.json)
- [BH-00 governance contract](../assets/bh-00-release/blazex-bh-00-governance-v0.1.0.json)
- [Acceptance registry](../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
