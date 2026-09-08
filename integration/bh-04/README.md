# BH-04 renderer integration

## Purpose

Current status: Phase 9 completes active standalone/headless conformance; Phase 8
LiveView/LocalLiveView integration is deferred. Phase 7 orders bounded effects and
cleanup. Phase 6 adds opt-in controlled forms, composition and owned focus/
selection continuity. Phase 5 adds bounded semantic listeners and root-local interaction
delivery with actual Elixir dispatch and correlated DOM commits. Phase 4 provides
atomic application and rollback/fallback isolation. The Phase 3 reconciler and Phase 2
v1 protocol remain immutable. Active Linux browser evidence is developmental,
not browser qualification or support.

Phase 1 activates evidence governance only. No incremental renderer behavior,
benchmark pass, browser qualification, or support is claimed.

## Index

- [Phase 9 reconciliation report](conformance-report.mjs) verifies raw observations, headless bindings, cross-engine/repeat equality and raw hashes before generating the deterministic active/deferred ledger.

- [Phase 9 isolation build](conformance-isolation.mjs) tests the headless and standalone packages with framework/adapter/profile directories physically absent and audits the standalone asset closure.

- [Phase 9 semantic fixture generator](support/conformance_runner.exs), [canonical fixtures](conformance-fixtures-v0.1.0.txt), [browser runner](conformance-browser.mjs), [observations](conformance-scenarios.js), and [comparator negatives](conformance-test.mjs) compare actual headless semantics and standalone DOM with framework integration deferred.

- [Phase 7 browser driver](effect-browser.mjs), [scenarios](effect-scenarios.js), and [independent replay](effect-conformance.mjs) exercise explicitly negotiated bounded timer effects, failure isolation and owned cleanup.

- [Continuity usage](continuity-usage.md) — additive form contract and digest-bound envelope, with runtime limitations.
- [Continuity browser runner](continuity-browser.mjs) — Chrome/Firefox and real offline ERTS.
- [Continuity scenarios](continuity-scenarios.js) — controlled drafts, composition, selection, focus and cleanup.
- [Continuity replay](continuity-conformance.mjs) — independent manifest/digest and transaction replay.

- [Interaction usage](interaction-usage.md) — negotiated v2 companion, ownership and runtime packaging limits.
- [Interaction browser runner](interaction-browser.mjs) — Chrome/Firefox and offline ERTS with a test-only DevTools/stdio carrier.
- [Interaction scenarios](interaction-scenarios.js) — all 13 mappings, native events, adversarial inputs, queue pressure and cleanup.
- [Independent interaction replay](interaction-conformance.mjs) — validates raw Elixir/browser records against the JS transaction model.

- [Atomic DOM usage](atomic-dom-usage.md) — owner capabilities, queues, rollback and limitations.
- [Atomic DOM fixture generator](support/atomic_dom_runner.exs) — actual Phase 3 setup and transition transactions.
- [Atomic DOM fixtures](atomic-dom-fixtures-v0.1.0.txt) — 50 canonical setup/transition traces.
- [Shared atomic DOM scenarios](atomic-dom-scenarios.js) — fake DOM and active-browser failure/stale/queue/lifecycle checks.
- [Active browser runner](atomic-dom-browser.mjs) — loopback Chrome/Firefox execution and raw evidence capture.

- [Phase 3 trace evidence](reconciliation-fixtures-v0.1.0.txt) — 50 canonical callback traces with before/after projections and acknowledgements.
- [Independent replay and fixture checker](reconciliation-fixtures.mjs) — Node data replay, negative cases and exact Elixir report comparison.
- [Phase 3 protocol fixtures](reconciliation-protocol-fixtures-v0.1.0.txt) — 116 positive/negative v2 records and trusted contexts.
- [Phase 3 protocol results](reconciliation-protocol-results-v0.1.0.txt) — canonical bytes, digests and rejection classes.

- [Incremental lifecycle usage](reconciliation-usage.md) — pending/accepted facade, retry semantics and unchanged full-root migration path.

- [Phase 3 v2 record schema](render-transaction-v2.schema.json) — extended closed attributes and complete canonical intent cells; incompatible with v1 consumers.

- [Fixture definitions](protocol-cases.mjs) — deterministic positive, negative and boundary records.
- [Fixture generator/checker](protocol-fixtures.mjs) — checks generated freshness and exact cross-language reports.
- [Canonical fixtures](protocol-fixtures-v0.1.0.txt) — name, expected code, canonical context and input bytes in base64.
- [Canonical results](protocol-results-v0.1.0.txt) — normalized bytes, full-record hashes and rejection classes.
- [Runner support](support/README.md) — actual Elixir package execution.

- [Phase 2 record schema](render-transaction.schema.json) — exact transaction, operation, acknowledgement, diagnostic and trusted-context shapes; maxBytes is an enforced UTF-8 extension.
- [Phase 2 inventory](protocol-inventory-v0.1.0.json) — closed vocabulary, limits and empty behavior results. Phase 2 supersedes activation-only scope with pure protocol work, not DOM behavior.

- [Empty versioned index](integration-index-v0.1.0.json) declares transaction,
  reconciliation, interaction, browser, LiveView adapter, failure, measurement,
  review and acceptance classes with no results.
- [Schema](activation-index.schema.json) fixes the complete Phase 1 value.

## Ownership and history

The bh-04-owner owns this boundary. BH-02 full-root fixtures and all BH-03
artifacts remain immutable; reuse is reference evidence, not incremental pass
credit. Later evidence requires separate authorization, a new version and
explicit supersession links. Phase 9 is complete; Phase 10 is eligible but separately unauthorized,
and BH-05 remains ineligible.
