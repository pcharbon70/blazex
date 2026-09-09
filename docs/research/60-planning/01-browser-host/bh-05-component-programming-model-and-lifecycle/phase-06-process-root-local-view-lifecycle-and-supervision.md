---
title: "Phase 6 - Process-Root Local View Lifecycle and Supervision"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-05
  - component-model
  - implementation-planning
  - local-view
  - supervision
aliases:
  - "BH-05 phase 6"
---

# Phase 6 - Process-Root Local View Lifecycle and Supervision

Back to milestone: [README](README.md)

- [ ] 6 Phase - Process-Root Local View Lifecycle and Supervision.

  Implement the independently supervised local-view root that owns one
  component tree, mailbox, generation, transition coordinator, renderer root,
  effects/resources, fallback, and final state. Preserve dependency direction
  through abstract evaluator and commit ports rather than importing concrete
  UI-tree, renderer, host, or runtime implementations into Core.

  - [x] 6.1 Section - Authorize and freeze root lifecycle semantics.

    Bind nested component state plus BH-03/BH-04 root and renderer contracts,
    then define process states and commit ownership before starting processes.

    - [x] 6.1.1 Task - Record bounded Phase 6 authority.

      Establish provenance and keep full event/message/effect scheduling and
      retry policy outside this phase.

      - [x] 6.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 5 completion, accepted BH-03/BH-04 contract identities, and explicit Phase 6 authorization.
      - [x] 6.1.1.2 Subtask - Bind local-view role, nested state, host/root lifecycle, renderer transaction/acknowledgement, semantic evaluator, diagnostics, and supervision assumptions by version and hash.
      - [x] 6.1.1.3 Subtask - Exclude general event backlog, user `handle_info`, timers, effect/command execution, context/registry, automatic retry, and support claims.

    - [x] 6.1.2 Task - Freeze process, transition, and commit states.

      Define legal root states and ensure candidate component state becomes
      final only after semantic and renderer acceptance.

      - [x] 6.1.2.1 Subtask - Define dormant, starting, mounting, evaluating, awaiting-commit, ready, updating, replacing, stopping, disposed, and failed states with legal transitions.
      - [x] 6.1.2.2 Subtask - Define root instance/generation/revision/sequence, accepted and candidate component tables, semantic output, renderer root/transaction correlation, and final-state digest ownership.
      - [x] 6.1.2.3 Subtask - Define process start/registration, one in-flight state transition, semantic reject, renderer reject/rollback, commit, host removal, shutdown, crash, and terminal acknowledgement behavior.

  - [x] 6.2 Section - Define evaluator, renderer-commit, and host lifecycle ports.

    Preserve the inward package graph by defining narrow Core-facing contracts
    implemented by UI-tree, renderer/runtime, and host packages outwardly.

    - [x] 6.2.1 Task - Define the evaluator and commit interfaces.

      Pass immutable portable transition envelopes and receive validated,
      correlated results without concrete adapter types.

      - [x] 6.2.1.1 Subtask - Define evaluator requests/results for mount, parent-prop update, candidate render, replacement, and disposal planning over public Core records.
      - [x] 6.2.1.2 Subtask - Define semantic acceptance and renderer submission/acknowledgement interfaces with root/generation/revision/transaction correlation and stable failure classes.
      - [x] 6.2.1.3 Subtask - Prohibit callback modules from receiving port implementations, PIDs, renderer objects, DOM handles, host instances, or framework state.

    - [x] 6.2.2 Task - Define host and supervision interfaces.

      Let runtime/host compositions start and stop roots while Core retains the
      portable lifecycle meaning.

      - [x] 6.2.2.1 Subtask - Define root start specification, validated bootstrap props, public component ID/module, root identity, fallback contract, capability summary, and owner correlation.
      - [x] 6.2.2.2 Subtask - Define root registration/readiness/removal/shutdown/crash notifications and supervisor child identity without binding to browser or Popcorn structures.
      - [x] 6.2.2.3 Subtask - Define monitoring/introspection records with bounded redacted state and prohibit public exposure of root PIDs as mutable component references.

  - [x] 6.3 Section - Implement the root process and basic supervised lifecycle.

    Start, mount, update, commit, replace, and stop one root through the abstract
    ports while preserving accepted state on failed candidates.

    - [x] 6.3.1 Task - Implement root startup and transition coordination.

      Own one immutable lifecycle state and execute callbacks only through the
      selected public component/evaluator contracts.

      - [x] 6.3.1.1 Subtask - Validate start input, initialize generation/revision, invoke mount evaluation, submit accepted semantic output, and publish readiness only after correlated renderer commit.
      - [x] 6.3.1.2 Subtask - Process validated parent-prop updates and explicit replacement as serialized candidate transitions with no state advance before commit.
      - [x] 6.3.1.3 Subtask - Handle semantic rejection, renderer rejection/rollback, stale/duplicate acknowledgement, host removal, and startup timeout without publishing false readiness or partial final state.

    - [x] 6.3.2 Task - Implement supervision and deterministic stop.

      Integrate with ERTS and AtomVM-supported supervision primitives while
      keeping policy and restart execution separately governed.

      - [x] 6.3.2.1 Subtask - Provide a deterministic child specification and runtime-facing start/stop interface for uniquely identified roots.
      - [x] 6.3.2.2 Subtask - On normal stop/replacement/removal, invalidate admission, reject new work, coordinate renderer disposal, run nested disposal planning, and terminate exactly once.
      - [x] 6.3.2.3 Subtask - On crash, preserve redacted crash/generation metadata for the supervisor and ensure sibling roots/processes remain alive without automatically replaying work.

  - [ ] 6.4 Section - Phase 6 Integration Tests and Completion Evidence.

    Exercise basic supervised root lifecycle with deterministic evaluator and
    renderer doubles plus accepted BH-04 integration where available.

    - [ ] 6.4.1 Task - Run local-view lifecycle integration tests.

      Cover success, rejection, stale acknowledgement, process crash, sibling
      isolation, and normal stop through public runtime-facing contracts.

      - [ ] 6.4.1.1 Subtask - Test start/mount/commit/readiness, parent update/no-op/commit, replace/new generation, host removal, renderer disposal, stop, and remount.
      - [ ] 6.4.1.2 Subtask - Test invalid bootstrap, mount/update/render failure, semantic rejection, renderer rejection/rollback, acknowledgement loss/duplicate/stale, startup timeout, and crash before/after commit.
      - [ ] 6.4.1.3 Subtask - Prove accepted state/output/final digest advances only on commit, sibling roots survive, no public PID/adapter object leaks, and stop is idempotent.

    - [ ] 6.4.2 Task - Publish Phase 6 completion evidence.

      Record the lifecycle state machine, port contracts, supervision subset,
      and unresolved scheduling/retry/resource behavior.

      - [ ] 6.4.2.1 Subtask - Run Core/UI-tree/renderer/headless/test and applicable BH-04 suites, lifecycle fixtures, dependency audits, validators, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 6.4.2.2 Subtask - Publish transition tables, public contract inventories, trace hashes, exact commands/counts, crash/rejection outcomes, ERTS/AtomVM compatibility analysis, failures, and limitations.
      - [ ] 6.4.2.3 Subtask - Mark Phase 6 complete only if final state and readiness are commit-correlated and roots are independently supervised; make Phase 7 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 6.4 passes or records a stop decision. A ready root with an
uncommitted renderer state, cross-root crash, reverse dependency, or public
mutable PID/adapter handle blocks completion.

## Connections

- [BH-05 plan](README.md)
- [Phase 5](phase-05-nested-stateful-identity-and-update-reconciliation.md)
- [Host-neutral component-kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)

## Sources

- [BH-02 renderer lifecycle fixtures](../../../../../integration/conformance/renderer-headless-fixtures-v0.1.0.json)
- [Foundational component-semantics inquiry](../../../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
