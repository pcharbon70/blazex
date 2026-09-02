---
title: "2026-09-02 Elixir WebAssembly components deep dive"
kind: journal
created: "2026-09-02"
tags:
  - blazor
  - elixir
  - literature-search
  - package-audit
  - phoenix
  - research-session
  - webassembly
aliases:
  - "BlazeX architecture research session"
---

# 2026-09-02 Elixir WebAssembly components deep dive

## Observations

- The premise required correction: ordinary Blazor components are generated
  .NET classes in shared assemblies, not independent Wasm modules. In default
  Blazor WebAssembly publication, Mono is native Wasm and managed IL is
  interpreted with partial JIT support. Native Wasm application AOT is an
  optional, larger publish mode.
- Phoenix LiveView is the closest Elixir architectural analogue to Blazor's
  component renderer: declarative templates become structured render data,
  events update component state, compact changes reach JavaScript, and
  JavaScript owns the DOM. The important difference is that ordinary LiveView
  state executes on the server.
- Popcorn and LocalLiveView already implement the central proposed experiment.
  AtomVM runs inside Wasm, LocalLiveView state runs in browser Elixir
  processes, and LiveView's renderer/client protocol patches the page.
- “Elixir compiled to WebAssembly” in that stack means BEAM bytecode executed
  by a Wasm-hosted AtomVM. The distinction must remain visible in product and
  performance claims.
- LocalLiveView's very recent 0.1.0 release is strategically valuable but too
  young to make an unqualified production recommendation.

## Environment

- Host workspace: `/home/ducky/code/blazex` on Linux x86-64.
- Research date: 2026-09-02.
- Browser execution was not benchmarked in this pass.
- The repository contained no application code or dependency manifest when
  research began.
- Primary documentation baselines:
  - ASP.NET Core / Blazor .NET 10;
  - Phoenix 1.8.13;
  - Phoenix LiveView 1.2.11;
  - Plug 1.20.3;
  - Popcorn 0.3.3 documentation/source package;
  - LocalLiveView 0.1.0 source package.

## Evidence

### Source method

The review prioritized official Microsoft documentation and tagged ASP.NET
Core source, official Phoenix/LiveView/Plug documentation and source,
WebAssembly specifications, Bytecode Alliance Component Model tooling,
official project repositories, Hex package metadata, and the first-party
LocalLiveView release post. Search results were used to locate primary sources,
not as a substitute for them.

The source trail is preserved as individual records in
[`30-sources`](../30-sources/README.md).

### Local package inspection

Extracted package contents were inspected at:

```text
/tmp/local_live_view_research
/tmp/popcorn_research
```

The exact extracted archives had these SHA-256 values:

```text
ab387b9b3116192218da2d12d747ef45771a7617dfe102a87acd2109335c3918  local_live_view contents.tar.gz
af0a93258a1bc1a6d618af251dc69b98b315e230d033cf23ca66d279d9baecec  popcorn contents.tar.gz
```

Relevant LocalLiveView 0.1.0 runtime assets measured with `stat`:

```text
AtomVM.wasm          4,234,209 bytes
AtomVM.mjs             304,708 bytes
iframe.mjs               7,265 bytes
local_live_view.js       48,395 bytes
raw subtotal          4,594,577 bytes
```

`gzip -9 -c AtomVM.wasm | wc -c` produced `1,416,258` bytes. This is a
measurement of one asset under one compressor setting, not the complete
network payload. The LocalLiveView package archive itself measured 1,555,925
bytes; an application `.avm`, CSS, and host application assets are additional.
The first-party release post reports an experimental tree-shaken Kanban demo
at approximately 1.8 MB for all compressed assets, but its exact measurement
method and device startup costs were not reproduced here.

### Source files inspected

The LocalLiveView package inspection included:

```text
lib/local_live_view/application.ex
lib/local_live_view/dispatcher.ex
lib/local_live_view/server.ex
lib/server/component.ex
lib/server/channel.ex
lib/server/mirror.ex
priv/static/local_live_view.js
priv/templates/llv.install/*
pages/guides/first-view.md
pages/guides/mirror-sync.md
mix.exs
```

The inspection found:

- one shared Popcorn runtime with LocalLiveView instances dispatched to local
  Elixir processes;
- use of private `Phoenix.LiveView.Diff`, renderer, lifecycle, and utility
  modules;
- a JavaScript transport shaped to reuse the existing LiveView client;
- a host component that marks a DOM root and transfers initial assigns;
- `push_server_event` and mirror-channel mechanisms for server interaction;
- a declared Popcorn 0.3.3 dependency and LiveView `~> 1.1` build dependency.

The Popcorn 0.3.3 `mix.exs` inspection found an exact OTP 26.0.2 check and an
exact Elixir 1.17.3 requirement. Popcorn's public limitations also document an
unstable API, incomplete AtomVM OTP/NIF coverage, JSON/`postMessage` interop
constraints, and limited debugging.

### What was not demonstrated

- No browser startup, memory, interaction-latency, or mobile measurements were
  run.
- No Phoenix application was generated and no component was compiled.
- No SSR/hydration path was demonstrated.
- No Plug-only renderer or transport was implemented.
- No security test, cross-origin third-party integration test, or offline
  synchronization test was run.
- No claim was made that AtomVM supports arbitrary Elixir/OTP libraries.

## Threads

- [The main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
  develops the architecture and staged recommendation.
- [The operational inquiry](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md)
  turns the remaining uncertainty into testable gates.
- [The topic map](../10-maps/elixir-webassembly-components.md) organizes the
  primary evidence and alternative paths.

## Follow-ups

- Build a pinned Phoenix/LocalLiveView example and preserve its lockfile,
  emitted manifest, compressed assets, and browser trace.
- Add conformance tests that execute one component on BEAM and AtomVM.
- Benchmark cold and warm startup on desktop and low-end mobile hardware.
- Prototype a versioned renderer adapter that makes every private LiveView
  dependency explicit.
- Test required third-party resources and popup flows under COOP/COEP.
- Specify one signed, idempotent, server-authorized command protocol over both
  Phoenix Channels and plain Plug.
