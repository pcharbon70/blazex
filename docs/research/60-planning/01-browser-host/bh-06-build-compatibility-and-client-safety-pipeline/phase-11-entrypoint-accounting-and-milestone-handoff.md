---
title: "BH-06 Phase 11 - Entrypoint Accounting and Milestone Handoff"
kind: note
created: "2026-09-12"
maturity: developing
tags: [attestation, bh-06, build, entrypoint, handoff]
aliases: ["BH-06 phase 11"]
---

# BH-06 Phase 11 - Entrypoint Accounting and Milestone Handoff

Back to the [milestone](README.md).

- [x] 11 Phase - Entrypoint Accounting and Milestone Handoff.
  - Need: Phases 1–10 implement every named roadmap capability, but reviewers
    still have to correlate separate manifest, safety, compatibility, license,
    payload, closure, and integrity reports manually for each browser entrypoint.
  - Outcome: a closed policy declares every authorized browser entrypoint and a
    deterministic attestation accounts for its runtime, application code,
    assets, licenses, payload, safety, compatibility, and delivery integrity.
  - Boundary: this closes BH-06 for bounded development. It does not authorize
    production serving/releases, Phoenix, command transport, routing, prefetch,
    support promotion, LiveView, LocalLiveView, BH-07 implementation, or BH-19.

  - [x] 11.1 Section - Freeze accounting authority and completion contract.
    - [x] Bind accepted Phase 10, exact base, ownership, workflow, and deferrals.
    - [x] Freeze the complete entrypoint set, required public/private roles,
      evidence categories, deterministic identities, limits, and stop rules.
    - [x] Activate policy/report schemas, planning, baseline, and evidence indexes.

  - [x] 11.2 Section - Implement deterministic entrypoint attestation.
    - [x] Validate the policy without atom creation and reject duplicate,
      unknown, missing, unused, over-limit, or malformed declarations.
    - [x] Build a path-independent attestation from the manifest and exact
      safety, compatibility, license, closure, payload, and integrity evidence.
    - [x] Verify all identities, totals, decisions, ownership, and role coverage
      with focused positive, deterministic-repeat, and mutation tests.

  - [x] 11.3 Section - Integrate, package, and replay the attested candidate.
    - [x] Emit the attestation only after all existing gates accept and bind it
      into the active-browser replay without changing public payload accounting.
    - [x] Prove the attested counter entrypoint through the existing AtomVM
      lifecycle in Chrome and Firefox with exact parity.
    - [x] Reject stale manifest, missing license/payload category, undeclared
      entrypoint, false decision, and browser attestation-binding mutations.

  - [x] 11.4 Section - Reproduce, reconcile, and close BH-06.
    - [x] Run package, browser-Wasm, schemas, validator mutations, independent
      rebuild, scoped Mix, historical BH-06, archive, and patch-hygiene gates.
    - [x] Publish identities, accounting summary, limitations, inherited corpus
      failures, review, completion decision, and explicit BH-07 handoff boundary.
    - [x] Accept BH-06 only if every declared browser entrypoint is accounted,
      every unchanged gate passes, and both active browsers bind the attestation.

## Exit gate

The declared entrypoint set and produced attestation set match exactly. Each
attestation binds one entrypoint to all required artifact roles and evidence
categories, recomputes identities and payload totals, and records only passing
decisions. Equivalent inputs produce byte-equivalent attestations. Chrome and
Firefox bind the attestation before completing the unchanged real-Wasm proof.

## Connections

- [Phase 10 completion](phase-10-completion.md)
- [Entrypoint-accounting contract](entrypoint-accounting-contract.md)
- [Browser milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
