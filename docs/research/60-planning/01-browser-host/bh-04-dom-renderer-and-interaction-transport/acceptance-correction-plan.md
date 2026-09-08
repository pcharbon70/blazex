---
title: "BH-04 corrective acceptance plan"
kind: note
created: "2026-09-08"
maturity: developing
tags: [bh-04, acceptance, benchmarks]
aliases: []
---

# BH-04 corrective acceptance plan

The owner authorized addressing the BH-04 blockers, including independent
reviewer agents, before BH-05 on 2026-09-08. This is a corrective successor to
Phase 10, not retroactive alteration of its revise decision or a new product
phase. Base: `d61e103b14595acca182611524eb4c7245906f20`; branch:
`codex/bh04-acceptance-correction`. Preserve user README/BH-05/demo edits.

## Ordered sections

- [x] C1 — Freeze corrected measurement and review scope before acceptance runs.
- [x] C2 — Repair independent findings and produce native-presentation evidence.
- [x] C3 — Obtain final independent reviews, bind all obligations and decide.
- [ ] C4 — Reproduce active gates, publish one PR, merge, sync main, then delete branch.

One commit per section. A blocker stays blocking; no threshold reduction,
sample removal, independent-review fiction or deferred qualification credit.
BH-05 cannot start until a successor decision is accepted.

## Frozen native-presentation method

Use the unchanged canonical `keyed-reorder` fixture and actual AtomicDOMRoots.
One labeled setup run and 100 measured runs per installed Linux Chrome and
Firefox, all retained. Each root mounts and settles for 100 ms before receipt;
after commit observe for 125 ms before teardown. Both are outside the measured
receipt-to-presentation interval. Keep failed or missing presentations as
blocking samples, not filtered data. No screenshots, forced layout, animation
frame timestamps or synthetic presentation events stand in for compositor
evidence. Record receipt, queue/pump, preflight acceptance, apply, commit and
native trace identities; frame opportunities may be diagnostic only.

Chrome: DevTools native tracing records UserTiming receipt/commit marks, a
same-renderer-process Paint, and paired
`SubmitCompositorFrameToPresentationCompositorFrame` begin/end events. Match
the presentation pair by process and local trace ID after the measured paint,
within the isolated observation window. The end is compositor presentation,
not a physical-display or vsync support claim. Reject missing/ambiguous chains.

Firefox: startup Gecko profiler captures UserTiming marks and the owning
window's `ViewManagerFlush` with transaction identity, plus the compositor's
`ContentPaint Payload Presented` interval. Align process clocks using the
profile's recorded process start times. Its payload start must fall within
the owning content flush, and its end must follow commit within the sample
window. Also require the owning window's trusted `MozAfterPaint` event after
presentation. Reject missing/ambiguous correlation. A test-only preference
exposes that event in a fresh profile; production preferences are unchanged.
Use marker-only profiling to avoid stack-sampling overhead and retain the
complete compressed native profiles, not just extracted passing rows.

Proposed p95 remains at most **50 ms**, nearest-rank over all 100 measured
samples. Report median, p95, p99, minimum, maximum and population CV. CV >10%
requires investigation, not averaging away unstable runs. New measurement
method has no like-for-like old paint baseline; the old frame proxy is not a
regression baseline. Local headless software presentation is active development
evidence only; unavailable physical device/platform qualification stays owned
and deferred under the existing policy.

## Review corrections and scope

Three independent read-only agents cover architecture/implementation,
security/packaging/provenance, and QA/accessibility/performance/reliability.
Their initial findings include controlled-draft corruption by non-edit events,
insufficient stale/queue evidence validation, and stale package documentation.
Repair these within BH-04 and rerun affected scenarios. Return the exact final
delta and evidence to reviewers. Record tool/test execution and limitations;
agents are independent from implementation, not different-human sign-off.

The parallel-review skill requires one cumulative report under `.spec/reviews`;
the successor acceptance record binds it. Keep all old evidence and the sealed
`70-tools` migration intact. New tools belong in `70-tools`. Historical gates
must run at their accepted revisions when current correction sources differ;
new acceptance must validate current source and evidence separately.

## Decision and handoff

Acceptance requires all five BH-04 obligations, no active blocker, exact current
source bindings, complete scenario/review coverage and deterministic release
generation. Carry every inherited limitation and deferred qualification.
LiveView/LocalLiveView remain deferred. No public API, product controls, server
authority, Plug qualification, production Wasm endpoint or release support is
authorized. Accepted BH-04 permits separately authorized BH-05 Phase 1.

The research scripts already moved in PR #50 to `docs/research/70-tools`.
No additional script relocation is part of this correction; prominently remind
the owner about the changed commands when actual BH-04 acceptance is achieved.

## Sources and connections

- [Phase 10 decision](phase-10-implementation-evidence.md)
- [Milestone index](README.md)
- [Gecko profiler lifecycle](https://firefox-source-docs.mozilla.org/tools/profiler/code-overview.html) — native process profiling and shutdown capture; inspected 2026-09-08.
- [Gecko paint event interface](https://raw.githubusercontent.com/mozilla-firefox/firefox/main/dom/webidl/NotifyPaintEvent.webidl) — privileged paint/transaction fields; plain content events cannot expose them.
- [Gecko presentation implementation](https://raw.githubusercontent.com/mozilla-firefox/firefox/main/layout/base/nsPresContext.cpp) — native paint notification, not an animation-frame proxy.
- [Quality contract](../../../assets/quality-acceptance/blazex-quality-contract-v0.1.0.json)
