---
title: "WebAssembly non-web embeddings and WASI host capabilities"
kind: source
created: "2026-09-02"
authors:
  - "WebAssembly Community Group"
  - "WASI Subgroup"
published: null
citation_key: "webassembly-community-group-2026-non-web-wasi"
container: "WebAssembly and WASI official documentation"
edition: null
isbn: null
doi: null
url: "https://webassembly.org/docs/non-web/"
accessed: "2026-09-02"
tags:
  - capability-model
  - non-web
  - wasi
  - webassembly
aliases:
  - "Non-browser WebAssembly hosting"
---

# WebAssembly non-web embeddings and WASI host capabilities

## Reference

WebAssembly Community Group. [Non-Web
Embeddings](https://webassembly.org/docs/non-web/),
[Portability](https://webassembly.org/docs/portability/), and [WebAssembly
specifications](https://webassembly.org/specs/). WASI Subgroup. [WASI
introduction](https://wasi.dev/). Accessed 2026-09-02.

## Research question or contribution

Does WebAssembly intrinsically require a browser, and which contracts can a
BlazeX runtime rely on when the execution host is a desktop process,
standalone runtime, server, edge worker, or embedded system?

## Findings

- Core WebAssembly is specified independently of a concrete host. It defines
  an import mechanism, not a filesystem, network, DOM, window, or operating
  system API.
- The official non-web embedding guidance explicitly includes servers,
  datacenters, IoT devices, mobile/desktop applications, embedded use inside
  larger programs, JavaScript VMs, and environments without JavaScript.
- A `.wasm` artifact is portable only when a target host can fulfill its
  imports. A module built around browser JavaScript imports is not thereby a
  WASI application and will not necessarily instantiate in a standalone
  runtime.
- WASI is a standards-track family of capability-oriented interfaces for
  non-web and web-capable hosts. Current documentation lists command-line,
  HTTP, clocks, randomness, streams, filesystem, networking, and related
  system facilities across WASI releases.
- WASI applications receive only the capabilities supplied by the host. This
  is useful for least-authority BlazeX hosts, but it does not define UI
  components, native widgets, layout, accessibility, or a window system.
- Source-level portability requires an abstraction or library that maps a
  stable source interface onto each host's imports. This is directly
  analogous to a BlazeX host-capability adapter.

## Relevance

BlazeX can treat the browser as one execution profile rather than its
fundamental boundary. The public component kernel should depend on semantic
render and capability protocols; browser Web APIs, desktop services, and
WASI imports should implement those protocols in separate adapters.

## Limits

The official documentation establishes portability and host layering, not
the feasibility of running Popcorn's current browser-targeted AtomVM artifact
under WASI. That would require inspecting and implementing its exact imports.
WASI is evolving, and support varies by runtime and release.

## Derived work

- [Host-neutral BlazeX architecture and native control backends](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Host-neutral and native-renderer map](../10-maps/host-neutral-and-native-renderer-architecture.md)
- [Native-control portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
