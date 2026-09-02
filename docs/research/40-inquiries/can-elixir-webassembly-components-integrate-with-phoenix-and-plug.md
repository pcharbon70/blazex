---
title: "Can Elixir WebAssembly components integrate with Phoenix and Plug?"
kind: inquiry
created: "2026-09-02"
status: open
tags:
  - components
  - elixir
  - phoenix
  - plug
  - research-program
  - webassembly
aliases:
  - "BlazeX feasibility inquiry"
---

# Can Elixir WebAssembly components integrate with Phoenix and Plug?

## Why this matters

Blazor demonstrates that a managed-language component model can execute both
on a server and in a browser-hosted WebAssembly runtime. Phoenix LiveView
already supplies Elixir developers with declarative HEEx, component
composition, process-shaped state, compact diffs, a mature browser patcher,
and server bridges. Combining those ideas could make latency-sensitive,
offline-capable UI state possible without changing languages.

The browser-local profile fails if it depends permanently on one exact
OTP/Elixir pair, ships an unacceptable fixed payload, cannot render reliably
across BEAM and AtomVM, requires unstable private LiveView APIs, breaks common
third-party web integrations through cross-origin isolation, or encourages
trusted decisions in client state.

This inquiry now evaluates the first Popcorn/AtomVM plus Phoenix/Plug profile,
not the universal BlazeX architecture. The separate [cross-renderer
inquiry](can-one-blazex-component-model-target-dom-and-native-controls.md)
tests whether the component model remains valid for non-browser and native
control hosts.

## Operational question

For a pinned browser, Phoenix, LiveView, AtomVM, Popcorn, OTP, and Elixir
matrix, can a framework:

1. compile a declared client-safe Elixir dependency graph into reproducible
   `.avm` bundles and reject unsupported modules or NIFs before deployment;
2. boot one shared browser runtime and mount multiple isolated local views
   without one runtime per visual component;
3. preserve documented `mount`, `update`, `handle_event`, `handle_info`,
   `render`, component identity, lifecycle, and disposal semantics;
4. produce equivalent initial markup on ordinary BEAM and browser AtomVM, then
   activate it without duplicate effects, lost form state, or visible
   replacement;
5. apply compact render updates while preserving focus, selection, hooks,
   forms, uploads, and nested component identity;
6. run local events offline while routing privileged commands through a
   server-validated Phoenix Channel or portable Plug transport;
7. meet explicit cold/warm payload, startup, memory, local-event latency, DOM
   patch, and build-time budgets on desktop and representative mobile devices;
8. coexist with the target application's CDN, OAuth, payment, analytics, and
   embedding requirements under the necessary browser headers; and
9. rely only on public, versioned interfaces or carry a bounded, tested
   compatibility adapter with a credible upstream path?

A proof-of-concept counter answers none of these by itself. A positive answer
requires reproducible conformance, integration, and browser benchmark suites.

## Working hypotheses

- **H1 — runtime-in-Wasm is viable:** Popcorn and LocalLiveView demonstrate the
  central event/render loop, making a framework prototype immediately
  practical.
- **H2 — Phoenix first:** Phoenix/LiveView materially reduces server-integration
  work through HEEx, Channels, PubSub, sessions, assets, and an optional DOM
  patching adapter. BlazeX still owns a standalone DOM renderer so Plug-only
  hosting does not inherit Phoenix or LiveView.
- **H3 — shared runtime:** the viable packaging unit is one shared AtomVM plus
  one or more application bundles, not one Wasm instance per component.
- **H4 — compatibility dominates:** AtomVM's OTP/NIF subset and Popcorn's exact
  toolchain pins will be a larger adoption barrier than writing the component
  callbacks.
- **H5 — renderer API is decisive:** production maintainability depends on a
  BlazeX-owned standalone DOM protocol plus a bounded, version-tested adapter
  wherever LiveView or LocalLiveView patching is used.
- **H6 — SSR is possible but not free:** server and local execution of the same
  HEEx modules can enable prerendering, but state transfer, deterministic
  initialization, and effect ownership require explicit design.
- **H7 — two products may be needed:** full Elixir semantics favor the shared
  AtomVM runtime; tiny native-Wasm islands favor a restricted Orb-like DSL.
  One backend is unlikely to optimize both goals.
- **H8 — browser success must not define the ABI:** semantic nodes, events,
  effects, and resources must remain independent of HEEx/DOM so desktop native
  renderers can use the same component model.

## Paths to explore

### Compatibility and build analysis

- Pin LocalLiveView and Popcorn releases and produce a complete transitive
  module/NIF support report during `mix blazex.build`.
- Run the same pure component modules under BEAM and AtomVM and compare
  lifecycle traces, rendered structures, exceptions, arithmetic, binaries,
  timers, processes, and message ordering.
- Test component packages as separately loadable `.avm` feature bundles.

### Rendering and activation

- Define a public renderer protocol independent of private LiveView structs,
  then build an adapter to the current LiveView diff/JavaScript client.
- Golden-test initial HTML and subsequent diffs across runtime versions.
- Prototype static prerender plus a signed, versioned state envelope; verify
  focus, forms, hooks, nested components, navigation, and failure fallback.

### Server and offline behavior

- Implement the same typed command contract over Phoenix Channels and a plain
  Plug HTTP/WebSocket adapter.
- Test disconnect, retry, deduplication, optimistic updates, conflict handling,
  multiple tabs, deploy-version mismatch, and server revocation.
- Verify that authorization and domain invariants remain server-owned.

### Performance and deployment

- Measure compressed fixed runtime size, route bundle size, parse/compile/boot
  time, first component mount, warm-cache navigation, memory, event-to-paint
  p50/p95, and build time.
- Include low-end Android hardware and constrained network profiles.
- Audit COOP/COEP interactions with every required cross-origin resource and
  popup flow.

## Findings

- The [main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
  finds the architecture technically feasible and recommends an adapter layer
  over Popcorn and LocalLiveView instead of a new VM/compiler.
- [Popcorn](../30-sources/software-mansion-2026-popcorn-documentation-and-source.md)
  compiles AtomVM to Wasm and executes ordinary BEAM bytecode from `.avm`
  bundles; it does not AOT-compile general Elixir modules into native Wasm.
- [LocalLiveView](../30-sources/software-mansion-2026-local-live-view-first-release.md)
  already demonstrates browser-local LiveView-shaped processes and reuses the
  stock LiveView browser patcher, but version 0.1.0 depends on private APIs and
  has no completed SSR path.
- The [research journal](../50-journal/2026-09-02-elixir-webassembly-components-deep-dive.md)
  records a 4,234,209-byte raw AtomVM Wasm asset in the inspected 0.1.0 package
  and a 1,416,258-byte gzip result before application bundle and remaining
  runtime assets.
- Blazor validates the shared-runtime model and multi-host component
  abstraction, while its optional AOT mode has no general Elixir equivalent
  today.
- The [host-neutral architecture](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
  makes this browser stack one runtime/renderer profile and requires an early
  native-control proof before F0 API stability.

## Outcome

Open. The evidence supports a bounded prototype, not a production-readiness
claim. The next decisive result is a pinned Phoenix application that mounts
several local views, passes BEAM/AtomVM conformance tests, records mobile cold
and warm performance, and proves one secure server-command flow. SSR,
Plug-only rendering, and broad package compatibility should remain gated until
that baseline is reproducible.
