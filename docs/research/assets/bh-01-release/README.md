---
title: "BH-01 Feasibility Release Assets"
kind: map
created: "2026-09-05"
tags:
  - archive-navigation
  - bh-01
  - directory-index
  - feasibility
  - release-contract
aliases:
  - "BlazeX BH-01 release assets"
---

# BH-01 Feasibility Release Assets (`bh-01-release`)

## Purpose

This directory holds the immutable candidate feasibility baseline, its schema,
and generated human indexes. The baseline records what BH-01 actually proved,
failed, conditioned, or deferred; it is not a production software release.

## Canonical artifacts

- [Feasibility baseline v0.1.0](blazex-bh-01-feasibility-baseline-v0.1.0.json)
- [Feasibility baseline schema](blazex-bh-01-feasibility-baseline.schema.json)
- [Release index](blazex-bh-01-release-index-v0-1-0.md)
- [Compatibility and limitations index](blazex-bh-01-compatibility-limitations-index-v0-1-0.md)
- [Artifact index](blazex-bh-01-artifact-index-v0-1-0.md)
- [Benchmark index](blazex-bh-01-benchmark-index-v0-1-0.md)
- [Proof index](blazex-bh-01-proof-index-v0-1-0.md)
- [Risk index](blazex-bh-01-risk-index-v0-1-0.md)
- [Finding index](blazex-bh-01-finding-index-v0-1-0.md)
- [Environment index](blazex-bh-01-environment-index-v0-1-0.md)

## Maintenance

Generate and validate this package with
`integration/reproducibility/version_phase10_baseline.py`. Never edit a
generated index as independent truth. A changed source, tool, lock, runtime,
private API, browser, environment, scenario, mitigation, or threshold must
invalidate affected evidence, preserve this baseline, repeat the governed
proofs, and publish a superseding version.
