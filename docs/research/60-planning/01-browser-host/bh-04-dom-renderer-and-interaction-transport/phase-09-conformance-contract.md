---
title: "BH-04 Phase 9 Conformance Contract"
kind: note
created: "2026-09-08"
maturity: developing
tags:
  - bh-04
  - conformance
aliases: []
---

# BH-04 Phase 9 Conformance Contract

## Authority and boundary

The owner authorized Phase 9, section commits 9.1 through 9.5, one PR, merge,
synchronized main and subsequent feature-branch deletion. Base is
`644055f646392e9daabb396a636249433f09a991`. Section 9.1 includes the previously
approved framework deferral; unrelated README, BH-05 and demo edits are excluded.
The [authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-09-authorization-v0.1.0.json)
binds the accepted Phase 7 completion and current scope inputs.

LiveView and LocalLiveView remain [DEFERRED] under the
[owned decision](../../liveview-integration-deferral.md). No adapter is loaded,
tested or credited by this phase. Headless and standalone DOM are active.
Linux Chrome and Firefox must each pass; neither substitutes for the other.
Manual screen-reader, switch, voice-control, Safari/macOS, Windows and physical
mobile qualification remain [DEFERRED] to platform/accessibility owners at
BH-22. This is internal development evidence, never a support claim.

## Frozen corpus and comparison rules

| Corpus | Required observations | Oracle and allowance |
| --- | --- | --- |
| Semantic rendering | All 50 existing reconciliation cases plus an explicit accessibility state/live update | Actual headless snapshots and standalone transactions from the same semantic inputs; compare tree order, kind, text, bindings and accessibility intent rather than backend bytes |
| Atomic rejection | Fresh execution of the complete Phase 4 corpus, fault boundaries, stale traffic, properties, queue and cleanup cases | Last accepted projection and exact rejection/rollback outcomes; no mutation or identity loss |
| Interaction | Fresh execution of all 13 accepted mappings and 17 negative cases from Phase 5 | Actual Elixir dispatch, correlated acknowledgement, semantic outcomes and independent protocol replay |
| Forms and focus | Fresh execution of all 16 Phase 6 scenarios | Controlled value, selection, composition, focus restoration, replacement, stale rejection and cleanup |
| Effects and failures | Fresh execution of all 19 Phase 7 scenarios | Ordered semantic/effect results, failed effect, runtime loss, overload, disposal race and bounded cleanup; independent replay |
| Browser accessibility | Materialized roles, names, descriptions, relationships, states, live attributes, order, identity and duplicate-ID absence | Explicit semantic intent plus browser accessibility snapshots where available; automatic observations do not prove assistive-technology behavior |

Run the semantic rendering corpus twice per browser to expose unstable order,
identity and cleanup. Existing interactive corpora include rapid input,
multiple roots and repeated lifecycle scenarios. Retain their raw traces in
new Phase 9 artifacts; historical results are inputs, not new pass credit.

Headless has no DOM, native focus, text selection, Web API timers or browser
accessibility tree: those observations are not-applicable to headless, not
silently passing. Its semantic tree and intent remain the cross-path oracle.
Browser-specific behavior uses the already accepted semantic/form/effect
contracts and actual ERTS dispatch. The browser driver remains a test-only
DevTools/stdio carrier, not a newly packaged production Wasm endpoint.

Canonical observations retain IDs, tags, text, attributes, properties, order,
listeners, focus and selection. Only volatile run metadata (timestamps,
loopback ports and elapsed timing) may be excluded from normalized summaries;
raw records and hashes retain it. No golden-file auto-acceptance is permitted.
Reports must regenerate byte-identically twice from the same raw inputs.

## Evidence states and completion

Each required corpus/browser row is passed, failed, blocked, not-applicable or
deferred. Missing active evidence is blocked; mismatches are failed and block
completion. Deferred rows retain owner and reactivation rules and are excluded
from active counts. A schema-valid file, another path's pass or a successful
compilation cannot close a missing row.

The isolation gate must compile/test standalone and headless with adapter and
framework source/dependency directories physically absent from the build
context; audit source, Mix dependency, asset import and loaded-module closures.
Fixtures author semantic inputs without browser or framework types. Test
drivers may bridge the renderer boundary; application fixtures may not.

Phase 9 completion requires fresh raw results, deterministic reconciliation,
negative validator tests, source/fixture hashes, dependency evidence and all
active suites. Phase 10 becomes eligible but separately unauthorized. BH-04
is not complete; retain the owner's scripts-move warning for final acceptance.

## Connections

- [Phase 9 plan](phase-09-cross-path-accessibility-and-browser-conformance.md)
- [BH-04 index](README.md)
