---
title: "BH-06 Feature-Bundle Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, contract, feature-bundles, wasm]
aliases: []
---

# BH-06 Feature-Bundle Contract

Back to the [Phase 7 plan](phase-07-deterministic-feature-bundles.md).

## Planning and ownership

The versioned policy declares one base bundle, base-owned startup modules, and
one or more feature IDs with exact module sets. Planning consumes path-free
logical labels, module strings, byte counts, digests, and an explicit bundle ID
for every candidate BEAM. No input may be unowned or multiply declared.

Every declared feature must be non-empty and exactly represented. Startup
modules must belong to base. Duplicate IDs/modules, unknown bundle IDs,
duplicate labels/modules, malformed declarations, and explicit count or byte
overflow reject before any archive is created. Normalized plans sort bundles
and inputs by stable identity and retain no filesystem path.

## Packaging and runtime load

The base AVM owns boot, the host bridge, shared framework/runtime code, and the
AtomVM start module. Feature AVMs have no start module. Every archive and the
bundle plan are content-addressed manifest artifacts. The host verifies the
selected feature's SHA-256 and length before transferring it to the running VM.

The bridge first proves the counter module is unavailable, accepts the verified
feature as base64, decodes it, and calls AtomVM's `add_avm_pack_binary/2` in the
same VM. A successful feature ID may load once; unknown or duplicate loads
reject. Mount and later operations are unavailable until loading succeeds.

## Boundary

This proves separately packaged, acquired, and loaded code in one shared
runtime. It does not establish route selection, arbitrary plugin loading,
prefetch policy, payload budgets, production cache/service-worker behavior, or
BH-19 package distribution. LiveView and LocalLiveView are **[DEFERRED]** and
are not bundle owners, load transports, or completion gates.

