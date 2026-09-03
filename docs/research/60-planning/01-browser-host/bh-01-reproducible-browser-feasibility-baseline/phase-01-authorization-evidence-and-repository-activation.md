---
title: "Phase 1 - Authorization, Evidence Governance, and Repository Activation"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - bh-01
  - evidence-governance
  - implementation-planning
  - repository-structure
aliases:
  - "BH-01 phase 1"
---

# Phase 1 - Authorization, Evidence Governance, and Repository Activation

Back to milestone: [README](README.md)

- [ ] 1 Phase - Authorization, Evidence Governance, and Repository Activation.

  Convert the conditional BH-01 handoff into an auditable start, establish
  evidence and stop authority, and activate only the repository boundaries
  needed for the feasibility baseline without installing dependencies yet.

  - [x] 1.1 Section - Record authority and inherited contract truth.

    Implementation must start from an explicitly approved plan and the exact
    accepted BH-00 baseline rather than inferring permission from scaffolding.

    - [x] 1.1.1 Task - Record the separate BH-01 plan approval.

      The approval record must identify what was reviewed, who may begin, and
      which conditions remain binding.

      - [x] 1.1.1.1 Subtask - Record repository-owner approval date, approved plan revision, accountable milestone owner, specialist roles, conditions, and authorization scope.
      - [x] 1.1.1.2 Subtask - Verify work starts from synchronized `main` on a dedicated branch and that approval does not authorize BH-02, product support, or stable framework APIs.

    - [x] 1.1.2 Task - Snapshot the inherited BH-00 baseline.

      All later evidence must cite the immutable product contract it tests.

      - [x] 1.1.2.1 Subtask - Record `BX-BH00-BASELINE-0.1.0`, `BX-BH01-ENTRY-0.1`, source-manifest hash, governance status, and zero accepted exceptions.
      - [x] 1.1.2.2 Subtask - Import all eight input groups, ten proof obligations, eight risks, five stop conditions, prohibited actions, owner roles, and linked acceptance/budget IDs into a milestone ledger.
      - [x] 1.1.2.3 Subtask - Fail activation when a bound BH-00 source, generated view, main revision, approval record, or entry condition is stale or incomplete.

  - [x] 1.2 Section - Establish evidence, finding, and stop/go governance.

    Define how executable facts are captured, reviewed, invalidated, and used
    to stop the baseline before implementation produces ambiguous claims.

    - [x] 1.2.1 Task - Define canonical evidence records.

      Every result needs stable provenance from requirement to environment,
      command, artifact, observation, review, and outcome.

      - [x] 1.2.1.1 Subtask - Define evidence IDs and schemas for environment fingerprints, commands, logs, artifacts, scenarios, traces, measurements, reviews, findings, risks, exceptions, and decisions.
      - [x] 1.2.1.2 Subtask - Require source revision, owner, timestamp, tool identity, input/output hashes, raw evidence, normalization, limitation, supersession, retention, and reciprocal requirement links.
      - [x] 1.2.1.3 Subtask - Distinguish planned, observed, passed, failed, blocked, conditional, unsupported, untested, superseded, and invalidated states without allowing plan completion to count as product evidence.

    - [x] 1.2.2 Task - Assign finding and stop authority.

      Critical failures must halt downstream phases unless a reviewed plan
      amendment explicitly changes the candidate or affected proof.

      - [x] 1.2.2.1 Subtask - Assign owners and escalation paths for dependency access, reproducibility, runtime semantics, artifacts, private APIs, browser prerequisites, authenticated commands, and mobile viability.
      - [x] 1.2.2.2 Subtask - Define finding severity, blocker rules, stop records, affected evidence invalidation, bounded mitigation review, and prohibition on silently weakening thresholds or scenarios.
      - [x] 1.2.2.3 Subtask - Require explicit reapproval for changes to runtime substrate, server stack, activation boundary, proof method, browser matrix, quality threshold, or stop condition.

  - [ ] 1.3 Section - Activate the minimal repository slice.

    Initialize project boundaries and test harness locations only after approval,
    preserving dependency direction and keeping feasibility code disposable.

    - [ ] 1.3.1 Task - Activate owned runtime, host, renderer, and server packages.

      Each package receives one narrow responsibility and no placeholder public
      component or semantic-kernel contract.

      - [ ] 1.3.1.1 Subtask - Initialize manifests, module roots, ownership metadata, and test entry points for `blazex_runtime_popcorn`, `blazex_host_browser`, and `blazex_renderer_dom`.
      - [ ] 1.3.1.2 Subtask - Initialize `blazex_renderer_dom_liveview` and `blazex_phoenix` with their optional-adapter and server-authority boundaries explicit.
      - [ ] 1.3.1.3 Subtask - Mark every new module/API experimental and prohibit imports from inactive BH-02 core, effects, UI-tree, renderer-contract, headless, component-family, or native packages.

    - [ ] 1.3.2 Task - Activate the browser loader and executable profile.

      JavaScript and the Phoenix profile are outer adapters, not containers for
      reusable component behavior.

      - [ ] 1.3.2.1 Subtask - Initialize `js/blazex_runtime` with a pinned package-manager choice, module/build/test entry points, and explicit browser-bridge-only scope.
      - [ ] 1.3.2.2 Subtask - Initialize `profiles/browser_phoenix` with composition, endpoint, asset, development/test/release, and teardown boundaries but no candidate dependencies installed.
      - [ ] 1.3.2.3 Subtask - Prohibit component logic, server authorization, arbitrary script escape, or generic DOM ownership in the JavaScript loader and prohibit reusable runtime/renderer behavior in the profile.

    - [ ] 1.3.3 Task - Activate integration evidence locations and dependency guards.

      Scenarios and measurements need durable homes while future portable
      packages remain inactive and independently inspectable.

      - [ ] 1.3.3.1 Subtask - Initialize schemas and indexes under `integration/fixtures` and `integration/benchmarks` for scenarios, raw evidence, environment fingerprints, samples, and generated reports.
      - [ ] 1.3.3.2 Subtask - Add manifest/source graph checks for allowed edges, forbidden reverse dependencies, package ownership, standalone DOM independence, and Plug/headless exclusions.
      - [ ] 1.3.3.3 Subtask - Assert that no new manifest or implementation exists in BH-02 kernel/headless/native boundaries and that fixture code cannot be imported as a production dependency.
      - [ ] 1.3.3.4 Subtask - Document the exact nine activated boundaries and the review required to add, merge, or relocate one.

  - [ ] 1.4 Section - Phase 1 Integration Tests and Completion Evidence.

    Prove approval, evidence governance, repository ownership, and activation
    limits before dependency acquisition begins.

    - [ ] 1.4.1 Task - Test authorization and evidence fail-closed behavior.

      Controlled negative cases must demonstrate that stale or unauthorized
      starts cannot partially activate the milestone.

      - [ ] 1.4.1.1 Subtask - Validate plan/archive links, approval identity, BH-00 hashes, input/proof/risk ledgers, evidence schemas, and owner assignments.
      - [ ] 1.4.1.2 Subtask - Exercise missing approval, stale main, stale BH-00 source, incomplete ledger, unowned blocker, and unreviewed plan-change cases and verify actionable failure with no dependency acquisition.

    - [ ] 1.4.2 Task - Test repository boundaries and publish phase evidence.

      The activated skeleton must exactly match the approved slice and contain
      no hidden framework or support claim.

      - [ ] 1.4.2.1 Subtask - Run package/profile inventory, manifest ownership, dependency graph, forbidden-token, inactive-boundary, fixture-import, and patch hygiene checks.
      - [ ] 1.4.2.2 Subtask - Confirm only approved manifests/skeletons changed, no dependency was installed or locked, and all browsers/runtime behaviors remain unexecuted.
      - [ ] 1.4.2.3 Subtask - Publish Phase 1 evidence with revisions, approval, commands, validation output, findings, stop/go result, limitations, and exact authorization for Phase 2.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase only after the final integration section passes or records a
truthful stop decision. Do not acquire candidate dependencies in Phase 1.

## Connections

- [BH-01 plan](README.md)
- [BH-01 entry manifest](../../../assets/bh-00-release/blazex-bh-01-entry-manifest-v0-1-0.md)
- [Repository ownership map](../../../10-maps/blazex-repository-ownership-and-dependency-map.md)

## Sources

- [BH-00 governance contract](../../../assets/bh-00-release/blazex-bh-00-governance-v0.1.0.json)
