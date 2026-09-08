---
kind: parallel_code_review
status: complete
title: Parallel Code Review - BH-04 corrective acceptance
created_at: 2026-09-08T13:01:15-0400
review_target: codex/bh04-acceptance-correction
repository: /home/ducky/code/blazex
base_ref: d61e103b14595acca182611524eb4c7245906f20
head_ref: 4c9fdb7fcb979b5b263237850d78e6d913de17b4
review_lanes: [factual, qa, senior_engineering, security, consistency, redundancy, frontend, elixir, documentation]
result: findings
---

# Parallel Code Review — BH-04 corrective acceptance

## Review Context

The owner explicitly authorized independent reviewer agents before proceeding
to BH-05. Three read-only agents reviewed the baseline and corrective delta;
none implemented changes. The implementing parent synthesized findings and
applied fixes. Independence means separate agents, not different human sign-off.
The eight acceptance lenses map to architecture/implementation (architecture
agent), renderer/conformance/accessibility/performance/reliability (QA agent),
and security/packaging/dependency/provenance (security agent).

## Executive Summary

Review found a real controlled-draft corruption bug, insufficient stale-message
evidence checking, stale package documentation and a new benchmark cleanup-error
retention bug. All are corrected and verified by their reviewers. Native
presentation evidence now exists in both active browsers. Final successor
gate/provenance delta is approved by all three agents, conditional on successful
source-frozen execution and decision validation; this report alone does not accept BH-04.

## Blocking Findings

- Resolved P1: `js/blazex_runtime/src/interaction-listeners.js:53` admitted every
  semantic event into form continuity. An activate payload `{}` overwrote the
  text/check draft with undefined. Only change/select now admit drafts, with
  defensive payload/sequence guards and Node/real-DOM regressions.
- Resolved P2: `integration/bh-04/acceptance-report.mjs:35` accepted forged stale
  generations after refreshing row hashes. A successor checker derives seed,
  generation, delay and transaction/effect IDs, checks acknowledgements and
  unchanged state, and rejects eleven refreshed-hash mutations. Old evidence
  remains immutable.
- Resolved P2: `integration/bh-04/presentation-scenarios.js` initially lost all
  completed samples when cleanup threw. Error capture now preserves the current
  row and all predecessors; both real browsers prove injected late failure.
- Resolved P2 in candidate checker: live effect roots own one DOM lease, not
  zero. The corrected checker requires the unchanged live baseline of one and
  separate disposal convergence to zero.
- Resolved P1 provenance: passing gates initially lacked execution-time source
  bindings. Before/after/current complete source maps must now match; package,
  tool and newly added source mutation negatives prove stale evidence fails.
- Resolved P1 provenance: historical inputs were initially freshly hashed, not
  authenticated. Every inherited non-Markdown asset must now match its exact
  BASE Git blob, and all five condition IDs are required. Tampering is tested.

## Concerns

- Native trace data is not anonymous. It contains local executable/library
  paths identifying `/home/ducky`, process/environment metadata, localhost
  addresses and Firefox service preference URLs. Public publication must
  disclose this scope. Scanning found no common credentials or user-content URLs.
- High timing CV and chronological drift remain visible. Causes are unknown;
  development acceptance is not stable-performance or physical-display credit.
- Full dependency closure must be bound by the final successor, including
  `js/blazex_runtime/src/internal/errors.js` and `integration/bh-04/acceptance-report.mjs`.

## Suggestions

- Resolved P3: package README now describes experimental BH-04 reconciliation,
  continuity and effects, and explicitly defers LiveView/LocalLiveView.

## Open Questions

- Final acceptance requires actual passing source-frozen logs and regenerated
  decision verification, not merely the reviewers' conditional approval.

## Test Gaps And Residual Risk

No production Wasm carrier, physical display, manual assistive-technology,
unavailable platform, server authority, framework adapter or release support
qualification is implied. Fresh headless browsers exercise current Linux
development behavior. Performance qualification owner repeats at BH-22 governed
hardware and material renderer/runtime changes. First native attempt is retained
negative raw evidence; exact first-harness replay is not claimed.

## Lane Summaries

### Factual

Architecture agent checked spec/implementation alignment and corrected stale
package scope. Framework integration remains deferred.

### QA

QA independently reparsed both full native captures and verified all 200 measured
presentations, trace hashes and regenerated results. Both new test files pass.
Mutation and retention gaps were found and corrected.

### Senior Engineering

Architecture agent checked root ownership, controlled drafts, effect sessions
and integration boundaries. No unresolved reviewed runtime finding remains.

### Security

Security agent checked codec/allowlists, ownership/generations, queue bounds,
effect grants, dependency closure and evidence privacy. No confirmed new
runtime security blocker; final provenance gate remains to be reviewed.

### Consistency

Old JSON and sealed migration remain unchanged; new corpus tools live in
70-tools. Experimental package documentation is consistent with implementation.

### Redundancy

The successor reuses historical statistics and corpus comparison code rather
than replacing old evidence. No independent actionable redundancy finding.

## Raw Lane Outputs

### Architecture — baseline and corrective verification

Baseline P1: interaction-listeners.js:53 calls admitted for every semantic event;
form-continuity.js:12–14 unconditionally sets dirty/value/checked. Supported
activate on a controlled text field carries `{}`; subsequent rendering can
write literal `undefined`. Focus/blur are not supported semantic mappings;
activate/move/reorder are the applicable regression cases. Existing two Node
test files passed despite the coverage gap.

Follow-up: original P1 is corrected. Listener regression explicitly calls
setContinuity; browser regression attaches actual native listeners to real
inputs. Six cases pass per engine. Package documentation finding is corrected.
New P2: cleanup could throw before samples.push, losing earlier results.

Final runtime verification: all three findings resolved. Cleanup failure now
retains sample 0 and explicit failed sample 1 in both engines. No remaining
blocker from reviewed findings; unfinished C3/C4 gates are not approved.

### QA — baseline and corrective verification

Baseline P2: acceptance-report.mjs:35–38 only counted stale rows/diagnostics;
changing all generations to999999 and refreshing hashes still passed. Derive
the expected seed/generation/delay/ID and assert rejected acknowledgement and
nonmutation state. Queue acknowledgement identity and finite ordered timestamps
also need checking. Existing twelve report tests passed.

Correction findings: live effect baseline must be one DOM lease; teardown errors
must preserve rows. Both corrected and independently verified. Coincident Chrome
endpoints may be grouped for latency only when full begin/end PID/TID/timestamp
tuples match; retain all IDs and reject differing or unmatched chains.

Final QA disposition: both durable traces reparse identically; all200 measured
samples retained and below50ms. Both new test files pass. Variance investigation
is adequate for bounded development acceptance if high CV, chronological drift,
timing decomposition, unknown cause, no filtering/stability/physical-display
claim, and owned repeat obligation remain explicit. No additional measurement
is required solely to reduce CV. Overall acceptance still needs other gates.

### Security — baseline and corrective verification

Baseline: no confirmed finding. Four Node test files and fourteen migration
tests passed. Offline ERTS/test carrier is not production Wasm; same-origin
hostile JavaScript is not sandboxed; no server authorization or arbitrary effects.

Correction: four targeted test files passed. Current presentation direct hashes
and both gzip hashes match; first failed captures remain. Decompressed seven
captures (~84 MB); no common credential/private-key patterns or user-content
URLs found. Traces include identifying environment paths and standard Firefox
preference URLs. Bind the complete dependency closure and limit first-attempt
claims to retained negative evidence unless exact harness sources are preserved.
Final acceptance gate remains unreviewed; no milestone approval implied.

### Final gate delta reviews

Architecture: both provenance blockers are resolved. Complete source closure is
frozen before/after execution and compared to current bytes; historical inputs
match BASE Git blobs and all five condition IDs remain. Four tests pass. Copier
preserves attempts and checks historical revision. No outstanding blocker;
implementation delta approved contingent on final unchanged-source gates and
validated decision.

QA: freshness fix verified. Package/tool changes, added sources and inherited
artifact tampering have passing negative tests. All four successor tests pass.
Final delta approved contingent on frozen execution, durable capture and final
validator. Variance and qualification limits still apply.

Security: final delta approved contingent on successful execution. Source maps,
historical Git blobs, five conditions, no-overwrite copier and current-tool gate
verified. Four Python tests and both changed JavaScript syntax checks pass. No
new actionable blocker.

These final reviews cover the C2 commit plus the successor working delta, whose
exact source closure is bound in the generated decision. Reviewers did not edit
code or generate acceptance records.
