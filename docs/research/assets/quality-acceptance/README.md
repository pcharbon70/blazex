---
title: "Quality and Acceptance Assets"
kind: map
created: "2026-09-03"
tags:
  - acceptance-criteria
  - archive-navigation
  - bh-00
  - directory-index
  - quality-budgets
aliases:
  - "BlazeX quality and acceptance assets"
---

# Quality and Acceptance Assets (`quality-acceptance`)

## Purpose

This directory holds the versioned quality-budget and acceptance-traceability
contracts used to turn BlazeX roadmap and catalog claims into measurable,
owned, reproducible future evidence.

## What belongs here

- Machine schemas for quality budgets, gates, acceptance conditions, and
  coverage records.
- Canonical authored contracts whose proposed thresholds remain explicitly
  distinct from measured evidence.
- Deterministic generated coverage reports and review records.

Runtime measurements, browser traces, benchmark output, accessibility audit
captures, and release attestations belong to their responsible later
milestones and must only be referenced here through immutable evidence IDs.

## Index

### Subdirectories

- None yet.

### Files

- [BlazeX quality contract schema](blazex-quality-contract.schema.json) — JSON
  Schema 1.0.0 for measurement environments, proposed budgets, reliability
  scenarios, cross-cutting gates, exceptions, and evidence boundaries.
- [BlazeX quality contract v0.1.0](blazex-quality-contract-v0.1.0.json) —
  canonical Phase 5 quality contract containing proposed, unmeasured payload,
  startup, interaction, resource, build, and resilience budgets.

## Maintaining this index

Index every direct artifact and identify whether it is authored, generated, or
evidence. Never rewrite a proposed threshold as a passing measurement, and
never attach evidence without a reproducible method, immutable identity,
owner, environment, and freshness rule.
