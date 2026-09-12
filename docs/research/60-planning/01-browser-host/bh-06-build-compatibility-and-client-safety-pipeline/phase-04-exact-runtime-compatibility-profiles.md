---
title: "BH-06 Phase 4 - Exact Runtime Compatibility Profiles"
kind: note
created: "2026-09-12"
maturity: developing
tags: [atomvm, bh-06, build, compatibility, implementation-planning, wasm]
aliases: ["BH-06 phase 4"]
---

# BH-06 Phase 4 - Exact Runtime Compatibility Profiles

Back to the [milestone](README.md).

- [ ] 4 Phase - Exact Runtime Compatibility Profiles.
  - Need: Phase 3 proves that the reachable closure is client-safe, but the
    manifest still carries unverified compatibility strings and assembly can
    silently pair a candidate with the wrong runtime or protocol surface.
  - Outcome: a runtime-owned, versioned profile is matched exactly against a
    candidate requirement set before AVM assembly, with a deterministic report
    explaining every runtime, protocol, and feature decision.
  - Boundary: this phase owns compatibility declaration and enforcement, not
    secret scanning, license inventory, payload budgets, production release
    support, LiveView, LocalLiveView, or BH-07.

  - [x] 4.1 Section - Bind Phase 3 and freeze compatibility authority.
    - [x] Bind accepted Phase 3 evidence, exact base, delivery workflow, and deferrals.
    - [x] Freeze exact identity, protocol, feature, diagnostic, normalization,
      provider-ownership, and pre-assembly rules.
    - [x] Activate versioned profile, requirement, and result schemas without
      claiming a compatibility pass.

  - [x] 4.2 Section - Implement deterministic compatibility evaluation.
    - [x] Validate bounded profiles and requirements without creating atoms from input.
    - [x] Match the runtime identity/version/ABI, required protocol versions,
      and required supported feature states exactly.
    - [x] Reject unknown, duplicate, malformed, unsupported, missing, and unused
      candidate-specific declarations with stable diagnostics.

  - [x] 4.3 Section - Enforce compatibility before candidate bundle assembly.
    - [x] Compose client safety and compatibility into one ordered candidate gate.
    - [x] Bind a content-addressed compatibility report and exact profile identity
      into the candidate manifest.
    - [x] Prove compatible success plus runtime, ABI, protocol, feature, mutation,
      determinism, and pre-assembly rejection cases.

  - [ ] 4.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package, browser-Wasm, validator, mutation, deterministic-repeat,
      archive, JSON, syntax, dependency, and patch-hygiene gates.
    - [ ] Publish decisions, exact counts, hashes, commands, failures,
      limitations, and deferred qualifications.
    - [ ] Accept only if every requirement is explained and every incompatible
      candidate fails before AVM creation.

## Exit gate

Equivalent profile and requirement inputs must produce identical reports.
Every runtime, protocol, and feature requirement must have exactly one decision.
Identity, version, ABI, missing protocol, wrong protocol version, missing feature,
unsupported feature, unknown fields, post-assembly rejection, or Phase 3 browser
regression blocks completion.

## Connections

- [Phase 3 completion](phase-03-completion.md)
- [Compatibility profile contract](compatibility-profile-contract.md)
- [Browser milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
