---
title: "BH-05 Phase 9 Scope Evidence"
kind: note
created: "2026-09-09"
maturity: developing
tags:
  - bh-05
  - context
  - dynamic-components
aliases: []
---

# BH-05 Phase 9 Scope Evidence

Back to [milestone](README.md) and [scope contract](scope-contract.md).

## Implemented boundary

Opt-in scoped roots carry a frozen public context manifest and explicit provider
templates. Providers and subscriptions belong to one root generation. Nearest
lexical providers override declared defaults. Fixed context rejects changes;
tracked values retain the accepted consumer snapshot until a post-provider-commit
invalidation reaches that consumer in canonical tree order. Queue reservations
share the existing 256 total/128 message work bounds. Ordinary full-tree rendering
is retained; lifecycle updates depend on changed accepted invocation data.

Static provider and consumer grants must agree with component context declarations.
Host ingress cannot change or remove local-boundary providers. Both boundaries use
public portable values: no secrets, host handles, process objects or authoritative
client authentication. Removal drops dead subscriptions; replacement rebinds
runtime-owned initial templates to the new root generation. Stale revisions,
foreign roots/generations and altered invalidation digests reject before callbacks.

Registry composition accepts explicit compile/package/root lists of already-loaded
declared modules. Stable public IDs, roles, schema/contract versions, runtime,
capabilities, contexts and actions are validated. Dynamic sites have closed allowed
IDs and a declared registered fallback or redacted failure. Compatible same-ID
selection retains state; changed IDs replace identity. Registry metadata strips
module names and exports stable declaration hashes for later BH-06 reachability.
No input-derived atoms, module lookup, arbitrary apply or code loading is added.

## Fixtures and bounds

- [Public fixtures](../../../../../integration/bh-05/scope-fixtures.exs) combine
  a scoped root, stateful/pure registered targets, host-data contextual slots and
  an independent semantic oracle.
- [Integration tests](../../../../../integration/conformance/test/bh05_scopes_test.exs)
  exercise canonical invalidation, nearest providers, sibling-root isolation,
  dynamic replacement, fixed/unknown-ID rejection, renderer rollback and disposal.
- [Inventory](../../../../../integration/bh-05/scope-index-v0.1.0.json) binds all
  changed/new Elixir source files, twelve normalized digests and declared bounds.

The canonical integration order is `root,child,pure`. Subscription samples are
`3,3,3,3`, before and after the three consumer commits. Cleanup records one
replacement, one disposal and one rejected late ingress. The independent headless
oracle checks semantic output and final rendered state. Three new scope hashes
plus all nine inherited root/scheduling/action hashes must match exactly.

Core tests exercise 32 valid same-root providers and rejection of provider 33;
128 valid subscriptions and rejection above 128; replay equality; absent/default
resolution; fixed mutation; provider removal; malformed declarations; missing
grants; cross-root/generation values; secret-marked fields; and advisory auth.
Registry tests cover conflicting IDs, missing modules, schema/role/runtime/capability/
context/action mismatch, private/forged IDs, secret/module fields and 129 entries.
UI-tree tests cover commit reservations, renderer rejection, same-ID retention,
ID replacement, registered fallback, stale registry and local/host ingress checks.

## Validation and publication

All twenty gates passed against **1,094 source hashes**, unchanged throughout
the run at `/tmp/bh05-phase9-gates-tIUIoZ/execution.json`.

- [Frozen gates](../../../assets/bh-05-baseline/scope-gates-v0.1.0.json) retain
  exact commands, environment, raw outputs, timings and source hashes.
- [Completion](../../../assets/bh-05-baseline/scope-completion-v0.1.0.json) binds
  the accepted artifacts and Phase 10 eligible/unauthorized decision.

Package/conformance counts: Core 84, Effects 12, UI-tree 61, Renderer 8,
Headless 6, DOM 116, Test 3 and Conformance 88 — **378 tests**, zero failures.
JavaScript: **213 runtime + 7 DOM-driver tests**, zero failures. Compile fixtures:
**2 authoring + 3 schema tests**. Successor mutation suite: **7 tests**, all passing.
All twelve scope/root/scheduling/action digests match; no inherited trace changed.

The Phase 9 recorder runs twenty
gates: eight package/conformance suites, JavaScript, compile fixtures, runtime
subset audit, frozen Phase 1–8 and BH-04 replays, historical security/dependency
sweep, successor mutation tests, validator, generated authority, archive, JSON
and patch hygiene. It captures source hashes before and after execution and
refuses missing, duplicate, failed, stale or altered raw evidence. Publication
uses exclusive-create and cannot overwrite accepted records.

Phase 8 is replayed at `8e26ed110e1de2ab3be8039f27e5efaf7dea4117`.
All earlier replay pins remain those recorded by the accepted Phase 8 recorder;
no old validators or accepted artifact hashes are widened or silently regenerated.

Development failures are retained here: initial integration slot fixtures mixed
local references with host-boundary data and were rejected at startup. The final
fixture uses a host-data contextual slot on the pure descendant, with empty root
slots, retaining the frozen local/host contracts. A boundary test initially used
redacted root inspection instead of the actual submitted candidate; its fixture
now uses the accepted candidate without changing public inspection redaction.
Review also found that registry resolution inspected ordinary message payloads
as maps. It now examines only explicit scope-change work; an end-to-end scalar
message test retains ordinary scheduling semantics alongside dynamic selection.

## Limits and deferred work

This is ERTS/headless evidence only. Runtime/AtomVM compatibility is pinned API
and patch analysis, not Wasm execution or product support; Phase 11 owns runtime
parity and qualification. Callbacks and runtime configuration are trusted and
terminating; normalized queue bounds are not a hostile raw mailbox bound or
preemptive sandbox. Secret detection is structural, not interpretation of strings.

Limits: 16 context definitions, 32 providers, 128 subscriptions/components/registry
entries/call sites, and composition depth 12. Component declarations remain
within the frozen authoring compiler surface. Product context providers, Phoenix
sessions, arbitrary plugins, remote loading, server authority and BH-06 bundle
generation are excluded. Phase 10 owns expanded failure/disposal coordination.
LiveView and LocalLiveView remain explicitly deferred. Phase 9 completion makes
Phase 10 eligible, not authorized; BH-06 remains ineligible and support unsupported.
