---
title: "BH-06 License and Provenance Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, contract, licensing, provenance]
aliases: []
---

# BH-06 License and Provenance Contract

Back to the [Phase 6 plan](phase-06-license-and-provenance-inventory.md).

## Inputs and authority

Phase 6 consumes the exact logical labels and bytes already accepted by the
Phase 5 secret audit. The package declares one component ID for every input.
The versioned policy owns component source/version facts, shipment and
build-only scope, license-record references, notice paths, and explicit bounds.
Reports retain logical labels and digests, never filesystem source paths.

Each shipped component has a non-empty license-record set. A record states the
observed license expression and disposition; it does not grant rights. BlazeX
has no repository-level public license in the Phase 6 base, so project-owned
inputs are explicitly `NOASSERTION` and `private-development-only`. This phase
must not silently convert that state into an open-source or production release.

## Determinism and notices

Policies reject missing or unknown fields, duplicate IDs, unknown record
references, invalid scope, and bounds above implementation ceilings. Required
notice files are relative to a caller-supplied repository root and are verified
by SHA-256. Missing files or digest drift reject. Build-only records remain in
the report lineage but never count as shipped-input ownership.

Inputs reject duplicate labels, unknown component IDs, malformed declarations,
per-input overflow, aggregate overflow, and count overflow. Normalized reports
sort records and inputs by stable identity. The inventory and secret audit must
contain exactly equal `(label, bytes, sha256)` sets before assembly.

## Enforcement and boundary

Client safety runs first, compatibility second, secret audit third, license and
provenance inventory fourth, and AVM assembly only after all pass. The build
manifest binds the passing inventory as a content-addressed artifact. This is a
reproducible engineering control and not legal advice or a production-release
authorization.

LiveView and LocalLiveView are **[DEFERRED]** and are not inventory inputs,
components, provenance targets, or completion gates.

