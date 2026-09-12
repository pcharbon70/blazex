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
| [1 — Attested Static Delivery Boundary](phase-01-attested-static-delivery-boundary.md) | active | Serve the accepted BH-06 artifact set through Phoenix under exact manifest cache, integrity, and private-evidence rules while removing LiveView/LocalLiveView from the active profile. | Accepted BH-06 and explicit authorization |

Later phase decomposition remains a separate planning decision. Phase 1 does
not authorize sessions, bootstrap state, commands, pushes, reconnect, routing,
deployment coordination, support promotion, LiveView, LocalLiveView, or BH-08.

## Index

### Documents

- [Phase 1 — Attested Static Delivery Boundary](phase-01-attested-static-delivery-boundary.md)
- [Static-delivery contract](static-delivery-contract.md)

### Subdirectories

None.
