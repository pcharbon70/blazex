---
title: "BH-04 Phase 10 candidate evidence and revise decision"
kind: note
created: "2026-09-08"
maturity: developing
tags: [bh-04, acceptance, implementation-evidence]
aliases: []
---

# BH-04 Phase 10 candidate evidence and revise decision

**Decision: revise. BH-04 is not accepted; BH-05 is ineligible and unauthorized.**
This is delivery of the Phase 10 measurement/review candidate and truthful
negative decision, not completion credit for its unresolved acceptance tasks.
The [review](phase-10-review.md) identifies the two open blockers: actual
compositor-paint measurement and independent specialist review. Neither is an
unavailable-platform deferral. No threshold, scenario or independence requirement
has been weakened to turn the candidate green.

## Source and execution identity

Synchronized base: `23176db2ff608084e9f779943eadcd0eed1926af`.
Executable candidate for final full regression: Section 10.4 commit
`a8b37cc` (full identity in Git and the completion record). Final documentation
and raw rerun artifacts are added by Section 10.5. Runtime/package/profile
sources are unchanged; seven BH-04 support fixtures received only pinned
formatter changes. Exact current executable hashes are in the
[execution index](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-execution-index-v0.1.0.json).

Tools: Node 24.3.0; Python 3.12.12; Docker image `a2386c21edd5`, Elixir 1.17.3 /
OTP 26; Playwright core 1.62.1; Linux Chrome 140.0.7339.80 and Firefox 153.0.
The measurement artifact contains kernel, CPU, memory, load, executable paths,
source identities and monotonic browser timestamps. These are local development
environments, not BH-22 governed hardware or physical-display qualification.

## Measurements

Per engine: 101 keyed observations (one labeled setup, 100 measured), 20
65-proposal queue bursts, 1,000 stale renderer and 1,000 stale effect messages.
Every completed row has an identity, outcome and raw trace hash. Unique seeded
prior-generation effect envelopes include timer requests; no timer or DOM
mutation is credited on rejection. Queue maximum was 64 with the 65th proposal
rejected, no coalescing and a healthy sibling root able to progress.

The final [statistics](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-statistics-v0.1.0.json)
report frame-opportunity p95 of 30.3 ms Chrome / 32 ms Firefox, with CV 6.51% /
3.35%. **These are not compositor-paint budget passes.** All 4,000 stale
messages were rejected without observed DOM/retained-state/effect mutation.
Both engines also execute an intentional failure probe retaining its two
completed keyed observations; these negative probes are excluded from the
measurement minima by identity, not filtered from the main sample set.

The new benchmark mounts a recorded Elixir-produced canonical effect fixture
and reseals generation-bound listener intents for the stale test. Full
interaction/continuity/effect corpora separately execute a fresh offline ERTS
runtime with test-only DevTools/stdio transport. This does not create a
production AtomVM/Wasm renderer endpoint or standards-level Wasm components.

## Reproduction and final gates

Run from repository root:

```sh
node integration/bh-04/acceptance-browser.mjs docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-measurements-v0.1.0.json
node integration/bh-04/acceptance-report.mjs --write
node integration/bh-04/acceptance-report.test.mjs
node integration/bh-04/acceptance-gates.mjs
node integration/bh-04/acceptance-corpora.mjs
node integration/bh-04/acceptance-release.mjs --write
node integration/bh-04/acceptance-release.mjs
node integration/bh-04/acceptance-release.mjs
python3 docs/research/validate_bh04_acceptance.py
python3 docs/research/validate_bh04_acceptance.py --require-accepted
```

The last command **must fail** for this candidate. A valid revise report is not
an accepted milestone. Rerunning raw measurements creates new evidence and
requires regeneration, updated completion bindings and another reviewed commit;
never overwrite accepted predecessor artifacts.

The [gate log](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-gate-log-v0.1.0.json)
retains exact commands, exits and outputs for all package, browser, independent
replay, isolation, research and historical governance runs. Final expected
inventory: 177 package + 56 integration tests; 31 JavaScript test files; seven
DOM driver tests; 300 comparator negatives; 12 new statistical/retention
report tests; 423 research tests; 32 inherited validators and four unchanged
generators. The new candidate validator additionally verifies raw hashes,
fresh corpora, all five acceptance rows, inherited obligations and release
regeneration. Completion records actual exits, not these expected counts.

The [delivery record](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-completion-v0.1.0.json)
binds the final artifacts and first four section commits; its fifth identity
resolves to the commit introducing that record. All 49 recorded final commands
exited zero. The new final candidate check also rejects executable files omitted
from the execution index. `--require-accepted` remains an expected nonzero gate.

Browser corpus coverage per engine: 50 atomic scenarios and 1,204 injected
operation boundaries; 13 interaction mappings and 17 negatives; 16 continuity
scenarios; 19 effect scenarios and 24 root cleanup observations through 1000 ms;
51 semantic cases repeated twice. Exact offline replays retain 40 interaction
deliveries, 66 continuity proposals and 188 effect proposals across engines.
Framework-absent clean builds pass six headless and 116 standalone DOM tests.
This is build-directory isolation on the same host, not independent review or
an independent operator/machine; the owned clean-host repeat condition remains.

## Failed attempts retained

- The [first benchmark attempt](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-failed-attempt-v0.1.0.json)
  failed effect-root setup because the fixture's encoded listener generations
  were still generation 1. The corrected fixture reseals those identities.
  Its completed pre-failure samples were not flushed; no pass credit is taken.
  The harness was corrected and intentionally tested before the final rerun.
- The first successful full measurements are preserved in Section 10.2 Git
  history (`2ffebef`); the final retention-tested run supersedes them, without
  claiming an improved paint result.
- The [first full gate attempt](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-first-gate-attempt-v0.1.0.json)
  found seven fixture formatting failures and in-progress archive indexes.
  Formatting and indexes were corrected before final execution.
- A corpus-check invocation initially used the research directory instead of
  repository root and failed module resolution; the documented root invocation
  was rerun. The existing Jason protocol-consolidation warning remains visible
  in raw offline runtime stderr and is not a dependency upgrade.

## Delivery boundaries

One commit per section, one PR, merge, checkout/sync main, then delete the exact
feature branch. User README, BH-05 planning edits and demo are kept out of this
PR and restored after synchronization. No BH-05 document changes are required
for a blocked entry manifest.

LiveView and LocalLiveView remain deferred with no pass credit. Public APIs,
product components, server authority, Plug execution, prerender/activation,
native/manual-AT qualification and release support remain later work. The
owner's prominent **scripts-move warning remains due at actual BH-04
acceptance**; no scripts are relocated in Phase 10.

## Connections

- [Phase 10 plan](phase-10-measurement-review-and-bh-04-acceptance.md)
- [Frozen contract](phase-10-acceptance-contract.md)
- [Review findings](phase-10-review.md)
- [Versioned release candidate](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-release-index-v0.1.0.json)
- [Milestone index](README.md)
