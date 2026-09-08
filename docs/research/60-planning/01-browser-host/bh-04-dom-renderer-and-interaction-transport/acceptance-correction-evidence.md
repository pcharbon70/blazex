---
title: "BH-04 corrective acceptance evidence"
kind: note
created: "2026-09-08"
maturity: developing
tags: [bh-04, acceptance, benchmarks]
aliases: []
---

# BH-04 corrective acceptance evidence

Status: **accepted for bounded development** by the source-bound
[corrective decision](../../../assets/bh-04-correction/decision.json).
Independent review closure and current/historical execution gates pass. C4 PR
delivery and branch cleanup remain to be completed. Release support remains
unsupported; BH-05 Phase 1 is eligible under the owner's separate request.

## C2 runtime and checker corrections

Only normalized change/select events admit controlled drafts. Defensive value,
checked-state and sequence guards prevent malformed direct admissions from
advancing the edit fence. Six real-DOM cases (text/check with activate/move/
reorder) pass in each installed browser. All 31 JavaScript test files pass.

The successor checker validates the deterministic stale seed stream,
generation, delay, transaction/effect identities, rejected acknowledgement,
unchanged before/after DOM and renderer state, and finite ordered queue times.
Mounted effect roots retain one DOM lease; disposal converges to zero. Eleven
refreshed-hash forgery regressions are rejected. Old Phase 10 JSON and its report
generator remain unchanged.

The presentation harness retains setup/submission/shutdown errors within
completed sample rows. Injected late-cleanup failure in each browser retains
sample 0 plus the explicit failed sample 1. No partial success becomes a pass.

## Native measurements

The [complete captures](../../../assets/bh-04-correction/README.md) bind direct
driver/runtime bytes; the final gate must bind the full dependency closure.
Chrome 140.0.7339.80 and Firefox 153.0 ran headless on the Linux workstation.
All 100 measured samples per engine are retained, with one labeled setup sample.

| Receipt-to-presentation | Chrome | Firefox |
| --- | ---: | ---: |
| Median (ms) | 6.518 | 9.511 |
| p95 (ms) | 13.915 | 20.054 |
| p99 (ms) | 27.029 | 21.210 |
| Maximum (ms) | 28.378 | 21.917 |
| Population CV | 57.571% | 41.755% |

Both p95 values are below the unchanged 50 ms development budget. This is
native headless compositor presentation, not physical-display qualification,
production Wasm performance or a stable hardware baseline.

### Failed attempt and parser correction

The first Chrome run rejected seven samples because distinct local trace IDs
had identical begin/end process, thread and timestamp tuples. Independent QA
confirmed these describe the same observed latency endpoint, without proving
a unique frame identity. The corrected parser retains every ID and full trace,
grouping only exactly coincident endpoints. Different times, processes,
threads, missing or multiply matched ends fail. The original report and traces
remain unchanged as negative evidence; exact first-harness replay is not claimed.

### Variance investigation

The 10% CV trigger is exceeded. No samples were discarded or averaged across
runs. Chrome receipt-to-commit p95 is 10.490 ms and post-commit presentation
p95 is 3.708 ms; Firefox's are 6.724 ms and 14.505 ms. Variability exists in both
parts. Consecutive 25-sample means are 4.812/4.970/11.340/11.636 ms in Chrome
and 13.186/11.443/9.997/8.311 ms in Firefox: temporal drift remains visible.

Host contention, runtime warmup and browser scheduling are hypotheses, not
proven causes; profiling also changes the environment. The old frame proxy is
not a comparable baseline. Independent QA considers this investigation adequate
for bounded development acceptance, not a stability claim. The performance
qualification owner must repeat these measurements at BH-22 governed hardware
qualification and after material renderer/runtime changes. This obligation
receives no deferred pass credit. Overall acceptance still requires C3/C4.

## Reproduction

Create a fresh temporary directory, then run
`node integration/bh-04/presentation-browser.mjs <directory>` from the repository
root. Full compressed native traces and the report are written without
overwriting an existing run. Browser paths are recorded in the driver.

Run `node --test integration/bh-04/presentation-trace.test.mjs integration/bh-04/corrective-report.test.mjs`
for native-chain negatives and stale-evidence mutations. The immutable historical
Phase 10 decision remains revise; this successor closes its blockers without
rewriting that record.

## C3 source-bound decision and independent closure

All three independent reviewer agents approved the final delta conditional on
passing unchanged-source gates. The [cumulative review](../../../../../.spec/reviews/2026-09-08T13-01-15-0400-parallel-code-review-bh04-correction.md)
retains original findings, corrections, disagreement resolution and limitations.
The final execution log binds identical before/after/current source closures;
four successor Python tests include stale execution and inherited-input tampering.
All inherited non-Markdown assets match their frozen Git blobs. All five
acceptance conditions and every inherited obligation/deferral remain present.

The complete historical sweep at `d61e103b14595acca182611524eb4c7245906f20`
passes 438 tests and every validator/generator check. The current 15-command
sweep passes offline package/conformance tests, JavaScript, current-tool tests,
both browsers, replays, isolation, archive, migration and hygiene checks.
Earlier missing-artifact/bootstrap and incomplete-index attempts are retained;
they receive no passing credit. Native and stale observations independently
reparse from raw captures. Exact commands and outputs remain in the gate logs.

Current command: `python3 docs/research/70-tools/validate_bh04_correction.py`.
The old sealed `check_all.py` remains a historical-snapshot sweep, not a way to
validate changed implementation bytes against old acceptance. No bound tool or
old record was silently rehashed. The scripts-move warning was delivered to the
owner: corpus Python now lives in `docs/research/70-tools`.

## C4 delivery checkpoint

The current validator and deterministic generator check both pass after the
C3 commit, as do archive validation and patch hygiene. Implementation sections
are committed separately: C1 `9e35f3c`, C2 `4c9fdb7`, C3 `d2e18f9`, followed by
this C4 delivery checkpoint. One corrective PR will contain the four commits.
The PR must be merged before returning to main, fast-forwarding from origin,
and deleting its feature branch. Publication/merge/cleanup are deliberately
not marked complete in this pre-publication record; the PR and final delivery
message record those external actions. Unrelated user work remains preserved
in stash `04f1fcd5aef6f74c9093a22cb85bca33e6e7ba61` until return to main.

Public capture disclosure: native evidence includes browser/environment and
local path metadata, as detailed in the captures index. No support or human
review qualification is inferred from publication.
