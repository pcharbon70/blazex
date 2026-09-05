---
title: "Phase 2 - Semantic Nodes, Identity, and Portable Component Evaluation"
kind: note
created: "2026-09-05"
maturity: developing
tags:
  - bh-02
  - component-model
  - host-neutral
  - implementation-planning
  - semantic-ui
aliases:
  - "BH-02 phase 2"
---

# Phase 2 - Semantic Nodes, Identity, and Portable Component Evaluation

Back to milestone: [README](README.md)

- [ ] 2 Phase - Semantic Nodes, Identity, and Portable Component Evaluation.

  Define the smallest executable semantic-tree and component-evaluation
  contract that can remain independent of every renderer, host, runtime, and
  server adapter. All APIs remain experimental until BH-02 acceptance.

  - [x] 2.1 Section - Authorize and freeze the experimental contract envelope.

    Bind the completed Phase 1 gate and accepted architecture decisions before
    adding executable semantics.

    - [x] 2.1.1 Task - Record bounded Phase 2 authorization.

      - [x] 2.1.1.1 Subtask - Record the owner request, synchronized base, branch, four-section delivery, single-PR rule, and final local/remote branch cleanup.
      - [x] 2.1.1.2 Subtask - Keep Phases 3–8, stable/public APIs, product components, renderer behavior, external dependencies, and support claims unauthorized.

    - [x] 2.1.2 Task - Define the first contract envelope.

      - [x] 2.1.2.1 Subtask - Bind ADR-0001, ADR-0002, the Phase 1 completion decision, and the host-neutral architecture by path and SHA-256.
      - [x] 2.1.2.2 Subtask - Freeze semantic-tree version 1, a bounded node-kind vocabulary, portable identity/key rules, and deterministic sibling uniqueness requirements.
      - [x] 2.1.2.3 Subtask - Freeze pure/stateful mount, update, replacement, output-validation, and failure semantics without lifecycle effects or renderer work.

  - [x] 2.2 Section - Implement semantic nodes and deterministic identity.

    Make identity and tree validity executable in the inward packages without
    introducing later-phase fields.

    - [x] 2.2.1 Task - Implement portable component and node identity.

      - [x] 2.2.1.1 Subtask - Add a structural identity containing root, path, and positive generation with bounded portable key validation.
      - [x] 2.2.1.2 Subtask - Preserve identity across update and move, derive child identity deterministically, and increment generation on replacement.
      - [x] 2.2.1.3 Subtask - Reject PIDs, references, functions, maps, structs, improper lists, and other opaque terms as identity material.

    - [x] 2.2.2 Task - Implement semantic node version 1.

      - [x] 2.2.2.1 Subtask - Add typed text, group, action, field, selection, collection, and surface nodes with identity, optional key, content, and ordered children only.
      - [x] 2.2.2.2 Subtask - Validate the complete tree, identity ancestry, duplicate sibling identities/keys, text/content rules, and unknown or malformed structures before acceptance.
      - [x] 2.2.2.3 Subtask - Add deterministic traversal and focused positive/negative unit tests without defining events, layout, tokens, accessibility, resources, or renderer extensions.

  - [ ] 2.3 Section - Implement portable pure and stateful evaluation.

    Evaluate component modules through one host-neutral state machine and
    accept output only after semantic-tree validation.

    - [ ] 2.3.1 Task - Implement the component evaluation state machine.

      - [ ] 2.3.1.1 Subtask - Define explicit pure and stateful component modes and required callbacks with map props and opaque portable state.
      - [ ] 2.3.1.2 Subtask - Implement mount and update with stable identity, monotonic revision, fail-closed callback results, and structured deterministic diagnostics.
      - [ ] 2.3.1.3 Subtask - Implement replacement as a new generation and prohibit implicit rename, ambient rerender, process ownership, effects, messages, and disposal semantics.

    - [ ] 2.3.2 Task - Validate semantic output atomically.

      - [ ] 2.3.2.1 Subtask - Add UI-tree integration that validates component output and root identity after mount, update, and replacement.
      - [ ] 2.3.2.2 Subtask - Prove pure evaluation, stateful transitions, keyed reorder identity, replacement generation, malformed callbacks, and invalid-tree rejection.

  - [ ] 2.4 Section - Run the Phase 2 integration gate and publish evidence.

    Demonstrate the contract as a coherent experimental slice while preventing
    later semantics or platform objects from entering it.

    - [ ] 2.4.1 Task - Add conformance and governance evidence.

      - [ ] 2.4.1.1 Subtask - Publish versioned semantic/evaluation fixtures and expected outcomes without claiming renderer conformance.
      - [ ] 2.4.1.2 Subtask - Add fail-closed validation for authorization, bound hashes, exact contract vocabulary, API ownership, fixture coverage, forbidden leakage, and premature later-phase claims.
      - [ ] 2.4.1.3 Subtask - Add negative tests for stale authorization, expanded kinds, invalid identity material, renderer leakage, missing fixture coverage, and stable/support overclaims.

    - [ ] 2.4.2 Task - Execute and record the complete Phase 2 gate.

      - [ ] 2.4.2.1 Subtask - Run all affected Mix tests and format checks, BH-02 Phase 1 and Phase 2 validators, archive validation, inherited validators, and patch hygiene checks.
      - [ ] 2.4.2.2 Subtask - Record tool identities, commands, hashes, section commits, limitations, and a truthful pass or stop decision.
      - [ ] 2.4.2.3 Subtask - Leave Phase 3 unauthorized and make no renderer, browser, native-control, accessibility, performance, or support claim.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 2.4 passes or records a truthful stop decision. Phase 2 adds no
external dependency and does not stabilize its experimental APIs.

## Connections

- [BH-02 plan](README.md)
- [ADR-0001 — Host-neutral semantic component kernel](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [ADR-0002 — Versioned semantic UI tree](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md)
- [Host-neutral architecture](../../../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Foundational component semantics inquiry](../../../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)

## Sources

- [Phase 1 completion evidence](phase-01-implementation-evidence.md)
- [BH-02 conditional entry manifest](../../../assets/bh-01-release/blazex-bh-02-entry-manifest-v0-1-0.md)
