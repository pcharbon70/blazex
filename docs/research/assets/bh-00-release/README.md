---
title: "BH-00 Release Assets"
kind: map
created: "2026-09-03"
tags:
  - archive-navigation
  - bh-00
  - directory-index
  - governance
  - release-contract
aliases:
  - "BlazeX BH-00 release assets"
---

# BH-00 Release Assets (`bh-00-release`)

## Purpose

This directory holds the versioned governance, reconciliation, review, risk,
release-index, and BH-01 entry artifacts that close the BH-00 product contract.

## What belongs here

- The canonical machine governance contract and schema.
- Source-bound reconciliation and multidisciplinary review records.
- The BH-00 release index and BH-01 input/decision manifest.
- Deterministic generated summaries and final acceptance review evidence.

Runtime builds, dependency locks, browser measurements, component
implementations, and BH-01 experiment output do not belong here.

## Index

### Subdirectories

- None yet.

### Files

- [BH-00 governance schema](blazex-bh-00-governance.schema.json) — JSON Schema
  1.0.0 for source bindings, architecture/package/profile reconciliation,
  reviews, findings, risks, release identity, and BH-01 entry decisions.
- [BH-00 governance contract v0.1.0](blazex-bh-00-governance-v0.1.0.json) —
  canonical staged governance record binding the accepted BH-00 inputs and
  reconciliation outcomes without claiming runtime implementation.

## Maintaining this index

Index every direct artifact and label authored, generated, historical,
proposed, unsupported, and deferred material explicitly. A source hash change
requires reconciliation and a governed version update; never edit generated
views as the source of truth.
