---
title: "BH-06 Phase 3 - Server and Native Client-Safety Gate"
kind: note
created: "2026-09-12"
maturity: developing
tags: [beam, bh-06, build, client-safety, implementation-planning, native, server]
aliases: ["BH-06 phase 3"]
---

# BH-06 Phase 3 - Server and Native Client-Safety Gate

Back to the [milestone](README.md).

- [ ] 3 Phase - Server and Native Client-Safety Gate.
  - Need: Phase 2 exposes the reachable closure and external references but
    deliberately does not decide whether those dependencies are browser-safe.
  - Outcome: every reachable module and external module has one explicit,
    deterministic classification; server-only, native, unknown, and forbidden
    runtime primitives stop the candidate build before bundle assembly.
  - Boundary: this phase owns dependency classification and enforcement, not
    secret scanning, compatibility profiles, licenses, payload budgets,
    production release support, or BH-07.

  - [x] 3.1 Section - Bind Phase 2 and freeze client-safety authority.
    - [x] Bind accepted Phase 2 evidence, exact base, delivery workflow, and deferrals.
    - [x] Freeze application/module precedence, external coverage, forbidden
      primitive, diagnostic, determinism, and fail-closed rules.
    - [x] Activate versioned policy and result schemas without claiming a pass.

  - [x] 3.2 Section - Implement deterministic dependency classification.
    - [x] Validate bounded policy records without creating atoms from input.
    - [x] Classify every reachable module by exact module override or explicit
      application ownership and every external module by exact policy.
    - [x] Reject unknown, server-only, native, contradictory, unused, and
      forbidden-primitive declarations with stable diagnostics.

  - [x] 3.3 Section - Enforce safety before candidate bundle assembly.
    - [x] Carry trusted application ownership into path-free BEAM inventory.
    - [x] Bind a content-addressed client-safety report into the candidate manifest.
    - [x] Prove safe success plus server, NIF, port, unknown, policy-mutation,
      report-mutation, and pre-assembly rejection cases.

  - [ ] 3.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package, browser-Wasm, validator, mutation, deterministic-repeat,
      archive, JSON, syntax, dependency, and patch-hygiene gates.
    - [ ] Publish classifications, exact counts, hashes, commands, failures,
      limitations, and deferred qualifications.
    - [ ] Accept only if all reachable and external dependencies are explained
      and unsafe candidates fail before AVM creation.

## Exit gate

Equivalent policy, inventory, and reachability inputs must produce identical
reports. Every reachable module and external module must have exactly one
explanation. Unknown, server-only, or native dependencies; NIF/port primitives;
contradictory policy; path leakage; post-assembly rejection; or Phase 2 browser
regression blocks completion.

## Connections

- [Phase 2 completion](phase-02-completion.md)
- [Client-safety policy contract](client-safety-policy-contract.md)
- [Browser milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
