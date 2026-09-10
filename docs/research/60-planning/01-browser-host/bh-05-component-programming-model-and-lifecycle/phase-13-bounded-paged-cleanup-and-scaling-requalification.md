---
title: "Phase 13 - Bounded Paged Cleanup and Scaling Requalification"
kind: note
created: "2026-09-10"
maturity: developing
tags:
  - atomvm
  - bh-05
  - cleanup
  - implementation-planning
  - reliability
  - scaling
aliases:
  - "BH-05 phase 13"
  - "BH-05 cleanup correction plan"
---

# Phase 13 - Bounded Paged Cleanup and Scaling Requalification

Back to milestone: [README](README.md)

- [ ] 13 Phase - Bounded Paged Cleanup and Scaling Requalification.

  Correct the Phase 12 Firefox terminal-state divergence by replacing
  per-resource helper-process cleanup with one bounded, runtime-owned cleanup
  session whose work and results are transferred in fixed pages. Preserve the
  frozen 1000 ms cleanup deadline, the 512-lease fixture, every failed trial,
  per-resource terminal evidence, and the existing public adapter contract.
  Add structural amplification counters, boundary-size measurements, payload
  stress, and fail-closed evidence validation so an endpoint pass cannot hide
  a similar scaling cliff elsewhere.

  This is a corrective re-entry phase, not a new feature phase. Phase 12 and
  its **revise** evidence remain immutable. BH-06 remains ineligible and
  unauthorized until this phase passes the complete BH-05 gate. Browser,
  platform, profile, public 1.0, and release support remain unqualified.
  LiveView and LocalLiveView remain **[DEFERRED]**, and unavailable external
  qualification remains **[DEFERRED]** to BH-22.

  - [x] 13.1 Section - Freeze the correction architecture and anti-concealment contract.

    Bind the exact algorithm, deadline semantics, scale matrix, counters, and
    decision rules before implementation or fresh qualification evidence is
    generated.

    - [x] 13.1.1 Task - Record bounded Phase 13 authority and provenance.

      Establish a source-bound corrective overlay without weakening or
      rewriting the Phase 12 decision.

      - [x] 13.1.1.1 Subtask - Record explicit Phase 13 authorization, synchronized `main`, feature branch, Phase 12 merge identity, section commits, one-PR rule, merge result, and final branch cleanup.
      - [x] 13.1.1.2 Subtask - Bind Phase 12 authorization, raw cleanup trials, reports, completion evidence, reconciliation, release decision, the recovery contract, and the exact failing Chrome/Firefox artifacts by path and SHA-256.
      - [x] 13.1.1.3 Subtask - Prohibit deadline increases, fixture reductions, browser exclusions, failed-sample deletion, timer-start movement, post-hoc page tuning, support promotion, and edits that relabel the Phase 12 `revise` outcome.

    - [x] 13.1.2 Task - Freeze the cleanup-session algorithm.

      Replace process-per-resource work with a constant-process protocol while
      preserving deterministic cleanup and per-resource truth.

      - [x] 13.1.2.1 Subtask - Open and monitor one runtime-owned normal cleanup session per root; use it for owner discovery, cancellation, component cleanup, lease release, and renderer disposal; transfer ordered jobs and results in pages of 64 entries with a hard protocol maximum of 128; and never spawn a helper process per job or lease.
      - [x] 13.1.2.2 Subtask - Execute existing adapter release callbacks in deterministic owner/resource order inside the session, return one correlated result vector per page, and retain an exact terminal status for every resource rather than treating a page as one atomic success.
      - [x] 13.1.2.3 Subtask - On callback failure, session exit, malformed reply, or deadline exhaustion, retain completed page results, kill and demonitor the session, classify every unacknowledged identity as unresolved, and run at most one separate forced-cleanup session over that exact remainder.
      - [x] 13.1.2.4 Subtask - Keep normal and forced sessions sequential, root-owned, non-link-leaking, and bounded to at most one live cleanup worker at a time and two worker starts for the whole disposal attempt.

    - [x] 13.1.3 Task - Freeze deadline, ordering, and terminal-state invariants.

      Make the correction observable without changing the semantic contract.

      - [x] 13.1.3.1 Subtask - Start the unchanged monotonic 1000 ms deadline at the disposal request before inventory, sorting, planning, session startup, callbacks, result collation, forced cleanup, and ledger finalization; every stage consumes the same remaining budget.
      - [x] 13.1.3.2 Subtask - Preserve deepest-root-first disposal, lease owner and generation checks, idempotent release, stale-result rejection, renderer/focus ordering, and the distinction between released, force-released, failed, timed-out, and unresolved terminal outcomes.
      - [x] 13.1.3.3 Subtask - Require success to mean both zero live terminal leases and zero unresolved identities; moving an unresolved lease to a lost/closed ledger collection must never manufacture a pass.

    - [x] 13.1.4 Task - Pre-register scaling and decision rules.

      Detect algorithmic knees and work amplification independently of a single
      wall-clock endpoint.

      - [x] 13.1.4.1 Subtask - Freeze canonical lease counts `0, 1, 63, 64, 65, 127, 128, 129, 255, 256, 257, 511, 512`, covering both sides of every page and power-of-two boundary without changing the 512-lease acceptance fixture.
      - [x] 13.1.4.2 Subtask - Freeze canonical payload runs at every count, maximum-portable payload runs at `64, 65, 256, 512`, and minimal-payload controls at `64` and `512`; bind exact identifier, owner, acquisition-metadata, result, and diagnostic size limits.
      - [x] 13.1.4.3 Subtask - Freeze one warmup followed by 20 retained ERTS samples at every boundary count and 100 retained ERTS samples at 512; retain 10 Chrome and 10 Firefox samples at every boundary count and 20 per browser at 512.
      - [x] 13.1.4.4 Subtask - Require zero unresolved identities in every retained active-runtime sample, the existing controlled ERTS p95 at or below 1000 ms, exact structural bounds, and no unexplained timing knee under the predeclared robust linear-residual rule.
      - [x] 13.1.4.5 Subtask - Define the timing-shape alarm before execution: for counts at least 64, fit retained per-runtime medians with a Theil-Sen line; any point above the prediction by more than the greater of 100 ms or 50% is a blocking scaling finding unless an independently reproduced bounded runtime discontinuity is recorded and the phase is revised rather than passed.

  - [x] 13.2 Section - Implement bounded paged cleanup sessions.

    Introduce the internal cleanup protocol and migrate recovery execution
    without expanding public component, renderer, effect, or adapter APIs.

    - [x] 13.2.1 Task - Implement the runtime-owned session protocol.

      Use one monitored worker and bounded messages rather than one monitored
      process and structured message exchange per resource.

      - [x] 13.2.1.1 Subtask - Add private request, page, result-vector, terminal-summary, cancellation, and malformed-reply forms with root, generation, sequence, page, and resource correlation.
      - [x] 13.2.1.2 Subtask - Stream at most 64 jobs into the worker and at most 64 correlated results back per message, reject duplicate/missing/out-of-order pages, and cap all decoded collections before allocation or callback execution.
      - [x] 13.2.1.3 Subtask - Reuse the existing per-resource release callback inside the worker so host adapters need no batch API and cannot infer that a whole page succeeded from a partial result.
      - [x] 13.2.1.4 Subtask - Bound session mailbox, reply count, retained result vectors, diagnostic bytes, and shutdown behavior under success, callback error, callback exit, malformed data, owner exit, and timeout.

    - [x] 13.2.2 Task - Integrate the session with recovery cleanup.

      Preserve the current recovery state machine while eliminating its
      process-per-resource amplification.

      - [x] 13.2.2.1 Subtask - Replace individual recovery-port calls across owner discovery, cancellation, component cleanup, lease release, and renderer disposal with one reusable normal session and ordered page dispatch under the single remaining-deadline value; merge page vectors into the existing per-resource cleanup report.
      - [x] 13.2.2.2 Subtask - Preserve acknowledged results across a failed page, compute the exact unacknowledged remainder once, and invoke one forced session without re-releasing already terminal resources.
      - [x] 13.2.2.3 Subtask - Finalize the ledger, renderer surface, focus outcome, generation, and root only after normal/forced result reconciliation; reject late session replies before any state or host mutation.
      - [x] 13.2.2.4 Subtask - Keep the internal change absent from public API manifests and prove application fixtures still import only documented BlazeX contracts.

    - [x] 13.2.3 Task - Unit-test protocol and recovery edge cases.

      Exercise page boundaries, partial progress, and termination before
      relying on browser timing.

      - [x] 13.2.3.1 Subtask - Test empty, single, exact-page, page-plus-one, multi-page, and 512-resource success with exact callback order, result identity, page count, and worker count.
      - [x] 13.2.3.2 Subtask - Inject failure, exit, malformed result, duplicate result, missing result, delay, and hang at the first, middle, and last position of both the first and a later page.
      - [x] 13.2.3.3 Subtask - Verify timeout kills/demonitors the worker, forced cleanup sees only the unresolved remainder, repeated disposal is idempotent, and late replies or stale generations cannot mutate state.

  - [x] 13.3 Section - Add structural scaling observability and shape gates.

    Measure why work scales, not only whether the final duration happened to
    fit under a threshold.

    - [x] 13.3.1 Task - Instrument cleanup stages and amplification.

      Emit bounded diagnostic counters and timings that explain process,
      message, callback, payload, and retained-state growth.

      - [x] 13.3.1.1 Subtask - Record monotonic durations for inventory, ordering/planning, normal session startup, each page, callback execution, result collation, forced session, ledger finalization, renderer disposal, and total cleanup.
      - [x] 13.3.1.2 Subtask - Record leases presented, pages sent/received, callbacks attempted/completed, normal/forced worker starts, peak live cleanup workers, protocol messages, encoded page bytes, terminal outcomes, and unresolved identities.
      - [x] 13.3.1.3 Subtask - Enforce structural bounds: normal worker starts at most one, total worker starts at most two, peak live cleanup workers at most one, successful lease pages exactly `ceil(resource_count / 64)`, total pages bounded by `ceil(total_job_count / 64)` plus fixed owner-discovery exchanges, callbacks at most once per normal/forced pass, and protocol messages proportional to pages rather than resources.
      - [x] 13.3.1.4 Subtask - Measure ERTS heap/process deltas and browser-AtomVM memory pages or the closest available counter; when an engine cannot expose a metric, record explicit unavailable instrumentation while retaining the mandatory structural counters.

    - [x] 13.3.2 Task - Build reusable scale-shape runners.

      Make boundary and payload matrices available to later milestones instead
      of embedding one-off assertions only in BH-05 acceptance code.

      - [x] 13.3.2.1 Subtask - Add a deterministic runner that executes the pre-registered count/payload matrix under ERTS, Chrome AtomVM, and Firefox AtomVM and emits one raw record per retained sample.
      - [x] 13.3.2.2 Subtask - Compute maxima, nearest-rank percentiles, medians, Theil-Sen slope/intercept, residual alarms, and structural amplification from raw records without discarding failures or outliers.
      - [x] 13.3.2.3 Subtask - Version the runner and schema for reuse by later queue, effect, resource, renderer, registry, and build-reachability budgets, with the workload dimension and structural counters supplied explicitly by each owner.

    - [x] 13.3.3 Task - Exercise adverse distribution shapes.

      Prevent a uniform happy-path fixture from hiding resource-size,
      position, or ownership cliffs.

      - [x] 13.3.3.1 Subtask - Run canonical, maximum-portable, and minimal payloads with one slow, failed, or hanging callback placed at page start, middle, and end and at the beginning, middle, and end of the total inventory.
      - [x] 13.3.3.2 Subtask - Run single-owner and maximally distributed-owner inventories while preserving the same total count, ordering rules, and deadline.
      - [x] 13.3.3.3 Subtask - Assert bounded failure blast radius, exact partial acknowledgements, exact forced remainder, no duplicate callbacks beyond the defined forced pass, zero stale mutations, and zero unexpected retained workers/messages.

  - [x] 13.4 Section - Make evidence semantics fail closed.

    Separate harness execution from semantic acceptance and make omissions or
    misleading summaries invalidate the evidence.

    - [x] 13.4.1 Task - Correct result and terminal-inventory reporting.

      Eliminate ambiguous `passed` labels and zero-live-ledger summaries that
      can coexist with unresolved cleanup work.

      - [x] 13.4.1.1 Subtask - Report `execution_state` separately from `acceptance_state`; a completed browser harness may be `executed` while cleanup acceptance is `failed`, but it may never emit an unconditional top-level `result: passed` when a required invariant fails.
      - [x] 13.4.1.2 Subtask - Require each summary to include live terminal leases, unresolved identities, lost/closed identities, normal and forced outcomes, deadline state, structural counters, scale point, payload class, sample identity, and raw-record hash.
      - [x] 13.4.1.3 Subtask - Preserve every Phase 12 failure and every Phase 13 attempt in append-only evidence; reruns add records and may not replace, omit, or relabel earlier observations.

    - [x] 13.4.2 Task - Add adversarial evidence validation.

      Prove that the gate rejects the same concealment mechanisms it forbids.

      - [x] 13.4.2.1 Subtask - Mutation-test deleted failures, missing scale points, reduced repetitions, changed deadline/page size, removed raw hashes, altered browser/runtime identity, and acceptance/execution-state substitution.
      - [x] 13.4.2.2 Subtask - Mutation-test unresolved-to-lost relabeling, zero-live-ledger-only claims, aggregate-page success masking one resource failure, omitted structural counters, and endpoint-only summaries.
      - [x] 13.4.2.3 Subtask - Require validators to recompute summaries and shape alarms from raw records, verify source/bundle/runtime identities, reject duplicate sample identities, and fail when required instrumentation is silently absent.

  - [x] 13.5 Section - Requalify active runtimes and reconcile BH-05.

    Run the frozen correction against the original blocker and the expanded
    scale corpus before reconsidering BH-05 acceptance.

    - [x] 13.5.1 Task - Execute the active-runtime correction matrix.

      Generate source-frozen results for ERTS/headless and both active Linux
      browser engines.

      - [x] 13.5.1.1 Subtask - Build fresh browser artifacts and run all count, payload, owner-distribution, and adverse-position observations under local ERTS/headless, Linux Chrome AtomVM/DOM, and Linux Firefox AtomVM/DOM.
      - [x] 13.5.1.2 Subtask - Re-run the original 512-resource Phase 12 fixture unchanged and require exact zero-unresolved Chrome/Firefox terminal inventories under the unchanged deadline in every retained sample.
      - [x] 13.5.1.3 Subtask - Run the 100-cycle process-growth corpus and require zero unexpected worker, message, lease, renderer, timer, request, or component-process retention.
      - [x] 13.5.1.4 Subtask - Preserve runtime/browser versions, AtomVM and bundle identities, source revision, clocks, raw outputs, failures, variance, unavailable metrics, and repeat context.

    - [x] 13.5.2 Task - Review the correction and shared scaling guard.

      Challenge correctness, portability, performance shape, security, and
      evidence integrity rather than accepting a faster endpoint alone.

      - [x] 13.5.2.1 Subtask - Review session ownership, link/monitor behavior, mailbox bounds, malformed-term handling, deadline arithmetic, partial-result reconciliation, forced cleanup, idempotency, and stale rejection on ERTS and AtomVM.
      - [x] 13.5.2.2 Subtask - Review process/message/payload amplification, boundary/payload coverage, regression method, raw-data retention, validator mutation tests, instrumentation limitations, and reuse requirements for later milestone budgets.
      - [x] 13.5.2.3 Subtask - Record every finding, disagreement, owner, severity, disposition, reproduction, and blocking effect; a passed 512-resource timing cannot close a structural, intermediate-size, or evidence-integrity finding.

    - [x] 13.5.3 Task - Reconcile the Phase 12 decision.

      Publish a successor overlay while keeping the original decision and raw
      evidence immutable.

      - [x] 13.5.3.1 Subtask - Map the Firefox blocker and every Phase 12 re-entry condition to exact Phase 13 implementation, tests, active-runtime raw records, structural counters, reviews, and validators.
      - [x] 13.5.3.2 Subtask - Regenerate the BH-05 release/acceptance overlay and BH-06 entry state only from canonical source-bound inputs, preserving all earlier failures and support limitations.
      - [x] 13.5.3.3 Subtask - Mark BH-05 accepted and BH-06 eligible-but-unauthorized only if every original gate and every Phase 13 anti-concealment gate passes; otherwise publish `revise` or `block` with exact re-entry requirements.

  - [x] 13.6 Section - Phase 13 integration tests and completion evidence.

    Rebuild and verify the entire BH-05 candidate plus the reusable scaling
    guard from a clean source-frozen state.

    - [x] 13.6.1 Task - Run the complete correction gate.

      Exercise implementation, regression, measurement, provenance, and
      archive checks as one reproducible decision pipeline.

      - [x] 13.6.1.1 Subtask - Run all activated Mix/Node tests and formatting/build checks, ERTS/headless and active Chrome/Firefox AtomVM/DOM suites, cleanup unit/failure cases, full boundary/payload matrices, the unchanged Phase 12 fixture, 100-cycle growth runs, and historical Phase 1–12 validators.
      - [x] 13.6.1.2 Subtask - Run structural-bound, timing-shape, raw-evidence, schema, mutation, source/bundle freshness, public/private API, dependency, archive, JSON, reciprocal-link, and patch-hygiene validators.
      - [x] 13.6.1.3 Subtask - Repeat the unchanged 512-resource fixture and a representative `64, 65, 256, 512` scaling subset from a second clean build/execution context; any mismatch remains a failure or explicit `revise`, never a discarded outlier.

    - [x] 13.6.2 Task - Publish completion evidence and decision.

      Record enough detail to reproduce the result and understand its scaling
      behavior without relying on a green summary label.

      - [x] 13.6.2.1 Subtask - Publish commands, tools/environments, source/artifact hashes, sample counts, raw records, stage timings, structural counters, shape models/alarms, terminal inventories, failures, findings, limitations, reviews, and exact gate outcomes.
      - [x] 13.6.2.2 Subtask - Verify every direct file is indexed, all generated artifacts reproduce byte-for-byte, every failed attempt remains linked, and the completion record binds the final source revision rather than an earlier measurement tree.
      - [x] 13.6.2.3 Subtask - Open one pull request only after the gate records a truthful outcome; after an authorized merge, synchronize `main` with `origin/main` before deleting the local and remote feature branch.

## Section delivery rule

Complete and verify each section before its own coherent commit. Open one pull
request only after Section 13.6 passes or records a truthful `revise`/`block`
decision. Do not tune page size or measurements after seeing results, move work
outside the deadline, increase the deadline, reduce the fixture, omit scale
points or failures, use an endpoint result to waive a structural alarm, or
infer browser/platform/profile/release support.

## Exit gate

Phase 13 passes only when the unchanged Phase 12 512-resource fixture and the
pre-registered scaling matrices produce exact zero-unresolved terminal
inventories on ERTS, Linux Chrome AtomVM, and Linux Firefox AtomVM; controlled
ERTS cleanup remains within the existing 1000 ms p95 budget; the cleanup
protocol satisfies every constant-worker and page-proportional-message bound;
no timing-shape alarm, process/message/resource retention, stale mutation,
missing evidence, or active review finding remains; and the complete BH-05 gate
reproduces from source-frozen inputs. A pass makes BH-06 eligible but does not
authorize it.

## Connections

- [BH-05 plan](README.md)
- [Phase 12](phase-12-reliability-measurement-review-and-bh-05-acceptance.md)
- [Phase 12 completion evidence](acceptance-evidence.md)
- [Acceptance reconciliation](acceptance-reconciliation.md)
- [Recovery contract](recovery-contract.md)
- [Final measurement and acceptance contract](acceptance-contract.md)
- [Quality budget and measurement policy](../../../20-notes/blazex-quality-budget-and-measurement-policy.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)

## Sources

- [Phase 12 raw acceptance evidence](../../../../../integration/bh-05/acceptance-cleanup-raw-v0.1.0.json)
- [Phase 12 acceptance gate](../../../assets/bh-05-baseline/acceptance-gates-v0.1.0.json)
- [Phase 12 completion record](../../../assets/bh-05-baseline/acceptance-completion-v0.1.0.json)
