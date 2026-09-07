# BH-04 renderer integration

## Purpose

Phase 1 activates evidence governance only. No incremental renderer behavior,
benchmark pass, browser qualification, or support is claimed.

## Index

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
explicit supersession links. Phase 2 is not authorized; BH-05 is ineligible.
