---
title: "BH-04 Phase 3 Implementation Evidence"
kind: note
created: "2026-09-07"
maturity: developing
tags:
  - bh-04
  - implementation-evidence
  - reconciliation
aliases: []
---

# BH-04 Phase 3 Implementation Evidence

## Decision

Phase 3 passes the pure keyed-reconciliation gate. Phase 4 is eligible but
unauthorized. BH-04 acceptance and BH-05 eligibility remain outstanding.
This implements internal transaction production, not browser DOM application.

The authorized base is `980836b8bc34383bde2e1f24a5a9e7d65908d347`; branch
`codex/bh04-phase3-reconciliation`. Delivery uses four section commits and
one PR, followed by merge, synchronized main, branch deletion and restoration
of unrelated user work. The final section commit is the commit introducing
the completion record.

## Implemented sections

- 3.1 binds inherited sources and freezes identity, replacement, bounds and
  acknowledgement semantics in the [contract](phase-03-reconciliation-contract.md).
  The user expressly approved the needed protocol correction.
- 3.2 adds immutable indexed projections, canonical fingerprints, bounded keyed
  diffing and pure replay-before-publication. V2 adds the existing Lowerer's
  missing ARIA/layout attributes and complete canonical intent cells. Historical
  v1 code and all fixtures are unchanged.
- 3.3 adds an incremental neutral-backend implementation and an acknowledgement-
  aware facade. Accepted projection and neutral metadata stay unchanged until
  an exactly correlated terminal acknowledgement. Progress is monotonic; retry
  IDs are fresh; supersession and implicit fallback reject; disposal is terminal.
- 3.4 proves reconstruction and cross-renderer parity, validates both languages,
  binds current sources, reproduces historical gates and closes adversarial
  constructor, integer-size and state-version findings.

The neutral Session and semantic kernel are unchanged. The original DOM backend
remains the full-root compatibility path; use the new
[incremental facade](../../../../../integration/bh-04/reconciliation-usage.md)
for opt-in transaction production. Property slots have internal diff/replay
coverage but do not introduce a semantic property API.

## Evidence

The [source index](../../../assets/bh-04-baseline/blazex-bh-04-phase-03-source-index-v0.1.0.json)
binds 31 source/schema/fixture/gate files. The
[completion record](../../../assets/bh-04-baseline/blazex-bh-04-phase-03-completion-v0.1.0.json)
binds that index, authority, contract, this note and the
[command log](../../../assets/bh-04-baseline/blazex-bh-04-phase-03-validation-log-v0.1.0.txt).

- 50 real callback traces reconstruct the exact next full-root projection.
  They cover initial/no-op/leaf updates, nested insertion/removal, keyed moves,
  reparenting through new semantic identities, listener/layout/relationship/
  focus/selection changes, materialization replacement, generation replacement
  and disposal. Forty traces are generated; unit tests exercise another 120 seeds.
- Headless conformance compares ordered kind/content/identity topology,
  semantic listeners, focus, selection, accessibility names/relationships and
  exercised layout metrics. Renderer-specific transaction bytes are not compared
  across backends.
- Independent JavaScript data replay reconstructs all 50 projections exactly.
  Elixir and Node agree on 116 protocol records: 100 accepted transaction/ack
  records and 16 expected rejections. Both codecs also reproduce the unchanged
  75-case v1 suite.
- 173 tests across seven Elixir packages pass, including 110 DOM tests;
  56 integration conformance tests pass. Runtime JS build and 23 test files
  pass; the unchanged full-root driver build and seven tests pass.
- 351 research tests, all 27 validators and four generators pass. Both JSON
  Schemas and all 134 positive v1/v2 records/contexts validate. Dependency,
  leakage, complete JSON parsing and patch-hygiene checks pass.
- Trace SHA-256:
  `048a858cba6d8d857ad6c991ccaf9fb63cdde63d2f17d290a87557bb7a070f2f`.
  Exact cross-language result SHA-256:
  `354e934999f31137bbc5f9d5c98d6e038b09d3724518df0b6c43ab68b25c3424`.

Reproduction uses the pinned local Elixir 1.17.3 / OTP 26 image
`a2386c21edd5`, networking disabled; Node 24.3.0, npm 11.4.2,
Python 3.12.12, jsonschema 4.25.1 and Git 2.49.0. See the log for exact commands.

## Algorithm and failure observations

The diff removes vanished/incompatible subtrees postorder, creates nodes
preorder, and positions siblings right-to-left using stable next-sibling
anchors. Value/intent changes follow topology. Every operation depends on its
predecessor. Complete pure replay and canonical comparison occur before a
transaction can be returned.

The observed rich mount uses 35 operations / 6382 bytes, a leaf edit two
operations / 611 bytes, and a no-op one barrier / 505 bytes. The largest fixed
trace is generation replacement at 40 operations / 7490 bytes. These are trace
observations, not throughput, latency, memory or browser-performance passes.

Work is bounded quadratic in node count with fixed depth/field ceilings and
bounded operation preflight; retained memory contains old/new projections and
one candidate. Limits reject rather than truncate. The input walker also bounds
tree shape before neutral semantic validation and limits oversized integer keys.
Mismatch, duplicate identity, missing relationships, unsafe operations, stale
acknowledgements, corrupt state and overflow reject without accepted-state
mutation. Kind/tag incompatibility explicitly rematerializes a subtree;
generation change uses an explicit root replacement transaction. No fallback
is used to conceal a diff defect.

Development failures included an initial struct traversal bug, a capturing-regex
mistake, test fixture construction mistakes and stale mixed-version build caches.
All were corrected and rerun. A clean container-local build directory resolves
the stale Elixir type-checker artifact failure. No active failure was deferred.

## History and limits

The exact Phase 3 authorization enables a bounded Phase 2 snapshot reproduction.
Historical Phase 1/2 code, evidence and fixture meanings remain intact; current
Phase 3 hashes and scope are checked independently. No dependency, existing
runtime behavior, LiveView adapter or BH-02/BH-03 fixture was changed.

Intent cells contain canonical data only; they do not install listeners,
restore focus or execute effects. Fixture acknowledgements are synthetic
protocol inputs and do not prove browser execution. Browser queues, rollback,
real form/focus continuity, runtime delivery and LiveView remain later phases.
V2 is intentionally incompatible with v1 consumers. API state remains
experimental and support state unsupported.

[DEFERRED] Unavailable OS/browser/device/manual-AT qualification remains assigned
to inherited qualification owners, due by BH-22, without active pass credit.
Review was performed by the implementation agent, not an independent reviewer.

## Connections

- [Phase 3 checklist](phase-03-keyed-incremental-reconciliation-and-deterministic-diffing.md)
- [Phase 4 plan](phase-04-atomic-dom-application-root-queues-and-stale-rejection.md)
- [Milestone index](README.md)
