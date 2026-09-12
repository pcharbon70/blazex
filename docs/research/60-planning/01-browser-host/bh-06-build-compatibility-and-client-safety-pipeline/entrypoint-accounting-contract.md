---
title: "BH-06 Entrypoint Accounting Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [attestation, bh-06, build, contract, entrypoint]
aliases: []
---

# BH-06 Entrypoint Accounting Contract

Back to the [milestone](README.md) and [Phase 11 plan](phase-11-entrypoint-accounting-and-milestone-handoff.md).

An application-owned, versioned policy declares the complete browser entrypoint
set by stable ID and module name. It also declares every required public and
private artifact role, every required evidence category, and scaling limits.
Policy loading is closed-world, bounded, ordered, and may not create atoms.

One attestation is produced per declared entrypoint only after its manifest and
all prior gates exist. It binds the canonical policy, complete manifest,
artifacts by role/exposure/identity/bytes, compatibility identities, safety and
secret decisions, license components and input coverage, bundle ownership,
runtime closure summary, payload policy/metrics/budgets, and delivery-integrity
policy. Paths are retained only for public/private artifact correlation; source
filesystem paths are never admitted.

The attestation set must equal the declared entrypoint set. Missing, extra,
duplicate, stale, rejected, malformed, unaccounted, or over-limit input fails
closed with an actionable category and entrypoint ID. Equivalent normalized
inputs produce byte-equivalent JSON.

This attestation closes build review, not production delivery. Serving,
deployment coordination, Phoenix transport, authentication/authorization,
routing, LiveView, LocalLiveView, support promotion, BH-07, and BH-19 remain
outside this contract.
