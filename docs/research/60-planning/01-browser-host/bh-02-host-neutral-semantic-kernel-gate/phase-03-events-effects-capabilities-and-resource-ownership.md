---
title: "Phase 3 - Events, Effects, Capabilities, and Resource Ownership"
kind: note
created: "2026-09-05"
maturity: developing
tags:
  - bh-02
  - capabilities
  - component-model
  - effects
  - implementation-planning
  - resources
  - semantic-events
aliases:
  - "BH-02 phase 3"
---

# Phase 3 - Events, Effects, Capabilities, and Resource Ownership

Back to milestone: [README](README.md)

- [ ] 3 Phase - Events, Effects, Capabilities, and Resource Ownership.

  Add validated intent and host-service boundaries to the Phase 2 semantic
  kernel without importing a concrete provider, renderer, runtime, server, or
  platform object. All contracts remain experimental.

  - [x] 3.1 Section - Authorize and freeze the experimental contract envelope.

    Bind the completed Phase 2 gate and accepted effect architecture before
    extending component transitions.

    - [x] 3.1.1 Task - Record bounded Phase 3 authorization.

      - [x] 3.1.1.1 Subtask - Record the owner request, synchronized base, branch, four-section delivery, single-PR rule, and final local/remote branch cleanup.
      - [x] 3.1.1.2 Subtask - Keep Phases 4–8, stable APIs, product components, renderer behavior, external providers/dependencies, and support claims unauthorized.

    - [x] 3.1.2 Task - Define the first event/effect contract envelope.

      - [x] 3.1.2.1 Subtask - Bind ADR-0001, ADR-0003, the Phase 2 completion decision, and the host-neutral architecture by path and SHA-256.
      - [x] 3.1.2.2 Subtask - Freeze semantic event version 1, exact event names/fields, source-owner lineage, sequence, portable payload, and stale-generation rules.
      - [x] 3.1.2.3 Subtask - Freeze four proof capabilities, operations, requirement/fallback states, effect/result fields, and provider-neutral denial/cancel/timeout behavior.
      - [x] 3.1.2.4 Subtask - Freeze opaque resource identity, ownership, transfer, cancellation, disposal, and owner-generation cleanup semantics.

  - [ ] 3.2 Section - Implement semantic events, bindings, and dispatch.

    Route validated user intent to a stateful component without exposing a
    concrete callback or host event.

    - [ ] 3.2.1 Task - Implement semantic event and binding data.

      - [ ] 3.2.1.1 Subtask - Add the exact version-1 event names and fields with portable map payloads, positive sequences, owner identity, and source-node lineage validation.
      - [ ] 3.2.1.2 Subtask - Add a semantic document that binds source identity plus event name to one owning component and rejects missing sources, wrong generations, duplicate bindings, and unbound dispatch.

    - [ ] 3.2.2 Task - Implement atomic stateful event dispatch.

      - [ ] 3.2.2.1 Subtask - Extend the component callback/evaluation context with a stateful event transition and opaque emissions while keeping Core independent of the effects package.
      - [ ] 3.2.2.2 Subtask - Preserve owner identity, increment revision, validate rerendered semantic output atomically, and reject pure targets, stale/wrong owners, malformed callbacks, and invalid output.
      - [ ] 3.2.2.3 Subtask - Test activation/change/select intent, binding lookup, portable payload limits, sequence, lineage, stale generation, and prior-evaluation retention.

  - [ ] 3.3 Section - Implement capability, effect, and resource lifecycle contracts.

    Make host authority and resource lifetime explicit as pure portable data
    before any concrete provider exists.

    - [ ] 3.3.1 Task - Implement capability negotiation and typed effects.

      - [ ] 3.3.1.1 Subtask - Add time, clipboard, file-choice, and storage capabilities with exact allowed operations, required/optional modes, and fail/omit/component fallbacks.
      - [ ] 3.3.1.2 Subtask - Deny by default, fail missing required capabilities without fallback, record optional/fallback outcomes, and reject duplicates or unknown capabilities.
      - [ ] 3.3.1.3 Subtask - Add typed effect requests/results and a provider behaviour without embedding a provider object or concrete host type.

    - [ ] 3.3.2 Task - Implement generation-scoped effect and resource tracking.

      - [ ] 3.3.2.1 Subtask - Track unique pending effect IDs and deterministic completion, denial, cancellation, timeout, and failure states without partial mutation.
      - [ ] 3.3.2.2 Subtask - Register opaque resource IDs, enforce owner/capability/generation checks, support explicit transfer, and make disposal idempotent.
      - [ ] 3.3.2.3 Subtask - Cancel pending effects and dispose active resources for an owner generation while rejecting stale completion, transfer, or disposal.

  - [ ] 3.4 Section - Run the Phase 3 integration gate and publish evidence.

    Exercise event-to-effect and resource-cleanup traces through the composed
    profile without invoking a concrete provider or renderer backend.

    - [ ] 3.4.1 Task - Add conformance and governance evidence.

      - [ ] 3.4.1.1 Subtask - Publish versioned event/effect/resource scenarios covering dispatch, denial/fallback, cancellation, timeout, transfer, stale generation, and owner cleanup.
      - [ ] 3.4.1.2 Subtask - Add fail-closed validation for authorization, hashes, exact vocabularies, ownership, fixture coverage, forbidden leakage, and premature Phase 4–8 claims.
      - [ ] 3.4.1.3 Subtask - Add negative tests for stale authority, expanded names/operations, provider leakage, missing lifecycle coverage, stable APIs, backend results, and support overclaims.

    - [ ] 3.4.2 Task - Execute and record the complete Phase 3 gate.

      - [ ] 3.4.2.1 Subtask - Run all seven Mix project tests/format checks, Phase 1–3 validators, archive validation, inherited validators, and patch hygiene.
      - [ ] 3.4.2.2 Subtask - Record tools, commands, hashes, section commits, limitations, and a truthful pass or stop decision.
      - [ ] 3.4.2.3 Subtask - Leave Phase 4 unauthorized and make no layout, accessibility, focus, renderer, browser, native, performance, or support claim.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 3.4 passes or records a stop decision. Phase 3 adds no external
dependency, provider implementation, renderer behavior, or stable API.

## Connections

- [BH-02 plan](README.md)
- [ADR-0001 — Host-neutral semantic component kernel](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [ADR-0003 — Host-neutral effects, capabilities, and resources](../../../20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [Host-neutral architecture](../../../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Foundational component semantics inquiry](../../../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)

## Sources

- [Phase 2 implementation evidence](phase-02-implementation-evidence.md)
- [BH-02 conditional entry manifest](../../../assets/bh-01-release/blazex-bh-02-entry-manifest-v0-1-0.md)
