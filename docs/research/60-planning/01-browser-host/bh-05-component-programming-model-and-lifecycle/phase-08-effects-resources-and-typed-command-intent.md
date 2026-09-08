---
title: "Phase 8 - Effects, Resources, and Typed Command Intent"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-05
  - commands
  - effects
  - implementation-planning
  - resources
aliases:
  - "BH-05 phase 8"
---

# Phase 8 - Effects, Resources, and Typed Command Intent

Back to milestone: [README](README.md)

- [ ] 8 Phase - Effects, Resources, and Typed Command Intent.

  Replace generic component emissions with closed local-message, timer,
  capability-effect, resource, and remote-command intent records. Enforce
  admission, ordering, ownership, cancellation, timeout, stale-result, and
  trust boundaries while reserving actual browser providers and server command
  execution for their owning adapters.

  - [ ] 8.1 Section - Authorize and freeze action and authority semantics.

    Bind scheduler and effects contracts and define every action/result class
    before integrating providers or command adapters.

    - [ ] 8.1.1 Task - Record bounded Phase 8 authority.

      Establish provenance and prohibit concrete server/browser implementation
      or trust from entering Core.

      - [ ] 8.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 7 completion identity, and explicit Phase 8 authorization.
      - [ ] 8.1.1.2 Subtask - Bind callback result algebra, scheduler, effect/capability/resource contracts, server trust ADR, renderer barriers, diagnostics, and pending/resource budgets by version and hash.
      - [ ] 8.1.1.3 Subtask - Exclude concrete Web API providers, Phoenix/Plug command transport/authorization, uploads, navigation, persistence, arbitrary tasks, and support claims.

    - [ ] 8.1.2 Task - Freeze typed action and result vocabulary.

      Distinguish local work, host capability requests, resource leases, and
      remote authority crossings in both data and lifecycle.

      - [ ] 8.1.2.1 Subtask - Define closed action records for local message, timer start/cancel, effect request/cancel, resource transfer/release, and typed command intent with stable IDs and schema versions.
      - [ ] 8.1.2.2 Subtask - Define effect/command accepted, denied, completed, failed, timed-out, canceled, stale, and disconnected results plus resource acquired/transferred/released/lost states.
      - [ ] 8.1.2.3 Subtask - Define ordering relative to semantic and renderer commit, idempotency/replay policy, root/component/generation ownership, payload bounds, redaction, and maximum 128 pending effects/512 leases.

  - [ ] 8.2 Section - Implement typed action validation and effect scheduling.

    Validate candidate actions before state/output commit and submit accepted
    post-commit work only to negotiated abstract providers.

    - [ ] 8.2.1 Task - Implement action constructors and callback validation.

      Replace `[term()]` emissions with versioned records that cannot conceal
      browser objects, server work, PIDs, or arbitrary functions.

      - [ ] 8.2.1.1 Subtask - Implement strict typed constructors, schemas, counts, payload bounds, owner/source correlation, capability/command IDs, timeout, cancellation, and fallback metadata.
      - [ ] 8.2.1.2 Subtask - Validate all candidate actions together with state/output and reject unknown, malformed, excessive, wrong-owner, nonportable, unauthorized, or duplicate identities atomically.
      - [ ] 8.2.1.3 Subtask - Preserve action metadata for BH-06 build reachability and BH-07 command registration without resolving arbitrary modules or transports at runtime.

    - [ ] 8.2.2 Task - Integrate effect admission and result scheduling.

      Submit effects only after the accepted commit barrier and route bounded
      results back through the root scheduler.

      - [ ] 8.2.2.1 Subtask - Negotiate declared capabilities deny-by-default, admit no more than 128 pending effects per root, and record provider/fallback selection without exposing provider handles.
      - [ ] 8.2.2.2 Subtask - Schedule accepted results/timeouts/cancellations as typed generation-scoped work and reject duplicate, late, stale, wrong-owner, or post-disposal results before callbacks.
      - [ ] 8.2.2.3 Subtask - Never automatically replay non-idempotent effects after renderer rejection, root crash/retry, runtime loss, or reconnect.

  - [ ] 8.3 Section - Implement resource and command-intent boundaries.

    Track opaque resource leases and represent remote work as untrusted intent
    awaiting a future authenticated server adapter.

    - [ ] 8.3.1 Task - Integrate resource leases with component ownership.

      Give every resource one root generation and component owner with explicit
      transfer/release and terminal state.

      - [ ] 8.3.1.1 Subtask - Admit at most 512 simultaneous leases per root and inventory kind, opaque ID, owner, generation, acquisition effect, transfer history, release request, and terminal outcome.
      - [ ] 8.3.1.2 Subtask - Validate transfers within declared ownership rules and reject cross-root, stale-generation, duplicate, unknown, or post-disposal release/result operations.
      - [ ] 8.3.1.3 Subtask - Queue release/cancellation on nested removal/replacement and root shutdown/failure for Phase 10 disposal coordination.

    - [ ] 8.3.2 Task - Implement typed remote-command intent.

      Define what a component may request without granting client state any
      server authority or implementing a transport.

      - [ ] 8.3.2.1 Subtask - Define stable command ID, schema version, public payload, correlation/idempotency key, timeout, optimistic-state metadata, and expected public result/error schema.
      - [ ] 8.3.2.2 Subtask - Mark every command intent as untrusted client input and require future server authentication, authorization, validation, idempotency, auditing, and result normalization.
      - [ ] 8.3.2.3 Subtask - Reject arbitrary module/function targets, server PIDs/sockets, credentials/secrets, client authorization decisions, and direct transport selection in portable component code.

  - [ ] 8.4 Section - Phase 8 Integration Tests and Completion Evidence.

    Exercise delayed/denied effects, lease-heavy components, command intents,
    stale results, bounds, and commit ordering through deterministic providers
    and server-adapter doubles.

    - [ ] 8.4.1 Task - Run effects/resources/commands integration tests.

      Verify typed action traces and final state without invoking real
      privileged browser or server behavior.

      - [ ] 8.4.1.1 Subtask - Test capability allow/deny/fallback, effect completion/failure/timeout/cancel, post-commit submission, delayed result, nested owner removal, resource acquire/transfer/release, and command-intent creation.
      - [ ] 8.4.1.2 Subtask - Drive more than 128 pending effects and 512 leases and prove bounded rejection; test stale/duplicate/late/wrong-owner results and non-idempotent no-replay behavior.
      - [ ] 8.4.1.3 Subtask - Prove command records remain untrusted declarative intent, contain no transport/server authority, and can be denied by a deterministic future-adapter double without corrupting local state.

    - [ ] 8.4.2 Task - Publish Phase 8 completion evidence.

      Record action schemas, pending/resource maxima, trust analysis, and
      unresolved concrete-provider/command work.

      - [ ] 8.4.2.1 Subtask - Run Core/effects/UI-tree/renderer/test suites, delayed/denied/lease/command fixtures, validators, dependency/security audits, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 8.4.2.2 Subtask - Publish action/result inventories, raw pending/resource traces, fixture hashes, exact commands/counts, denial/timeout/cancel outcomes, failures, and limitations.
      - [ ] 8.4.2.3 Subtask - Mark Phase 8 complete only if all work is typed, bounded, generation-scoped, and authority-correct; make Phase 9 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 8.4 passes or records a stop decision. Generic emissions,
provider/server handles, client-granted authority, unbounded pending work, or
automatic non-idempotent replay blocks completion.

## Connections

- [BH-05 plan](README.md)
- [Phase 7](phase-07-event-message-timer-and-transition-scheduling.md)
- [Host-neutral effects, capabilities, and resources](../../../20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [Server adapter and trust boundary](../../../20-notes/architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md)

## Sources

- [BH-02 event/effect/resource fixtures](../../../../../integration/conformance/event-effect-resource-fixtures-v0.1.0.json)
- [Canonical acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
