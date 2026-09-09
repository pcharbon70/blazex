---
title: "BH-05 Scoped Context and Registry Contract"
kind: note
created: "2026-09-09"
maturity: developing
tags:
  - bh-05
  - context
  - dynamic-components
aliases: []
---

# BH-05 Scoped Context and Registry Contract

## Authority and compatibility

Phase 9 follows accepted Phase 8 PR #59 at `8e26ed110e1de2ab3be8039f27e5efaf7dea4117`.
The owner authorized four verified section commits, one PR and merge, then main
synchronization before branch deletion. Existing Phase 1–8 evidence remains
sealed; successor tooling reviews only explicit Core input/coordinator and
outward evaluator seams. Default roots preserve all earlier normalized traces.

The version is `0.1.0-bh05-scopes`. Context and registry are opt-in runtime
composition, not globals or server authority. Core holds closed public records;
UI-tree performs lexical composition and evaluates declared modules. Providers
and consumers explicitly declare names using existing component `context`
metadata and static per-public-ID provide/consume grants. No compiler reflection
or import-allowlist expansion is authorized.
Context manifest identity is frozen within a root generation. Initial providers
are runtime-owned templates rebound to the new generation only on explicit root
replacement; host update records must always carry the current generation.

## Context records

At most 16 context declarations, 32 providers and 128 subscriptions exist per
root. Declarations contain name (map key), schema version 1, schema, boundary
(`local` or `host`), fixed/tracked mode, absent/present default, documentation,
public visibility and advisory marker. Auth-related data must be advisory;
authorization decisions, credentials, secrets and provider/renderer objects
are rejected structurally. Both boundaries retain public portable values;
local callable schemas are not admitted into this bounded context facility.
There is no implicit persistence, command or host/local conversion.

Provider identity is owner component identity plus context name. Owner must
be live in this root generation and have a static provide grant. Duplicate
same-scope providers reject before descendant callbacks. Values normalize under
the declared boundary and retain an accepted digest and revision. Consumers
resolve the nearest visible ancestor (including self) in the composition tree,
or an explicit declared default; absent required values reject. Slot context
props remain distinct from named context and retain existing lexical rules.

Tracked dependencies record consumer, provider/default identity, name, schema,
mode and digest. Provider changes commit first using accepted consumer values;
only then do bounded canonical-preorder invalidations update consumer context
and trigger ordinary lifecycle updates. Existing render traversal still occurs
for each root candidate. All invalidations reserve space inside the existing
256-work scheduler budget. They carry root/generation, scope revision and desired
dependency digest; stale notifications reject before callbacks. Fixed bindings
reject later resolution/value changes while a consumer identity survives.
Replacement/removal drops subscriptions; no global registry, process dictionary
or application environment supplies component context. An update is a single
bounded snapshot, never recursive propagation, with depth inherited at 12.

## Manifest-bounded registry

A runtime-private registry composes explicit compile/package/root lists of
at most 128 entries total. Duplicate IDs are conflicts even when records match.
Each entry binds stable public ID, already loaded declared module, pure/stateful
role, contract/schema version, supported runtime subset, capability/context/action
names, package, public/private visibility and optional feature-bundle ID.
Only public metadata without module names is exported for BH-06; a feature ID
is declarative and does not load a bundle. Component metadata must agree with
the registration. Unknown versions, missing modules and incompatible roles
reject during composition. No atom creation, input-derived module names,
unrestricted reflection, arbitrary apply or code loading occurs during lookup.

Dynamic call sites declare an allowed-ID list, expected role/schema version,
registry generation, props/slots, stable key/site and either an explicit registered
fallback ID or a redacted diagnostic. Lookup validates all authority and schema
requirements before callback invocation. IDs and contracts participate in normal
keyed identity/reconciliation: compatible same-ID invocations retain state;
different IDs replace identities. Same-ID contract changes require a new root
generation, not silent migration. Caller grants cannot be supplied by host input.

## Evidence and exclusions

Run current package, context/registry integration, mutation, dependency/security,
archive/generated/JSON and hygiene gates plus frozen Phase 1–8/BH-04 replays.
Retain exact commands, source hashes, context/registry exports, canonical traces,
negative cases, cleanup, failures and qualification limits. Only passing evidence
makes Phase 10 eligible, unauthorized. BH-06 bundles/reachability, product theme/
form/auth providers, Phoenix sessions, plugins and remote loading are excluded.
LiveView and LocalLiveView remain deferred. ERTS evidence and pinned API analysis
do not grant Wasm execution parity; Phase 11 owns runtime qualification.

## Connections

- [Milestone](README.md)
- [Phase 9 plan](phase-09-scoped-context-and-manifest-bounded-dynamic-components.md)
- [Action contract](action-contract.md)
