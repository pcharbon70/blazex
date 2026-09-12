---
title: "BH-06 Entrypoint and Reachability Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [beam, bh-06, build, contract, entrypoint, reachability]
aliases: []
---

# BH-06 Entrypoint and Reachability Contract

Back to [Phase 2](phase-02-explicit-entrypoints-and-deterministic-reachability.md).

An entrypoint is an explicit bounded ID plus a fully qualified Elixir module
name. Input strings are never converted to atoms. A root must resolve to exactly
one supplied BEAM module and distinct IDs must not alias one root accidentally.

The analyzer reads only regular BEAM files supplied by trusted build
configuration. Its canonical inventory contains module names, content digests,
imports, and exports; it contains no absolute paths, mtimes, or map iteration
order. Duplicate modules and malformed BEAM files fail closed.

Reachability follows statically imported modules that exist in the supplied
inventory. Each reachable module records a shortest reason chain beginning at
an entrypoint ID; lexical ordering breaks equal-length ties. Imports outside
the inventory are retained as external references rather than silently treated
as bundled. Inventory modules not reached by any root are reported as unused
and are not eligible for the bundle closure.

Direct imports of `erlang:apply/2`, `erlang:apply/3`, or equivalent runtime
dispatch primitives are rejected unless the declaring module is explicitly
allowlisted by trusted configuration with a bounded textual reason. This is a
first anti-ambiguity gate, not a complete call-graph or adversarial Elixir
sandbox. Later phases own server/native dependency classifications, secret
configuration, compatibility profiles, licenses, and production support.

LiveView and LocalLiveView remain **[DEFERRED]** and are not entrypoints,
analyzer dependencies, or completion gates.
