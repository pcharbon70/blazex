---
title: "ERTS releases, external ports, and native integration"
kind: source
created: "2026-09-03"
authors:
  - "Elixir team"
  - "Erlang/OTP team"
  - "Rustler contributors"
published: null
citation_key: "erlang-elixir-2026-releases-ports-native"
container: "Elixir, Erlang/OTP, and Rustler documentation"
edition: null
isbn: null
doi: null
url: "https://mix.hexdocs.pm/Mix.Tasks.Release.html"
accessed: "2026-09-03"
tags:
  - beam
  - desktop
  - elixir
  - erlang
  - ffi
  - runtime
aliases:
  - "Native BEAM host integration evidence"
---

# ERTS releases, external ports, and native integration

## Reference

Elixir team. [`mix release`](https://mix.hexdocs.pm/Mix.Tasks.Release.html).
Erlang/OTP team. [Interoperability overview](https://www.erlang.org/docs/27/system/overview.html),
[`open_port/2`](https://www.erlang.org/doc/apps/erts/erlang.html), [ports and
port drivers](https://www.erlang.org/docs/28/system/ports.html), and [NIF
resources](https://www.erlang.org/doc/apps/erts/erl_nif.html). Rustler
contributors. [`Env`](https://docs.rs/rustler/latest/rustler/env/struct.Env.html),
[`OwnedEnv`](https://docs.rs/rustler/latest/rustler/env/struct.OwnedEnv.html),
and [`ResourceArc`](https://docs.rs/rustler/latest/rustler/struct.ResourceArc.html).
Accessed 2026-09-03.

## Research question or contribution

Should BlazeX embed the native GUI in ERTS, embed ERTS in the GUI, or connect
a normal release to an external host process?

## Findings

- Mix releases are self-contained and include ERTS by default, but each build
  is tied to the target architecture, OS/vendor, and ABI. Windows also has
  Visual C++ runtime considerations.
- Erlang's interoperability guidance warns that faulty NIFs can crash, hang,
  leak, or compromise the complete runtime and recommends an external port
  where its overhead is acceptable.
- `open_port/2` can launch an explicit executable with binary delivery,
  one/two/four-byte packet framing, exit-status reporting, and queue limits.
- Rustler improves type and resource safety but does not create a new failure
  domain. `Env` is not transferable between threads; native-created threads
  communicate through `OwnedEnv`, while resources need thread-safe ownership.
- No supported public `libbeam`-style API for embedding a complete ERTS VM in
  an arbitrary GUI executable was found.

## Relevance

A target-specific ERTS release plus a separate main-thread native host is the
least speculative first desktop profile. Ports give enough transport for the
correctness proof; optimized shared memory should wait for profiling.

## Limits

No port throughput, launcher process tree, inherited-descriptor strategy, or
release artifact was tested. Documentation pages span OTP versions because
the relevant mechanisms are documented separately; the implementation must
pin and verify one supported OTP/Elixir baseline.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Cross-renderer portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)

