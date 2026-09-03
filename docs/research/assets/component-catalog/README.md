---
title: "Component Catalog Assets"
kind: map
created: "2026-09-03"
tags:
  - archive-navigation
  - component-catalog
  - directory-index
  - mudblazor
aliases:
  - "BlazeX catalog assets"
---

# Component Catalog Assets (`component-catalog`)

## Purpose

This directory holds the pinned MudBlazor reference lock, immutable extraction
inputs, BlazeX catalog schema and authored data, deterministic generated views,
and source-diff/review reports used by BH-00.

## What belongs here

- Exact reference identities and content hashes.
- Raw source-facing snapshots extracted from the pinned reference.
- Machine schemas and canonical authored catalog data.
- Generated human-readable catalog views and deterministic review reports.

Implementation manifests, runtime component modules, release support evidence,
and live upstream downloads do not belong here.

## Index

### Subdirectories

- None yet.

### Files

- [BlazeX capability registry v0.1.0](blazex-capability-registry-v0.1.0.json) — fourteen catalog-facing focus, measurement, pointer, keyboard, clipboard, files, window, surface, notification, storage, theme, accessibility, time, and network contracts with lifecycle/security/fallback boundaries.
- [BlazeX component classification schema](blazex-component-classification.schema.json) — JSON Schema 1.0.0 for the versioned Phase 4 product, package, capability, remote, fallback, portability, native-strategy, exception, and evidence layer.
- [BlazeX component classification v0.1.0](blazex-component-classification-v0.1.0.json) — canonical classification overlay for all 83 families and twelve source exceptions, cryptographically bound to the locked Phase 3 catalog.
- [BlazeX component classification v0.1.0 generated view](blazex-component-classification-v0-1-0-generated.md) — deterministic joined human view of source family, disposition, tier, package, dependencies, and later Phase 4 dimensions.
- [BlazeX component catalog schema](blazex-component-catalog.schema.json) — canonical JSON Schema 1.0.0 for stable identities, source relationships, Phase 4 classification fields, capability/portability assessments, delivery states, evidence, and exceptions.
- [BlazeX component catalog v0.1.0](blazex-component-catalog-v0.1.0.json) — canonical authored inventory of all 83 normalized families, compound source identifiers, deliberately unassigned product/delivery fields, and twelve source-closure exception records.
- [BlazeX component catalog v0.1.0 generated view](blazex-component-catalog-v0-1-0-generated.md) — deterministic human-readable family, category, source-identity, exception, and unassigned-state view; never the authored source of truth.
- [MudBlazor v9.9.0 reference lock](mudblazor-v9.9.0-reference-lock.json) — exact repository, commit/tree/blob, license, extraction-boundary, and update-policy identities.
- [MudBlazor v9.9.0 inventory reconciliation](mudblazor-v9-9-0-inventory-reconciliation.md) — exact 83-to-83 source and existing-research comparison, category/name changes, exception closure, stewardship, and deferred product decisions.
- [MudBlazor v9.9.0 source-family snapshot](mudblazor-v9.9.0-source-families.txt) — sorted names of the 83 first-level component source directories at the locked commit.

## Maintaining this index

Index every direct artifact and identify whether it is authored, pinned input,
generated output, or review evidence. Never edit a generated view as the source
of truth, and never update the reference lock without a reviewed source diff.
