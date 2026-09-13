---
title: "WASI and WebAssembly threading proposal status"
kind: source
created: "2026-09-13"
authors:
  - "WebAssembly Community Group"
  - "WASI Subgroup"
published: null
citation_key: "webassembly-project-2026-wasi-threading-status"
container: "WebAssembly and WASI proposal repositories"
edition: null
isbn: null
doi: null
url: "https://github.com/WebAssembly/WASI/blob/main/docs/Proposals.md"
accessed: "2026-09-13"
tags:
  - browser
  - shared-memory
  - threads
  - wasi
  - webassembly
aliases:
  - "Current WASI threads status"
---

# WASI and WebAssembly threading proposal status

## Reference

WebAssembly Community Group and WASI Subgroup. [WASI proposal
registry](https://github.com/WebAssembly/WASI/blob/main/docs/Proposals.md),
[legacy `wasi-threads`
proposal](https://github.com/WebAssembly/wasi-threads/blob/main/README.md),
[Shared-Everything Threads
overview](https://github.com/WebAssembly/shared-everything-threads/blob/main/proposals/shared-everything-threads/Overview.md),
and [Core WebAssembly Threads
overview](https://github.com/WebAssembly/threads/blob/main/proposals/threads/Overview.md).
Living project records accessed 2026-09-13.

## Research question or contribution

Do current WASI or WebAssembly thread proposals supply a standardized browser
thread host that a first ERTS/Wasm proof can target instead of Emscripten's
Worker-based pthread implementation?

## Findings

- Core WebAssembly Threads standardizes shared linear memory, atomic
  operations, and wait/notify. It deliberately leaves thread creation and
  joining to the embedder; a browser uses Web Workers for that host role.
- The original `wasi-threads` repository labels itself a legacy proposal for
  WASI Preview 1 engines. It remains at Phase 1 and uses an instance-per-thread
  spawn design.
- That repository directs future work to Shared-Everything Threads. The latter
  is also Phase 1 and warns that it is under active development; it proposes
  shared functions, tables, globals, thread-local state, and Component Model
  thread-lifecycle built-ins in addition to already shared memories.
- The current WASI proposal registry lists Threads at Phase 1. It does not turn
  browser JavaScript APIs into a native WASI environment or remove the need for
  a browser embedder.
- Emscripten's established pthread-to-Worker implementation is therefore the
  more concrete first browser experiment for an upstream C runtime. A future
  WASI/non-browser ERTS target remains a separate ABI and product decision.

## Relevance

BlazeX should borrow WASI's capability discipline without claiming that a
current WASI Threads profile solves browser Worker creation, ERTS pthread
compatibility, DOM isolation, networking, storage, or whole-runtime teardown.
The first proof should pin Emscripten and treat proposal evolution as an input
to later portability work, not as a hidden dependency.

## Limits

These proposal repositories are living documents and can change phase or
design. They establish standards status and direction, not an ERTS build,
browser implementation parity, performance, or suitability for BlazeX.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [First-party ERTS/Wasm feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [2026-09-13 first-party ERTS WebAssembly runtime deep dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
