# BlazeX

BlazeX is a planned host-neutral UI component framework for Elixir. It aims to
offer a semantically rich component system inspired by MudBlazor while keeping
component definitions independent of any one renderer, runtime, or server
framework.

The first supported host will be the web browser, using an Elixir WebAssembly
runtime, a DOM renderer, and optional Phoenix or Plug integration. The
architecture deliberately leaves room for future native-control, WebView, and
standalone WebAssembly hosts without making browser concepts part of the core.

This repository is currently an architecture and research scaffold. The
directories below are tracked with responsibility and dependency-boundary
documents; they are not Mix or JavaScript projects yet.

## Repository structure

```text
blazex/
├── packages/       Reusable Elixir libraries and host adapters
├── js/             Browser-side JavaScript runtime packages
├── profiles/       Executable compositions of packages
├── integration/    Cross-package fixtures, conformance tests, and benchmarks
├── experiments/    Bounded architecture proofs that are not product packages
└── docs/research/  Research corpus, architecture notes, and planning
```

The reusable packages represent independent architectural axes:

- component semantics, effects, capabilities, and semantic UI trees;
- renderer contracts and concrete renderer backends;
- component families;
- WebAssembly runtime and host capability adapters; and
- Phoenix and Plug server integrations.

Executable profiles compose those axes into supported products. In particular,
Phoenix is an adapter used by the browser/Phoenix profile, not the container for
the entire framework.

## Dependency direction

Dependencies should flow from concrete hosts and profiles toward stable,
host-neutral contracts:

```text
component libraries -> core + effects + semantic UI tree
renderer backends   -> renderer contract + semantic UI tree
host adapters       -> effects + core/runtime contracts
server adapters     -> host-neutral packages + their server framework
profiles            -> the packages required for one executable composition
```

Core packages must not acquire dependencies on Phoenix, Plug, browser DOM
types, JavaScript APIs, Popcorn, or a future native UI toolkit. Concrete
adapters may depend inward on the shared contracts, but shared contracts must
not depend outward on an adapter.

## Project activation

A scaffold becomes an independent Mix or JavaScript project only when an
implementation milestone requires it. Each activated project should own its
toolchain configuration and lockfile, while local development can use path
dependencies. This avoids committing prematurely to a single Mix umbrella and
lets packages remain independently testable and publishable where useful.

The initial executable target is [`profiles/browser_phoenix`](profiles/browser_phoenix/README.md).
Its standalone DOM renderer and LiveView-specific lowering are separate
packages. The Plug profile uses only the standalone renderer, while the
headless profile establishes that Phoenix, LiveView, and the browser are
replaceable composition choices rather than core requirements.

## Research and planning

The evidence base, architecture maps, design notes, and planning scaffold live
under [`docs/research`](docs/research/README.md). The current package, profile,
integration, and experiment ownership rules are collected in the
[`BlazeX repository ownership and dependency map`](docs/research/10-maps/blazex-repository-ownership-and-dependency-map.md).
