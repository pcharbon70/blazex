---
title: "Browser Host Implementation Plan"
kind: map
created: "2026-09-02"
tags:
  - archive-navigation
  - browser
  - directory-index
  - implementation-planning
aliases:
  - "BlazeX browser planning stream"
---

# Browser Host Implementation Plan (`01-browser-host`)

## [DEFERRED] framework integration

LiveView and LocalLiveView are outside the current host implementation. The
[2026-09-08 deferral](../liveview-integration-deferral.md) applies throughout
this stream, including later milestones. Historical framework experiments stay
historical; they do not impose current implementation or compatibility gates.


## Purpose

This directory is the planning stream for BlazeX's first production host: the
web browser. It will eventually translate the research-level browser roadmap
into ordered implementation phases with explicit dependencies, tasks,
integration gates, and reproducible completion evidence.

The authoritative research-level sequence remains [Browser host
implementation milestones](../../20-notes/browser-host-implementation-milestones.md).

## What belongs here

BH-04 Phase 1 completed its governance-only activation on 2026-09-07 after
accepted BH-03 Phase 9. Its [ten-phase plan](bh-04-dom-renderer-and-interaction-transport/README.md)
now records completed Phase 2 protocol, Phase 3 pure keyed reconciliation and
Phase 4 atomic DOM application and Phase 5 semantic interaction transport.
Phases 6 and 7 are complete. Phase 8 is [DEFERRED]; Phase 9 conformance is complete.
The Phase 10 corrective successor accepts BH-04 for bounded development. BH-05
Phase 1 is eligible under the owner's request; no browser support is claimed.

- Future phase documents for browser-host implementation.
- Shared planning status, dependency, and evidence conventions for those
  phases.
- The packages, profiles, JavaScript projects, integration suites, and bounded
  experiments activated or modified by each phase.
- Dependency guards that keep standalone DOM rendering, LiveView integration,
  browser capabilities, and server adapters independently replaceable.
- Traceability from implementation work back to research conclusions and open
  inquiries.
- The eventual browser-stream completion gate.

BH-00 is complete. The repository owner approved the BH-01 plan snapshot and
all ten BH-01 phases are complete as governed work. Phase 8 retains its truthful
historical blocked result: only the Chrome/Linux row was available, four
browser/device rows and manual assistive-technology pairings could not execute,
and the two engine probes grant no support credit. Under the repository-wide
[development environment and deferred qualification policy](../development-environment-and-deferred-qualification-policy.md),
those unavailable external environments are now deferred rather than blockers
to framework development. Phase 9 is complete with a conditional active-Linux
proceed decision, retained payload/timer failures, and representative rerun
drift. BH-01 is complete with a proceed-with-bounded-conditions decision after
two independent clean execution contexts and the milestone-wide integration
gate passed. BH-02 Phase 1 activated and validated the neutral foundation. The
repository owner explicitly authorized BH-02 Phase 2 on 2026-09-05; its
semantic-node, identity, and component-evaluation gate passed. BH-02 Phase 3
was explicitly authorized on 2026-09-05; its event, effect, capability, and
resource gate passed locally. Phase 4 was explicitly authorized on 2026-09-05,
and its portable presentation-intent gate passed locally. Phase 5 passed its
renderer lifecycle/headless-oracle gate. Phase 6 passed its experimental
standalone DOM and active Linux Chrome/Firefox development gate on 2026-09-05.
Phase 7 and Phase 8 completed BH-02 with an accepted internal experimental
contract baseline. BH-03 Phase 1 completed its handoff reconciliation,
browser-host lifecycle boundary activation, and fail-closed gate on 2026-09-06.
Phase 2 completed compatibility, discovery, prerequisites, and strict manifest
validation on 2026-09-06. Phase 3 completed artifact acquisition, startup, and
readiness, and Phase 4 completed compatible runtime sharing and independent
root lifecycle on 2026-09-06. Phase 5 completed shutdown, bounded recovery,
and fallback, and Phase 6 passed the separate `/bh03/` Phoenix profile in the
active Linux Chrome/Firefox matrix on 2026-09-06. Phase 7 completed repeated
startup, ten-root lifecycle, cleanup, declared-failure, and capability-aware
memory observations on 2026-09-06. Phase 8 completed its review on 2026-09-07
with a revise decision. Corrective Phase 9 closed the unreported runtime-loss
defect and accepted BH-03 with bounded conditions on 2026-09-07.
The repository owner approved the BH-04 ten-phase decomposition on 2026-09-06.
BH-04 Phases 1 through 7 are complete; Phase 8 is [DEFERRED]. Phase 9 conformance
is complete and Phase 10's corrective successor is accepted for development.
BH-05 Phase 12 completed with a truthful `revise` decision because Firefox did
not reach an exact terminal cleanup inventory under the frozen deadline.
Corrective Phase 13 completed with a truthful `revise` result. Corrective
Phase 14 completed with `revise`: canonical Firefox cleanup passes, while the
maximum-payload 512 row retains a transfer blocker; BH-06 remains ineligible.

## Index

### Subdirectories

- [BH-04 — DOM Renderer and Interaction Transport](bh-04-dom-renderer-and-interaction-transport/README.md) — accepted for bounded development through the corrective successor; Phase 8 remains [DEFERRED], release support unqualified.

- [BH-00 — Product Boundary, Catalog, and Acceptance Contract](bh-00-product-boundary-catalog-and-acceptance-contract/README.md) — six-phase plan that freezes vocabulary, product scope, catalog dispositions, quality budgets, and acceptance traceability before BH-01 implementation begins.
- [BH-01 — Reproducible Browser Feasibility Baseline](bh-01-reproducible-browser-feasibility-baseline/README.md) — completed need-driven plan with a proceed-with-bounded-conditions decision; external browser qualification remains deferred, and its immutable entry artifact records the pre-authorization BH-02 state.
- [BH-02 — Host-Neutral Semantic Kernel Gate](bh-02-host-neutral-semantic-kernel-gate/README.md) — completed eight-phase contract and cross-renderer proof plan accepted for internal experimental use.
- [BH-03 — Browser Execution-Host and Runtime Boot Lifecycle](bh-03-browser-execution-host-and-runtime-boot-lifecycle/README.md) — accepted with bounded conditions; BH-04's corrective handoff is now accepted for development.
- [BH-05 — Component Programming Model and Lifecycle](bh-05-component-programming-model-and-lifecycle/README.md) — Phase 14 completed with `revise`; canonical cleanup passes but maximum-payload transfer remains blocking, and BH-06 remains ineligible. No support promotion is claimed.

### Documents

- None yet.

## Maintaining this index

Add phase documents only after the phase decomposition is explicitly
approved. When phases are introduced, index every phase here, record their
dependency order, activated projects, forbidden dependencies, and shared
completion rules. Keep active work unchecked until reproducible implementation
evidence satisfies the stated gates. Label work that requires an unavailable
platform, browser, device, service, or manual pairing `[DEFERRED]`; do not count
it as completed or allow it to block active development. The BH-02 native
renderer remains a bounded experiment unless a later planning stream explicitly
promotes it to a supported package.
