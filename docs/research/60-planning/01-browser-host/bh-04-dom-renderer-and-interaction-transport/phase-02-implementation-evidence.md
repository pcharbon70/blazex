---
title: "BH-04 Phase 2 implementation evidence"
kind: note
created: "2026-09-07"
maturity: developing
tags:
  - bh-04
  - protocol
  - implementation-evidence
aliases: []
---

# BH-04 Phase 2 implementation evidence

## Decision

Phase 2 passed its pure protocol gate. Phase 3 is eligible but unauthorized.
BH-04 milestone acceptance and BH-05 eligibility remain outstanding. This adds
an internal data protocol, not incremental rendering or browser support.

The authorized base is `ccc2c358f837bfe9997a147a33f51353ce663dd7`;
branch `codex/bh04-phase2-protocol`; one commit per section and one PR.
The requested delivery sequence is merge, checkout main, synchronize origin,
verify equality, and delete both feature branch references. The final section
commit resolves from the commit introducing the completion record.

## Implemented sections

- **2.1:** Bound Phase 1 completion and renderer/identity/event/effect/resource/
  presentation/root-generation/full-root contracts. Froze compatibility, root
  ownership, revision and digest invariants and explicit implementation exclusions.
- **2.2:** Defined a closed schema with four transaction kinds, twelve operations,
  seven acknowledgement states, ten diagnostic classes and finite bounds.
- **2.3:** Implemented immutable Elixir constructors, bounded canonical codecs,
  browser-side pure validators, topology preflight, exact generated schema
  representations and shared fixtures. Existing neutral lifecycle needed no
  additions. The BH-02 batch and its Erlang-term digest remain unchanged.
- **2.4:** Ran all integration gates and strengthened completion provenance.
  Final review added newline-boundary regressions to prohibit prefix-only regex
  acceptance and avoid unhandled integer-parser exceptions.

## Reproduction and exact evidence

The [source index](../../../assets/bh-04-baseline/blazex-bh-04-phase-02-source-index-v0.1.0.json)
pins twenty source/schema/fixture/gate files. The
[completion record](../../../assets/bh-04-baseline/blazex-bh-04-phase-02-completion-v0.1.0.json)
binds the source index, authority, this note and the
[command log](../../../assets/bh-04-baseline/blazex-bh-04-phase-02-validation-log-v0.1.0.txt).

- 75 shared fixtures: 34 accepted records and 41 expected rejections.
  Actual Elixir and JavaScript runs agree on normalized bytes, full-record
  SHA-256 hashes, and error classes, not merely success booleans.
- Comparison report SHA-256:
  `bdf708a88d6103d481f13b7b23b9980d00c5338bed5a7ab9cc259119bd7e4d4e`.
- `node integration/bh-04/protocol-fixtures.mjs --compare <elixir-report>`
  checks both generated freshness and exact cross-language output.
- `mix run ../../integration/bh-04/support/protocol_runner.exs <output>`
  from the standalone DOM package invokes the real Elixir modules.
- Seven package formats/tests passed: core 13, effects 9, UI tree 23,
  renderer 8, standalone DOM 85, LiveView adapter 4, headless 6.
  Total current suite coverage: 148 tests. The initial complete package run had
  146; the final DOM rerun includes the two added boundary regressions.
- Runtime JavaScript build and 22 test files passed; the unchanged full-root
  DOM driver build and seven tests passed.
- 340 research tests passed, including 14 current Phase 2 governance tests and
  27 reproduced historical Phase 1 tests. All 26 governance validators and
  four archive generators passed.
- Draft 2020-12 schema validation and all 34 positive schema records passed.
  Both codecs separately enforce the normative UTF-8 maxBytes extension.
  JSON parsing, dependency/source audit and patch hygiene passed.

Environment: Linux; pinned local image `a2386c21edd5`, Elixir 1.17.3,
OTP 26 / erts 14.0.2; Node 24.3.0; npm 11.4.2; Python 3.12.12;
jsonschema 4.25.1; Git 2.49.0. Containers ran with networking disabled.

## Historical checks and scope control

Phase 1 deliberately rejected any later implementation. Its original validator,
tests and immutable evidence are reproduced from the exact accepted Git revision
in an isolated local clone. A hash-pinned Phase 2 authorization activates this
specific historical path. Current protocol validation remains a separate gate;
historical success cannot certify the new sources.

The Phase 2 gate freezes the 802 historical source/evidence files, verifies
unchanged Phase 1 records and inherited inputs, audits exact new executable
inventory and forbids runtime/browser dispatch surfaces in the new JS code.
No dependency manifest, existing runtime behavior, LiveView adapter source,
BH-02 fixture or historical acceptance record was changed.

During development, local Mix encountered sandbox socket restrictions and
container-owned previous build output; testing moved to the existing pinned
container. A fixture path and temporary historical Git-index isolation were
corrected before their section commit. These were not waived gate failures.

## Limitations and carried obligations

- Pure topology preflight is not a reconciler or DOM applicator. Old/new values
  are strict data assertions; comparing them with materialized values, listener
  placement and actual form state belongs to Phase 4/6.
- Queue capacity and the attribute ceiling are declared policy, not executed
  queue or browser measurements. The current fourteen-name attribute vocabulary
  is narrower than the 32-attribute ceiling. The recent-ID window is bounded;
  it is not a claim of global duplicate retention.
- Trusted admission code supplies a bounded attempt header for outcome
  correlation. Rejection records can describe stale or incompatible traffic
  without accepting it. No acknowledgement proves an operation was executed.
- The protocol is internal and experimental. Later changes require versioned
  compatibility review, both codec suites and BH-04 acceptance.
- Browser, measurement, reconciliation, DOM application, event transport and
  LiveView adapter result sets are empty. Existing demo controls are unchanged.
- [DEFERRED] Unavailable OS/browser/device/manual-AT qualification remains with
  inherited qualification owners, due by BH-22, with no pass credit. The active
  Linux protocol gate passed; no active failure was deferred.
- Review was performed by the implementation agent, not an independent review.

## Connections

- [Phase 2 checklist](phase-02-versioned-render-transaction-and-patch-protocol.md)
- [Protocol design](phase-02-protocol-design.md)
- [Milestone plan](README.md)
