---
title: "Phase 2 - Compatibility Identity, Discovery, Prerequisites, and Manifest Contract"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-03
  - browser-host
  - compatibility
  - implementation-planning
  - manifest
aliases:
  - "BH-03 phase 2"
---

# Phase 2 - Compatibility Identity, Discovery, Prerequisites, and Manifest Contract

Back to milestone: [README](README.md)

- [ ] 2 Phase - Compatibility Identity, Discovery, Prerequisites, and Manifest Contract.

  Implement the versioned identity and validation gate that decides whether a
  browser profile is eligible to proceed to artifact acquisition. This phase
  never downloads runtime artifacts, starts a runtime, or registers roots.

  - [x] 2.1 Section - Authorize Phase 2 and freeze the executable contract.

    - [x] 2.1.1 Task - Bind authority and predecessor truth.

      - [x] 2.1.1.1 Subtask - Record synchronized `main`, exact base, working branch, four-section delivery, one PR, merge, synchronized-main return, and local/remote branch deletion.
      - [x] 2.1.1.2 Subtask - Bind the Phase 1 completion, planned lifecycle contract, entry ledger, accepted BH-02 contract baseline, and environment policy by SHA-256.
      - [x] 2.1.1.3 Subtask - Exclude artifact acquisition, startup, readiness, runtime/root lifecycle, recovery, measurements, support, and public stability.

    - [x] 2.1.2 Task - Freeze the Phase 2 executable vocabulary.

      - [x] 2.1.2.1 Subtask - Bind the five BH-03 identities and inherited renderer/semantic identities with exact-match negotiation.
      - [x] 2.1.2.2 Subtask - Define deterministic discovery sources, ambiguity rejection, same-origin rules, and prerequisite decisions.
      - [x] 2.1.2.3 Subtask - Define the strict manifest envelope, artifact declarations, failure classes, ownership, and Phase 3 boundary.

  - [ ] 2.2 Section - Implement compatibility identities and negotiation.

    - [ ] 2.2.1 Task - Publish owner-specific identity descriptors.

      - [ ] 2.2.1.1 Subtask - Replace the runtime adapter's disposable-only surface with a reusable, experimental Popcorn compatibility descriptor while retaining the historical BH-01 adapter contract.
      - [ ] 2.2.1.2 Subtask - Implement browser-host required identities and deterministic missing, unknown, duplicate, and mismatch rejection without acquiring dependencies.
      - [ ] 2.2.1.3 Subtask - Mirror the exact identity table and negotiation outcome in the browser loader.

    - [ ] 2.2.2 Task - Prove cross-language agreement.

      - [ ] 2.2.2.1 Subtask - Add positive exact-match tests and negative missing, extra, duplicate, malformed, and mismatched identity cases.
      - [ ] 2.2.2.2 Subtask - Verify failures classify as `identity-mismatch` before acquisition or activation.
      - [ ] 2.2.2.3 Subtask - Keep APIs experimental and component, renderer, server, and root behavior outside these modules.

  - [ ] 2.3 Section - Implement discovery, prerequisites, manifest validation, and fixtures.

    - [ ] 2.3.1 Task - Implement the pre-acquisition browser gate.

      - [ ] 2.3.1.1 Subtask - Resolve explicit, link, or meta manifest declarations deterministically and reject absence, ambiguity, credentials, fragments, cross-origin URLs, and unsupported schemes.
      - [ ] 2.3.1.2 Subtask - Evaluate the manifest-declared browser and deployment prerequisites with explicit `compatible`, `alternate-loading`, and `unsupported-prerequisite` outcomes.
      - [ ] 2.3.1.3 Subtask - Fetch only the manifest with bounded no-store, same-origin, no-redirect behavior and strictly validate its fields and artifact declarations.

    - [ ] 2.3.2 Task - Publish conformance fixtures and evidence boundaries.

      - [ ] 2.3.2.1 Subtask - Add versioned valid and invalid identity, discovery, prerequisite, and manifest fixtures under `integration/bh-03`.
      - [ ] 2.3.2.2 Subtask - Add unit/conformance tests proving deterministic normalized outputs and atomic rejection.
      - [ ] 2.3.2.3 Subtask - Keep browser results, artifact bytes, startup, roots, measurements, and acceptance evidence empty.

  - [ ] 2.4 Section - Run the inherited gate and publish completion evidence.

    - [ ] 2.4.1 Task - Execute the active Phase 2 checks.

      - [ ] 2.4.1.1 Subtask - Run project-local Mix/Node tests and builds, runtime verification, Phase 1 and Phase 2 validators/tests, all inherited validators/generators, JSON, archive, and patch hygiene.
      - [ ] 2.4.1.2 Subtask - Confirm Phase 3 behavior and all BH-03 browser/runtime/root/measurement/acceptance result sets remain absent.
      - [ ] 2.4.1.3 Subtask - Record exact commands, counts, negative outcomes, environment, and limitations.

    - [ ] 2.4.2 Task - Publish the Phase 2 decision.

      - [ ] 2.4.2.1 Subtask - Emit a versioned validation log, implementation-evidence note, and completion decision bound to current artifacts.
      - [ ] 2.4.2.2 Subtask - Mark Phase 2 complete only if every active gate passes without overclaim.
      - [ ] 2.4.2.3 Subtask - Leave Phase 3 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open and merge one pull
request only after Section 2.4 passes. Phase 2 may load and validate the JSON
manifest itself but must not acquire any declared artifact or start a runtime.

## Connections

- [BH-03 plan](README.md)
- [Phase 1 completion evidence](phase-01-implementation-evidence.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
- [BH-02 internal contract baseline](../../../assets/bh-02-baseline/blazex-bh-02-contract-baseline-v0.1.0.json)
