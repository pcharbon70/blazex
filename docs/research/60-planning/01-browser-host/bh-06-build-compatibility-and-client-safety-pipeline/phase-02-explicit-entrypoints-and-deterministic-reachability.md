---
title: "BH-06 Phase 2 - Explicit Entrypoints and Deterministic Reachability"
kind: note
created: "2026-09-12"
maturity: developing
tags: [beam, bh-06, build, entrypoint, implementation-planning, reachability]
aliases: ["BH-06 phase 2"]
---

# BH-06 Phase 2 - Explicit Entrypoints and Deterministic Reachability

Back to the [milestone](README.md).

- [x] 2 Phase - Explicit Entrypoints and Deterministic Reachability.

  Replace Phase 1's manually assembled fixed closure with a bounded,
  deterministic explanation of which BEAM modules are reachable from each
  explicit client entrypoint. This phase owns module accounting and ambiguous
  dispatch rejection, not the later server/native dependency policy.

  Work starts from synchronized `main` at
  `8246bcae50642347dcfa56ba7a93630b244b6456` on
  `codex/bh06-phase2-entrypoints-reachability`. The owner authorized Phase 2 on
  2026-09-12 with one commit per section, one PR, merge, synchronized-main
  return, and local/remote branch deletion.

  - [x] 2.1 Section - Bind Phase 1 and freeze reachability authority.
    - [x] Bind Phase 1 completion, review, manifest, browser evidence, build
      implementation, exact base, delivery workflow, and active deferrals.
    - [x] Freeze entrypoint identity, BEAM inventory, edge/reason-chain,
      external-reference, dynamic-dispatch, determinism, and bound rules.
    - [x] Activate versioned Phase 2 integration evidence without claiming a result.

  - [x] 2.2 Section - Implement explicit entrypoint and BEAM inventory contracts.
    - [x] Validate bounded entrypoint declarations without creating atoms from input.
    - [x] Read module/import/export/attribute facts from regular BEAM files,
      reject duplicates and malformed files, and normalize stable module names.
    - [x] Produce deterministic inventory records independent of input order,
      absolute paths, timestamps, or compiler chunk order.

  - [x] 2.3 Section - Implement reachability traversal and build integration.
    - [x] Traverse known module edges from each root with shortest stable reason chains.
    - [x] Separate external references, reject undeclared dynamic dispatch, and
      expose unused inventory without silently bundling it.
    - [x] Bind the reachability report into the candidate build manifest and
      exercise multi-root, cycle, missing-root, duplicate, and mutation cases.

  - [x] 2.4 Section - Reproduce, review, and publish completion.
    - [x] Run package, fixture, browser-Wasm replay, archive, JSON, mutation,
      deterministic-repeat, dependency, and patch-hygiene gates.
    - [x] Publish exact module/edge/external/unused counts, reason chains,
      hashes, commands, failures, limitations, and deferred qualifications.
    - [x] Accept only if reports are byte-stable and every included module has
      an entrypoint-rooted reason; leave later safety policy separately unauthorized.

## Exit gate

Equivalent BEAM inventories in any input order must produce identical reports.
Every included module must have a shortest deterministic reason chain from an
explicit entrypoint. Missing or duplicate modules, malformed BEAMs, ambiguous
dynamic dispatch, path leakage, unexplained inclusion, or Phase 1 browser-Wasm
regression blocks completion.

## Connections

- [Phase 1 completion](phase-01-completion.md)
- [Entrypoint and reachability contract](entrypoint-and-reachability-contract.md)
- [Browser milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
