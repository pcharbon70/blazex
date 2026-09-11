---
title: "Phase 15 - Runtime-Owned Resource Inventory and Maximum-Payload Requalification"
kind: note
created: "2026-09-11"
maturity: developing
tags:
  - atomvm
  - bh-05
  - cleanup
  - implementation-planning
  - reliability
  - resource-ownership
aliases:
  - "BH-05 phase 15"
  - "BH-05 runtime-owned resource correction"
---

# Phase 15 - Runtime-Owned Resource Inventory and Maximum-Payload Requalification

Back to milestone: [README](README.md)

- [ ] 15 Phase - Runtime-Owned Resource Inventory and Maximum-Payload Requalification.

  Correct `BH05-P14-MAXIMUM-PAYLOAD-TRANSFER` by transferring each complete
  release descriptor to one bounded runtime-owned cleanup session when the
  lease is acquired or transferred. Disposal sends only ordered compact lease
  identities to that already-live session. Preserve the 1000 ms deadline, all
  count/payload/repetition fixtures, page size 64, maximum page size 128,
  exact terminal outcomes, timeout isolation, and append-only failed evidence.

  The repository owner authorized this work on 2026-09-11. It starts from
  synchronized `main` at `69e017a9b87105b6f27a086d16978d8c0c2fca05` on
  `codex/bh05-phase15-runtime-owned-resource-inventory`. Delivery requires one
  commit per section, one pull request, its authorized merge, synchronization
  of `main` with `origin/main`, and deletion of the local and remote feature
  branch. BH-06 remains ineligible and unauthorized until this phase passes.
  LiveView and LocalLiveView remain **[DEFERRED]**.

  - [x] 15.1 Section - Freeze resource ownership and corrective authority.
    - [x] 15.1.1 Task - Bind Phase 14 inputs and immutable constraints.
      - [x] 15.1.1.1 Subtask - Record source, branch, section commits, one PR, merge authority, and cleanup workflow.
      - [x] 15.1.1.2 Subtask - Bind the Phase 14 decision, completion, attempt ledger, and affected sources by path and SHA-256.
      - [x] 15.1.1.3 Subtask - Prohibit deadline increases, fixture/repetition reductions, browser exclusions, failed-sample deletion, support promotion, and disposal-time preloading.
    - [x] 15.1.2 Task - Freeze the runtime-owned inventory contract.
      - [x] 15.1.2.1 Subtask - Open one bounded session per configured action runtime and register complete release descriptors as acquisition or transfer commits.
      - [x] 15.1.2.2 Subtask - Keep root-ledger truth and provider-release data correlated by stable lease identity without exposing the internal owner through snapshots or public APIs.
      - [x] 15.1.2.3 Subtask - Require compact identity-only normal release pages, exact acknowledgements, bounded capacity, and full-descriptor forced recovery only for the unresolved remainder.

  - [x] 15.2 Section - Implement the bounded owned-inventory protocol.
    - [x] 15.2.1 Task - Extend the recovery session with inventory commands.
      - [x] 15.2.1.1 Subtask - Add bounded register, replace, drop, inventory-count, and identity-release commands with correlated acknowledgements.
      - [x] 15.2.1.2 Subtask - Validate identities/descriptors before mutation and reject missing, duplicate, malformed, oversized, or out-of-order requests atomically.
      - [x] 15.2.1.3 Subtask - Retain at most 512 descriptors and clear acknowledged terminal entries without returning acquisition payloads.
    - [x] 15.2.2 Task - Prove protocol lifecycle and isolation.
      - [x] 15.2.2.1 Subtask - Test owner exit, explicit close, timeout, malformed replies, inventory mismatch, exact release ordering, and no leaked process or mailbox state.
      - [x] 15.2.2.2 Subtask - Measure registration separately from timed cleanup and reset only cleanup counters while retaining owned descriptors.
      - [x] 15.2.2.3 Subtask - Keep the protocol inside Core and the existing adapter release contract unchanged.

  - [ ] 15.3 Section - Integrate acquisition, transfer, release, and recovery.
    - [ ] 15.3.1 Task - Attach the owner to action-runtime lifecycle transitions.
      - [ ] 15.3.1.1 Subtask - Create the session with valid action runtime configuration and close it on rejected initialization or terminal shutdown.
      - [ ] 15.3.1.2 Subtask - Register newly acquired leases, replace transferred descriptors, and drop explicitly released leases only after the matching ledger transition succeeds.
      - [ ] 15.3.1.3 Subtask - Preserve portable snapshots, stale rejection, idempotency, pruning, and timeout behavior.
    - [ ] 15.3.2 Task - Use compact identities during normal disposal.
      - [ ] 15.3.2.1 Subtask - Reuse the already-live session and dispatch ordered identity pages under the original deadline.
      - [ ] 15.3.2.2 Subtask - Reconcile exact compact outcomes and retain root-ledger descriptors for only the exact forced remainder.
      - [ ] 15.3.2.3 Subtask - Fall back fail-closed when the session is absent, dead, divergent, or malformed without manufacturing completion.

  - [ ] 15.4 Section - Extend structural and anti-concealment gates.
    - [ ] 15.4.1 Task - Measure ownership-transfer and disposal amplification.
      - [ ] 15.4.1.1 Subtask - Record registration messages/bytes, compact release request bytes, inventory counts, descriptor bytes unavailable states, pages, callbacks, and workers.
      - [ ] 15.4.1.2 Subtask - Require disposal request bytes to scale with identities rather than acquisition payload size and normal worker starts during disposal to remain zero for configured runtimes.
      - [ ] 15.4.1.3 Subtask - Retain Phase 13/14 outcome, timing, process, message, payload, growth, and shape counters.
    - [ ] 15.4.2 Task - Make ownership evidence fail closed.
      - [ ] 15.4.2.1 Subtask - Mutation-test missing registration, inventory drift, payload reintroduction, count mismatch, masked failure, and disposal-time preload.
      - [ ] 15.4.2.2 Subtask - Recompute terminal inventories, summaries, and request-size bounds from raw records.
      - [ ] 15.4.2.3 Subtask - Preserve Phase 12-14 failures and distinguish lifecycle registration cost from timed cleanup cost.

  - [ ] 15.5 Section - Requalify active runtimes and reconcile BH-05.
    - [ ] 15.5.1 Task - Execute the source-frozen correction matrix.
      - [ ] 15.5.1.1 Subtask - Run ERTS/headless and Linux Chrome/Firefox AtomVM/DOM matrices, maximum payloads, adverse cases, and growth cases.
      - [ ] 15.5.1.2 Subtask - Require every retained active sample within 1000 ms with zero live and unresolved leases and exact inventory convergence.
      - [ ] 15.5.1.3 Subtask - Preserve source/bundle/runtime identities, raw failures, variance, counters, and unavailable metrics.
    - [ ] 15.5.2 Task - Review and reconcile the successor decision.
      - [ ] 15.5.2.1 Subtask - Review correctness, ownership, portability, performance, malformed input, evidence, security, and compatibility.
      - [ ] 15.5.2.2 Subtask - Map every Phase 14 re-entry condition and new ownership finding to evidence.
      - [ ] 15.5.2.3 Subtask - Accept only when all frozen gates pass; otherwise record revise or block.

  - [ ] 15.6 Section - Run the full integration gate and publish completion.
    - [ ] 15.6.1 Task - Rebuild and verify the complete candidate.
      - [ ] 15.6.1.1 Subtask - Run package, conformance, browser, formatting, archive, provenance, dependency, and hygiene gates.
      - [ ] 15.6.1.2 Subtask - Repeat maximum-payload 512 and `64, 65, 256, 512` from a second clean context.
      - [ ] 15.6.1.3 Subtask - Verify indexing, source binding, public API stability, and historical immutability.
    - [ ] 15.6.2 Task - Publish and deliver one successor pull request.
      - [ ] 15.6.2.1 Subtask - Publish commands, environments, hashes, samples, timings, inventories, findings, limitations, and decision.
      - [ ] 15.6.2.2 Subtask - Open one PR only after recording a truthful decision.
      - [ ] 15.6.2.3 Subtask - After merge, sync `main`, then delete local and remote feature branches.

## Exit gate

Phase 15 passes only when acquisition-time ownership is exact and bounded,
normal disposal pages contain compact identities and no acquisition payload,
forced cleanup retains the exact unresolved descriptors, every retained
ERTS/Chrome/Firefox sample has zero unresolved identities and stays within the
unchanged deadline, and the complete source-frozen BH-05 gate reproduces.

## Bound inputs

| Input | SHA-256 |
| --- | --- |
| `phase-14-review-and-reconciliation.md` | `def9e20a5dcc3235effb641e29b4bba41965ce33460c84128514a738dbb59d25` |
| `phase-14-completion.md` | `9c3fef8fc412b311ad167558704228c21345d5c3df981c279217279b7bc0dddc` |
| `integration/bh-05/compact-cleanup-attempts-v0.1.0.json` | `e553ad23e6cd04c475bd8f1c1fcea8727f0805ab57ddc85e4767c76ab9afc484` |
| `action_runtime.ex` | `0501e918bdb3e752ff52d1e43bac9b829eb4d965abc0c4380ee14fcc9884f9f6` |
| `action_ledger.ex` | `01ef100a74fb0db1fb893079e710fd343f4367c359736f8eccb9dba074788d13` |
| `recovery_cleanup.ex` | `fa5ec9e7dfce7118419e9d9ca0d9e74e3e10bf745fe9a1a35bad51d4f00a3cb0` |
| `recovery_port.ex` | `e4308f3f0a6cc804690934a35f253973910dfc0749bd2862e1f70389fd0b8226` |

## Connections

- [Runtime-owned resource inventory contract](runtime-owned-resource-inventory-contract.md)
- [Phase 14 review](phase-14-review-and-reconciliation.md)
- [Phase 14 completion](phase-14-completion.md)
- [Cleanup scaling contract](cleanup-scaling-contract.md)
- [Recovery contract](recovery-contract.md)
- [Development and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
