---
title: "BH-06 Client-Safety Policy Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, client-safety, contract, native, server]
aliases: []
---

# BH-06 Client-Safety Policy Contract

Back to [Phase 3](phase-03-server-native-client-safety-gate.md).

The classifier consumes the accepted Phase 2 reachability report, the trusted
path-free BEAM inventory that produced it, and one versioned policy. Inventory
records carry a bounded application ID supplied by trusted build configuration;
filesystem paths are never policy identities and never enter reports.

Every reachable module resolves through an exact module override or its exact
owning application, in that order. Every external module resolves through an
exact external-module rule. Reachable classifications are `client-safe`,
`server-only`, or `native`; external classifications are `runtime-safe`,
`server-only`, or `native`. Unknown ownership, missing rules, contradictory
duplicates, and unused overrides fail closed. Prefix and regular-expression
matching are excluded so similarly named modules cannot inherit authority.

The policy also names exact forbidden imports. Calls that load NIFs, open or
control ports, or otherwise cross the native runtime boundary are rejected
even when the containing application is marked client-safe. Stable diagnostics
name the reachable source module, policy identity, classification, and reason,
but never include absolute source paths or environment values.

A passing report is an explanation of the bounded candidate closure, not a
general Elixir sandbox or proof that AtomVM implements every API. Secret and
configuration scanning, compatibility profiles, licenses, payload budgets,
and production manifests remain later BH-06 work.

LiveView and LocalLiveView remain **[DEFERRED]**. They are not client roots,
allowed server dependencies, or completion gates.
