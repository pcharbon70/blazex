---
title: "BH-05 Phase 12 Completion Evidence"
kind: note
created: "2026-09-10"
maturity: developing
tags: [acceptance, bh-05, evidence]
aliases: []
---

# BH-05 Phase 12 Completion Evidence

Back to [milestone](README.md), [reconciliation](acceptance-reconciliation.md),
and [release decision](release-and-bh06-handoff.md).

## Outcome

Phase 12 is complete with decision **revise**. This is a successfully validated
decision pipeline, not BH-05 acceptance. BH-06 remains ineligible and
unauthorized; support remains unsupported.

Six controlled quantitative budgets and both canonical failure gates pass.
ERTS retained 20 count samples per count budget, 100 cleanup samples with a
2 ms nearest-rank p95, and ten independent 100-cycle samples with zero process
growth. The component failure gate covers 17 cases. A lifecycle defect found
during measurement—100 retained terminal guardians after 100 cycles—was fixed
with explicit terminal release and its failed trial remains in raw evidence.

The committed active browser measurement has Chrome at 500 ms with zero
unresolved releases and Firefox at 2652 ms with 452 unresolved releases. The
fresh final repetition independently recorded Chrome at 531 ms/zero unresolved
and Firefox at 2559 ms/442 unresolved. Both browsers report zero process growth.
The variable unresolved count does not weaken the invariant: Firefox fails to
reach the same terminal inventory under the unchanged 1000 ms deadline.

## Final gate

All 13 meta-gates passed against identical before/after hashes for 1,095 source
files. Package counts were Core 92, Effects 12, UI-tree 68, Renderer 8,
Headless 6, DOM 116, Test 3, and Conformance 93: **398 tests**, zero failures.
JavaScript was **213 runtime + 7 DOM-driver tests**, zero failures. The gate also
rebuilt the browser project, reproduced the active blocker, replayed Phase 11,
passed the historical sweep, regenerated release/reconciliation artifacts,
validated archive and JSON structure, and repeated Core/recovery tests in a
second clean build context.

The source-frozen [gate record](../../../assets/bh-05-baseline/acceptance-gates-v0.1.0.json)
has SHA-256 `fabd17a5ee2ca9512ad981cfb1a277012c2d88e5a9ac710aed4c337cfa34fd1c`.
The [completion record](../../../assets/bh-05-baseline/acceptance-completion-v0.1.0.json)
has SHA-256 `4769d0aa7d74da4aeab8fe13dbe3924666361a3a4c71a8af66fba902ad69774e`.

## Re-entry and limits

BH-05 re-entry must retain the resource-heavy fixture, 1000 ms deadline and all
failed trials, then produce fresh zero-unresolved exact Chrome/Firefox terminal
inventories and rerun the complete gate. No public 1.0, browser/platform,
profile or release-support inference is permitted. LiveView and LocalLiveView
remain separately deferred. Windows, macOS, WebKit, devices and manual
assistive-technology qualification remain deferred to BH-22.
