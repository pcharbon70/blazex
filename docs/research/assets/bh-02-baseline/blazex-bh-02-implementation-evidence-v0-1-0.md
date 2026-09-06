---
title: "BlazeX BH-02 Implementation Evidence v0.1.0"
kind: note
created: "2026-09-05"
maturity: stable
tags:
  - bh-02
  - conformance
  - host-neutral
  - implementation-evidence
aliases:
  - "BH-02 implementation evidence"
---

# BlazeX BH-02 Implementation Evidence v0.1.0

## Outcome

BH-02 is complete and accepted with bounded conditions. BlazeX now has an
internal, versioned host-neutral semantic contract exercised through a
deterministic headless oracle, a standalone DOM projection, and a limited
direct native-control experiment. The result is suitable as an internal input
to a separately authorized BH-03; it is not a stable public API or a supported
product release.

## Delivered phases

| Phase | Delivered result |
| --- | --- |
| 1 | Authorized nine repository boundaries and fail-closed dependency/leakage rules. |
| 2 | Implemented semantic nodes, stable identity, pure/stateful component evaluation, diagnostics, and portable validation. |
| 3 | Implemented normalized events, actions, capability negotiation, effects, providers, and resource lifecycle. |
| 4 | Implemented logical layout, token references, accessibility semantics, focus, selection, validation relationships, and file-choice intent. |
| 5 | Implemented renderer negotiation/lifecycle plus deterministic headless snapshots and traces. |
| 6 | Implemented a standalone full-root DOM lowering and browser driver, tested in Chrome and Firefox. |
| 7 | Implemented a disposable direct Win32/AppKit/GTK experiment; directly executed GTK 4 on Linux. |
| 8 | Reconciled all outputs and inherited obligations, froze the candidate contract, completed seven review lenses, and passed the full acceptance gate. |

## Cross-backend proof

The reconciled slice covers layout, action, field, selection, keyed list,
surface, focus, file choice, and disposal. Headless, DOM, and native-spike
contracts preserve semantic identity and lifecycle rules without admitting
browser or toolkit objects to portable packages. Backend identifiers,
encodings, geometry, and pixels remain private or out of parity scope.

File choice is accepted as a portable effect intent. DOM provider behavior is
not part of this milestone, and the native mapping is source-inspected but its
real dialog interaction remains deferred. This is a bounded exception, not a
silent pass for a provider implementation.

## Final reproduced gate

- Ten Mix projects passed formatting and 91 tests.
- The DOM package passed its build and seven Node tests.
- Chrome 140 and Firefox 134 each passed seven browser behaviors.
- The direct GTK 4.14.5 experiment passed under Xvfb with ten actual controls,
  one service mapping, semantic events, focus/selection, atomic stale
  rejection, and idempotent disposal.
- The research suite passed 218 Python tests, all Phase 1–8 validators, all
  inherited BH-00/BH-01 checks, deterministic generators, archive links and
  metadata, JSON parsing, and patch hygiene.

## Accepted internal contract

The compatibility identities in `BX-BH02-CONTRACT-BASELINE-0.1` are accepted
for internal downstream use. A material change requires a superseding ADR,
compatibility impact review, updated versioned fixtures, and affected backend
reexecution. Silent breaking changes are prohibited.

The accepted identity does not include DOM/browser objects, native handles,
backend-generated IDs, GTK/Win32/AppKit wire shapes as portable API, BH-01
fixture protocols, pixel/geometry equivalence, or production providers. Qt
and wxWidgets remain excluded direct and transitive systems.

## Conditions and nonclaims

Windows and macOS native execution, physical mobile, Safari, a second host,
and manual assistive-technology qualification remain deferred. GTK semantic
role gaps, IME, file-dialog interaction, visual equivalence, performance,
payload/reachability, SBOM/notices, signing, package publication, production
security/deployment, and release controls remain open at their later gates.

The canonical generated acceptance registry remains unchanged. Its BH-02
execution state is recorded only in versioned overlays. The BH-02 roadmap
condition passes at internal experimental milestone scope; the UI-tree package
condition is implemented but not fully verified because its payload/release
evidence has not run; all six product accessibility gates remain planned.

## Connections

- [BH-02 Phase 8 plan](../../60-planning/01-browser-host/bh-02-host-neutral-semantic-kernel-gate/phase-08-cross-backend-reconciliation-and-bh-02-acceptance.md)
- [Browser-host milestone roadmap](../../20-notes/browser-host-implementation-milestones.md)
- [Acceptance evidence policy](../../20-notes/blazex-acceptance-traceability-and-evidence-policy.md)

## Sources

- [Final acceptance decision](blazex-bh-02-acceptance-decision-v0.1.0.json)
- [Internal contract baseline](blazex-bh-02-contract-baseline-v0.1.0.json)
- [Reconciliation ledger](blazex-bh-02-reconciliation-v0.1.0.json)
- [Multidisciplinary review](blazex-bh-02-multidisciplinary-review-v0-1-0.md)
- [Final validation log](blazex-bh-02-phase-08-validation-log-v0.1.0.txt)
- [Final conformance index](../../../../integration/conformance/conformance-index-v0.8.0.json)
