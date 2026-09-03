---
title: "BlazeX BH-00 Release and BH-01 Entry Policy"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - bh-00
  - bh-01
  - product-contract
  - release-governance
aliases:
  - "BH-00 release policy"
---

# BlazeX BH-00 Release and BH-01 Entry Policy

## Decision

BH-00 publishes product-contract baseline `BX-BH00-BASELINE-0.1.0`. The
baseline is accepted as a definition, ownership, evidence, and governance
contract; it is not an implemented product release. Its bound source manifest,
review evidence, open risks, generated release index, and conditional BH-01
entry manifest form one versioned release unit.

BH-01 is `conditionally-ready`. This decision authorizes only the preparation
and later execution of a separately reviewed and explicitly approved
feasibility plan. It does not authorize project initialization, dependency
installation, framework abstraction, browser support, component support, or a
production release claim.

## Versioned contract set

The canonical governance record uses schema version `1.0.0` and contract
version `0.1.0`. Its source bindings pin the canonical vocabulary, eight
accepted architecture decisions, repository boundaries, browser support
envelope, component catalog and classification, quality contract, acceptance
registry, and browser roadmap by path and SHA-256.

The release unit contains:

- the authored governance contract and its JSON Schema;
- the multidisciplinary review and BH-01 risk register;
- the generated BH-00 release index;
- the generated BH-01 entry manifest; and
- the validators and deterministic generator that reproduce and check those
  records.

Generated Markdown is a projection, never an independent authority. A source
change makes the bound hash or generated view stale and therefore invalidates
the release until the owning record is deliberately changed, reviewed,
versioned, regenerated, and revalidated.

## Material states

The baseline distinguishes contract acceptance from delivery evidence:

- authoritative and accepted records govern semantics and ownership;
- locked records freeze an inspected source inventory at a named revision;
- proposed, candidate, deferred, and unsupported records describe future work
  without asserting successful execution;
- unimplemented, unmeasured, and unexecuted records have no product evidence;
  and
- historical or superseded records remain available for provenance.

Consequently, BH-00 acceptance does not establish a working Popcorn/AtomVM
stack, a browser compatibility matrix, implemented MudBlazor-inspired
components, passed performance budgets, production security or accessibility,
native-control parity, or release readiness. It also creates no .NET, Razor,
Blazor, MudBlazor API, package, binary, or renderer compatibility promise.

## Change and supersession

Any authoritative source change requires its accountable owner to classify the
change, update or supersede the governing decision, advance compatible contract
versions, regenerate every derivative, rerun affected validation and review,
and preserve the previous release identity and rationale.

A future baseline must explicitly name `BX-BH00-BASELINE-0.1.0` as
superseded. It must not rewrite this baseline's source manifest, review record,
risk history, or acceptance meaning. Emergency corrections still require a new
version; they are not applied silently to an already published identity.

## Conditional BH-01 entry

BH-01 may begin only when all of these conditions hold:

1. the Phase 6 pull request is merged into synchronized `main` with current
   source hashes and validation results;
2. a detailed BH-01 phased implementation plan is independently reviewed and
   explicitly approved; and
3. work begins on a dedicated branch while preserving the baseline's package
   boundaries, evidence states, proof obligations, risks, and stop conditions.

The entry manifest supplies eight required-but-unproven input groups and ten
observable proof obligations. Each proof traces to a browser-envelope claim,
an accepted architecture decision, one or more quality budgets, one or more
acceptance conditions, a repository owner, required evidence types, and a
stop-on-failure rule.

BH-01 must stop when the toolchain is not reproducible, required semantics
would force a contract redefinition, private Phoenix/LiveView coupling cannot
remain isolated, representative browser/mobile behavior is not product-viable
without bounded mitigation, or artifact origin and release properties cannot
be explained.

## Connections

- [BH-00 governance and reconciliation policy](blazex-bh-00-governance-reconciliation-policy.md)
- [BH-00 release index](../assets/bh-00-release/blazex-bh-00-release-index-v0-1-0.md)
- [BH-01 conditional entry manifest](../assets/bh-00-release/blazex-bh-01-entry-manifest-v0-1-0.md)
- [BH-00 Phase 6 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-06-governance-review-and-bh-00-acceptance.md)

## Sources

- [BH-00 governance contract](../assets/bh-00-release/blazex-bh-00-governance-v0.1.0.json)
- [BH-00 governance schema](../assets/bh-00-release/blazex-bh-00-governance.schema.json)
- [BH-00 multidisciplinary review](../assets/bh-00-release/blazex-bh-00-multidisciplinary-review-v0-1-0.md)
