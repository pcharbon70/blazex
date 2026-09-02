---
title: "Popcorn 0.3.3 architecture, build pipeline, and limitations"
kind: source
created: "2026-09-02"
authors:
  - "Software Mansion"
published: 2026
citation_key: "software-mansion-2026-popcorn"
container: "Popcorn documentation, source, and Hex package"
edition: "0.3.3"
isbn: null
doi: null
url: "https://github.com/software-mansion/popcorn"
accessed: "2026-09-02"
tags:
  - atom-vm
  - elixir
  - managed-runtimes
  - popcorn
  - webassembly
aliases:
  - "Popcorn architecture"
---

# Popcorn 0.3.3 architecture, build pipeline, and limitations

## Reference

Software Mansion. Popcorn 0.3.3 project, documentation, and Hex source
package. Accessed 2026-09-02. Principal pages:

- [Architecture](https://popcorn.hexdocs.pm/architecture.html)
- [First steps](https://popcorn.hexdocs.pm/first_steps.html)
- [Limitations](https://popcorn.hexdocs.pm/limitations.html)
- [Source repository](https://github.com/software-mansion/popcorn)

## Research question or contribution

Popcorn supplies the missing browser runtime for ordinary compiled
Elixir/Erlang modules. It is the most direct evidence that a BlazeX local
component process can execute in a browser while retaining a useful subset of
BEAM semantics.

## Method

The public architecture/setup/limitations documentation was read and the
extracted Popcorn 0.3.3 Hex source package was inspected, including `mix.exs`,
build modules, tree-shaking modules, JavaScript output conventions, and the
vendor packbeam integration.

## Findings

- Popcorn compiles the AtomVM runtime to WebAssembly and runs compiled BEAM
  bytecode inside it. Application modules are packaged into an `.avm` bundle;
  they are not generally AOT-compiled to native Wasm.
- AtomVM executes inside a hidden iframe to isolate hangs/crashes from the main
  window. The main JavaScript library communicates with it using
  `postMessage`.
- Runtime output includes `AtomVM.wasm`, `AtomVM.mjs`, iframe/interop code, and
  one or more application bundles.
- The build patches selected Erlang/Elixir standard-library modules to work
  around AtomVM limitations, recompiles them, and packages them with the app.
- `mix popcorn.cook` creates the application bundle; JavaScript bundler plugins
  integrate runtime assets.
- The current API is explicitly unstable. AtomVM lacks complete OTP, BEAM, and
  NIF coverage; documented gaps include large integers/bitstrings,
  distribution, and portions of ETS, logger, timers, and random facilities.
- JavaScript/Elixir calls use JSON-compatible values over `postMessage`, with
  opaque references for complex JavaScript objects. The boundary adds latency.
- Public setup documentation and the inspected 0.3.3 `mix.exs` require exact
  OTP 26.0.2 and Elixir 1.17.3 versions.
- Shared-memory support requires cross-origin-isolation headers in the current
  browser setup.
- An experimental tree shaker analyzes the reachable module/function graph to
  reduce bundles.

## Relevance

Popcorn makes a BlazeX proof of concept an integration and framework task
rather than a VM implementation project. It also establishes the initial
constraints that BlazeX must expose through build diagnostics and a tested
runtime-support profile.

## Limits

The project is work in progress and does not claim arbitrary OTP compatibility
or stable APIs. This research did not benchmark its interpreter, memory use,
iframe restart behavior, or interop latency in a browser.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [BlazeX feasibility inquiry](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md)
- [Local package audit journal](../50-journal/2026-09-02-elixir-webassembly-components-deep-dive.md)
