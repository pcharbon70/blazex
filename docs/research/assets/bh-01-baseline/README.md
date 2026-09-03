---
title: "BH-01 Feasibility Baseline Assets"
kind: map
created: "2026-09-03"
tags:
  - archive-navigation
  - bh-01
  - directory-index
  - evidence-governance
  - feasibility
aliases:
  - "BlazeX BH-01 baseline assets"
---

# BH-01 Feasibility Baseline Assets (`bh-01-baseline`)

## Purpose

This directory holds the governed authorization, milestone ledger, evidence
schemas, repository activation manifest, and phase evidence for the BH-01
browser feasibility baseline.

## What belongs here

- The explicit repository-owner authorization for a named BH-01 plan and phase.
- The immutable BH-00 baseline snapshot inherited by BH-01.
- Machine-readable inputs, proofs, risks, stop conditions, owners, and links.
- Evidence, finding, decision, repository-boundary, and phase-gate records.

Runtime binaries, downloaded dependencies, generated build products, browser
captures, and benchmark samples belong in their phase-owned integration
locations rather than this governance directory.

## Index

### Subdirectories

- None yet.

### Files

- [BH-01 authorization v0.1.0](blazex-bh-01-authorization-v0.1.0.json) —
  explicit repository-owner approval, activation base, scope, conditions, and
  non-authorizations for Phase 1.
- [BH-01 milestone ledger v0.1.0](blazex-bh-01-milestone-ledger-v0.1.0.json) —
  imported BH-00 entry inputs, proof obligations, risks, stop conditions,
  prohibited actions, owner assignments, and acceptance/budget links.
- [BH-01 evidence record schema](blazex-bh-01-evidence-record.schema.json) —
  strict common provenance and lifecycle contract for twelve record types and
  ten non-collapsing evidence states.
- [BH-01 governance schema](blazex-bh-01-governance.schema.json) — structure
  for evidence classes, authority, finding severity, stopping, invalidation,
  mitigation, and reapproval.
- [BH-01 evidence governance v0.1.0](blazex-bh-01-evidence-governance-v0.1.0.json)
  — active owners, escalation paths, blocker rules, and change control for the
  feasibility baseline.

## Maintaining this index

Index every direct artifact. Never rewrite an observed result or authorization
in place: supersede it with a versioned record, preserve reciprocal links, and
invalidate dependent evidence explicitly. Plan completion and repository
activation cannot be represented as browser, runtime, or product evidence.
