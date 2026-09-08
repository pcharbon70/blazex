---
title: "BH-04 Phase 9 Implementation Evidence"
kind: note
created: "2026-09-08"
maturity: developing
tags:
  - bh-04
  - conformance
  - evidence
aliases: []
---

# BH-04 Phase 9 Implementation Evidence

## Decision

Phase 9 passes its active standalone/headless conformance gate. LiveView and
LocalLiveView remain [DEFERRED], not executed or credited. Phase 10 is eligible
but separately unauthorized. BH-04 and BH-05 are not accepted by this result.
No product support, manual accessibility qualification or new production Wasm
endpoint is claimed. The scripts-move warning remains due at full BH-04 acceptance.

## Delivered sections

1. 9.1 bound the Phase 7 handoff and approved framework deferral, corrected
   downstream gates and froze active/deferred comparison rules.
2. 9.2 added 51 deterministic shared semantic cases, actual headless snapshots,
   standalone reconciler outputs, browser observations, comparison negatives
   and physically isolated builds. The same semantic inputs are evaluated by
   both backends; expected output is not learned from browser snapshots.
3. 9.3 executed all five corpora in Chrome 140.0.7339.80 and Firefox 153.0 on
   Linux. Semantic rendering repeated twice per browser. Raw observations
   include acknowledgements, rollback/replay outcomes, DOM, computed
   accessibility and disposal inventories. Interaction/form/effect runs use
   real Elixir dispatch through the previously qualified test-only carrier.
4. 9.4 reconciled 263 active rows, verified headless binding equality, retained
   owned deferrals, checked cross-engine and repeated observations, and added
   fail-closed evidence tests. Three application fixtures contain no renderer,
   runtime, host or framework imports; browser-specific code stays in drivers.
5. 9.5 reran active tests and final browser comparisons, checked deterministic
   reports, preserved historical governance through narrowly hash-bound
   amendments and exact Git snapshots, and published the completion candidate.

## Results

| Gate | Observed result |
| --- | --- |
| Semantic/headless corpus | 51 deterministic cases, generated twice identically; headless tree/kind/text/order, bindings and accessibility intent compared to standalone output |
| Semantic browsers | 102 observations per engine, 204 total; repeat/cross-engine normalized DOM equality, role/name snapshots, relationships, states, live attributes, identity and cleanup |
| Comparator negatives | 300 corruptions rejected, including missing nodes, changed text/kind/tag/children and unexpected aria-hidden |
| Atomic corpus, each engine | 50 scenarios; 1,204 injected boundaries; 100 stale rejections; queue maximum 64; 1,263 cleanups |
| Interaction corpus, each engine | 13 accepted event mappings; 17 negative scenarios; three roots; 18 DOM commits; trusted input and no-render events |
| Form/focus corpus, each engine | 16 scenarios; two roots and two cleanups; controlled edits, composition, selection, replacement and focus continuity |
| Effect/failure corpus, each engine | 19 scenarios; 24 roots and cleanups; failed effects, runtime loss, overload and disposal race |
| Independent interaction replay | 40 deliveries, 24 rejected requests, 42 commits across both engines |
| Independent continuity replay | 66 proposals, 64 commits, 22 delivered events |
| Independent effect replay | 188 proposals, 150 commits, 78 events, 40 results |
| Isolated dependency proof | Six neutral/renderer source packages mounted read-only, one protocol data fixture; framework, adapter and profile directories absent; network disabled; 6 headless + 116 DOM tests passed; compiled-module check clean |
| Asset audit | 19 standalone JavaScript modules, relative imports only, no framework coupling; source hashes retained |
| Active Mix suites | Core 13, effects 9, UI tree 25, renderer 8, headless 6, DOM 116: 177 package tests; integration conformance 56 |
| JavaScript | 31 runtime test files; seven standalone DOM driver tests; new comparator and deterministic report checks |
| Research | 412 unit tests passed; all 32 validators passed (Phase 9 candidate then completion gate); four generators unchanged |

The 263-row ledger consists of 51 headless case rows, 204 repeated browser case
rows and eight aggregate regression-corpus/browser rows. It is not 263 distinct
user-facing controls or accessibility qualification tests. Raw evidence retains
all regression traces; aggregate rows link those files by exact hash.

## Failures corrected and limitations

- Headless diagnostic tuples and hyphenated accessibility attributes initially
  did not fit the closed wire codec. Driver serialization now uses explicit
  lists, bounded strings and canonical attribute cells; no wire relaxation.
- The first physically isolated DOM test build lacked the existing protocol
  data fixture. Only that data file was added to its read-only mounts; no
  framework or adapter directory was introduced.
- An injected-failure test reused the failed attempt's transaction ID and was
  correctly rejected. The harness now issues a distinct failed-attempt ID and
  tests replay rejection separately. No renderer fix was necessary.
- An initial JavaScript glob selected no tests and a Python invocation used
  the wrong working directory. Correct explicit paths were rerun; zero tests
  and import failures are not counted as passes.
- Historical checks initially rejected the approved roadmap/policy annotations.
  Exact old/new hashes and the owned decision now constrain the amendment;
  all other drift remains rejected. The accepted BH-03 correction and BH-04
  Phase 7 gates reproduce on their exact accepted Git snapshot rather than
  rewriting completion hashes. The current Phase 9 source gate remains separate.
- Existing Jason fixture compilation emits its known consolidated Enumerable
  warning. It did not fail dispatch or replay; no dependency upgrade occurred.

Accessibility snapshots use Playwright 1.62.1's computed role/name tree, not a
platform accessibility API or a manual screen reader. Descriptions, states,
relationships and live intent are independently checked as materialized DOM
attributes. Headless cannot prove browser focus, native selection, Web API
effects or accessibility-tree behavior; those rows remain not-applicable there.
Manual assistive technology and unavailable external platforms remain owned
BH-22 deferrals. Framework integration requires separate post-BH-04 authorization.

The executable production profile and its historical dependency lock are not
recomposed by this phase. The tested standalone path loads no deferred adapter.
Future Plug is unactivated and receives no build/support credit. Browser
interaction execution uses offline ERTS and a test-only DevTools/stdio carrier;
this does not establish a newly packaged AtomVM/Wasm interaction endpoint.

## Reproduction and provenance

Use pinned Docker image `a2386c21edd5` (Elixir 1.17.3, OTP 26), Node 24.3.0,
Python 3.12.12 and the installed Linux Chrome/Firefox executables. Run the
[command log](../../../assets/bh-04-baseline/blazex-bh-04-phase-09-validation-log-v0.1.0.txt).
The [source index](../../../assets/bh-04-baseline/blazex-bh-04-phase-09-source-index-v0.1.0.json)
binds implementation and drivers; the
[ledger](../../../assets/bh-04-baseline/blazex-bh-04-phase-09-conformance-ledger-v0.1.0.json)
binds raw inputs. Rebuilding the report twice yields identical bytes from the
same raw files; timing and loopback-port metadata remain in the raw carrier logs.

- [Phase 9 plan](phase-09-cross-path-accessibility-and-browser-conformance.md)
- [Conformance contract](phase-09-conformance-contract.md)
- [Completion decision](../../../assets/bh-04-baseline/blazex-bh-04-phase-09-completion-v0.1.0.json)
- [BH-04 index](README.md)
