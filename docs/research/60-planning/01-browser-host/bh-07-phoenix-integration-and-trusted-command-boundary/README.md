---
title: "BH-07 Phoenix Integration and Trusted Command Boundary"
kind: map
created: "2026-09-12"
tags: [archive-navigation, bh-07, phoenix, trusted-boundary]
aliases: ["BH-07 implementation plan"]
---

# BH-07 Phoenix Integration and Trusted Command Boundary

## Purpose

Compose the accepted browser build with Phoenix as a replaceable delivery and
trusted-command adapter. Browser-host, renderer, and component behavior remain
in their owning packages. LiveView and LocalLiveView are **[DEFERRED]** and are
not dependencies, inputs, or completion gates for current BH-07 work.

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — Attested Static Delivery Boundary](phase-01-attested-static-delivery-boundary.md) | complete | Serve the accepted BH-06 artifact set through Phoenix under exact manifest cache, integrity, and private-evidence rules while removing LiveView/LocalLiveView from the active profile. | Accepted BH-06 and explicit authorization |

Later phase decomposition remains a separate planning decision. Phase 1 does
not authorize sessions, bootstrap state, commands, pushes, reconnect, routing,
deployment coordination, support promotion, LiveView, LocalLiveView, or BH-08.

## Index

### Documents

- [Phase 1 — Attested Static Delivery Boundary](phase-01-attested-static-delivery-boundary.md)
- [Static-delivery contract](static-delivery-contract.md)
- [Phase 1 completion evidence](phase-01-completion.md)
- [Phase 1 review and reconciliation](phase-01-review-and-reconciliation.md)

### Subdirectories

None.

## What belongs here

Prospective, explicitly authorized BH-07 Phoenix integration plans and their
completion reviews belong here. Implementation evidence remains under
`integration/bh-07`; immutable authorization and completion bindings remain
under `assets/bh-07-baseline`.

## Maintaining this index

Index every direct planning document and add later phases only after separate
owner authorization. Keep LiveView and LocalLiveView marked deferred unless a
future planning decision explicitly changes that boundary.
