---
title: "BH-06 Phase 5 - Secret-Bearing Input Exclusion"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, client-safety, implementation-planning, secrets, security]
aliases: ["BH-06 phase 5"]
---

# BH-06 Phase 5 - Secret-Bearing Input Exclusion

Back to the [milestone](README.md).

- [ ] 5 Phase - Secret-Bearing Input Exclusion.
  - Need: Phase 4 rejects incompatible candidates, but reachable BEAMs, host
    assets, and public configuration can still carry credentials into the browser.
  - Outcome: every byte source assembled for the application bundle and every
    browser host/document input is accounted for by digest and scanned under a
    versioned policy; findings reject before AVM assembly without disclosing matches.
  - Boundary: this phase owns deterministic secret/configuration exclusion, not
    license inventory, feature-bundle decomposition, payload budgets, production
    release support, LiveView, LocalLiveView, or BH-07.

  - [x] 5.1 Section - Bind Phase 4 and freeze secret-exclusion authority.
    - [x] Bind accepted Phase 4 evidence, exact base, delivery workflow, and deferrals.
    - [x] Freeze input accounting, public-config, literal/key-fragment, redaction,
      scale-bound, diagnostic, normalization, and pre-assembly rules.
    - [x] Activate versioned policy and result schemas without claiming a pass.

  - [ ] 5.2 Section - Implement deterministic redacted scanning.
    - [ ] Validate bounded policies, inputs, and JSON-safe public configuration
      without creating atoms or retaining filesystem paths.
    - [ ] Scan all occurrences of fixed byte signatures and normalized config keys,
      recording only rule identity, logical subject, offset, digest, and counts.
    - [ ] Reject unknown fields, duplicates, malformed values, overflow, and any
      finding with stable, value-free diagnostics.

  - [ ] 5.3 Section - Enforce exclusion before candidate bundle assembly.
    - [ ] Compose safety, compatibility, and secret exclusion in one ordered gate.
    - [ ] Bind a content-addressed secret audit into the manifest and account for
      the exact bundle, document, and host inputs.
    - [ ] Prove clean success plus literal, config-key, duplicate, overflow,
      mutation, determinism, redaction, and pre-assembly rejection cases.

  - [ ] 5.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package, browser-Wasm, validator, mutation, deterministic-repeat,
      archive, runtime, JavaScript, demo, syntax, and patch-hygiene gates.
    - [ ] Publish exact counts, hashes, commands, failures, limitations, and deferrals.
    - [ ] Accept only if every assembled input is accounted for, clean candidates
      pass, findings are redacted, and secret-bearing candidates cannot create an AVM.

## Exit gate

Equivalent policy, public configuration, and bytes must produce identical reports.
Every bundle input and browser-owned source must have one digest record. Any
forbidden literal or config key, unaccounted input, malformed declaration,
unsafe diagnostic disclosure, post-assembly rejection, or Phase 4 browser
regression blocks completion.

## Connections

- [Phase 4 completion](phase-04-completion.md)
- [Secret-exclusion contract](secret-exclusion-contract.md)
- [Browser trust and deployment policy](../../../20-notes/blazex-browser-trust-deployment-and-fallback-policy.md)
