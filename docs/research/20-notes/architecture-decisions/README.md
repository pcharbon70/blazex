---
title: "Architecture Decisions"
kind: map
created: "2026-09-02"
tags:
  - architecture-decision
  - archive-navigation
  - directory-index
aliases:
  - "BlazeX ADR register"
---

# Architecture Decisions (`architecture-decisions`)

## Purpose

This directory contains permanent architecture decision records for BlazeX.
The records turn accepted research conclusions into stable choices with named
impacts, review triggers, and supersession history.

## What belongs here

- One ADR per durable architecture or product-boundary decision.
- Accepted, proposed, rejected, deprecated, and superseded decisions whose
  history remains relevant.
- Explicit compatibility, security, accessibility, packaging, dependency, and
  cross-backend impact analysis.

Exploratory synthesis remains in `20-notes`; open questions remain in
`40-inquiries`; implementation sequencing remains in `60-planning`. ADRs do not
claim that an implementation or support matrix exists.

## Decision register

| ID | Decision | Status | Primary owners |
| --- | --- | --- | --- |
| ADR-0001 | [Host-neutral semantic component kernel](adr-0001-host-neutral-semantic-component-kernel.md) | accepted | architecture and component-kernel stewards |
| ADR-0002 | [Versioned semantic UI tree](adr-0002-versioned-semantic-ui-tree.md) | accepted | architecture, UI-tree, and renderer-contract stewards |
| ADR-0003 | [Effects, capabilities, and resources remain host-neutral](adr-0003-host-neutral-effects-capabilities-and-resources.md) | accepted | architecture, effects, and host-adapter stewards |
| ADR-0004 | [Renderer backends are separate and LiveView lowering is optional](adr-0004-renderer-backend-separation.md) | accepted | renderer and integration stewards |
| ADR-0005 | [Server adapters remain outside the component trust boundary](adr-0005-server-adapter-and-trust-boundary.md) | accepted | security, server-integration, and component stewards |
| ADR-0006 | [Executable profiles compose independent axes](adr-0006-profile-composition.md) | accepted | architecture, release, and profile stewards |
| ADR-0007 | [Native-control portability proof precedes API stability](adr-0007-native-control-portability-gate.md) | accepted | architecture, renderer, accessibility, and test stewards |
| ADR-0008 | [MudBlazor inspiration creates no .NET compatibility contract](adr-0008-no-dotnet-compatibility-contract.md) | accepted | product, API, legal, and documentation stewards |

## Governance

### States

- **proposed:** complete enough for review but not binding;
- **under-review:** actively owned and being evaluated but not binding;
- **accepted:** binding current architecture and `maturity: stable`;
- **rejected:** considered and not selected, retained for history;
- **deprecated:** still observable but scheduled for replacement; and
- **superseded:** replaced by a named later ADR and retained permanently; and
- **archived:** non-binding historical context removed from the active register
  but retained permanently with its ID.

### Review workflow

1. Assign the next unused permanent ADR ID.
2. Mark the complete proposal `under-review` and identify architecture and
   product owners plus every materially affected
   package, profile, security, accessibility, release, and documentation owner.
3. Complete the required impact review and link current evidence.
4. Resolve blocking review findings before acceptance.
5. Update the register and all affected roadmaps, maps, catalogs, package or
   profile boundaries, and acceptance records in the same reviewed change.
6. Supersede rather than rewrite an accepted decision when the durable choice
   changes materially.

### Review triggers

Review an accepted ADR when executable evidence contradicts an assumption; a
new runtime, host, renderer, capability provider, server adapter, profile, or
shell is proposed; a public compatibility or support promise changes; a
security/accessibility consequence changes; or a dependency edge would cross a
forbidden boundary.

## Index

### Subdirectories

- None yet.

### Documents

- [ADR-0001 — Host-neutral semantic component kernel](adr-0001-host-neutral-semantic-component-kernel.md)
- [ADR-0002 — Versioned semantic UI tree](adr-0002-versioned-semantic-ui-tree.md)
- [ADR-0003 — Host-neutral effects, capabilities, and resources](adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [ADR-0004 — Renderer backend separation](adr-0004-renderer-backend-separation.md)
- [ADR-0005 — Server adapter and trust boundary](adr-0005-server-adapter-and-trust-boundary.md)
- [ADR-0006 — Profile composition](adr-0006-profile-composition.md)
- [ADR-0007 — Native-control portability gate](adr-0007-native-control-portability-gate.md)
- [ADR-0008 — No .NET compatibility contract](adr-0008-no-dotnet-compatibility-contract.md)

## Maintaining this index

Index every ADR, preserve permanent IDs and history, keep status synchronized
with body metadata and maturity, and update the decision register whenever a
record is proposed, accepted, rejected, deprecated, or superseded.
