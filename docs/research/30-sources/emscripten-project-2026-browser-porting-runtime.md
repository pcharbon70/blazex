---
title: "Emscripten browser porting and runtime environment"
kind: source
created: "2026-09-13"
authors:
  - "Emscripten contributors"
published: null
citation_key: "emscripten-project-2026-browser-porting-runtime"
container: "Emscripten documentation"
edition: "6.0.10-git development documentation"
isbn: null
doi: null
url: "https://emscripten.org/docs/porting/index.html"
accessed: "2026-09-13"
tags:
  - browser
  - emscripten
  - pthreads
  - runtime
  - toolchain
  - webassembly
  - web-workers
aliases:
  - "Emscripten runtime-porting evidence"
---

# Emscripten browser porting and runtime environment

## Reference

Emscripten contributors. [“Porting”](https://emscripten.org/docs/porting/index.html),
[“About Emscripten”](https://emscripten.org/docs/introducing_emscripten/about_emscripten),
[“Emscripten Runtime
Environment”](https://emscripten.org/docs/porting/emscripten-runtime-environment.html),
[“Pthreads Support”](https://emscripten.org/docs/porting/pthreads.html), and
[“File System
Overview”](https://emscripten.org/docs/porting/files/file_systems_overview.html),
[“Networking”](https://emscripten.org/docs/porting/networking.html),
[“Asyncify”](https://emscripten.org/docs/porting/asyncify.html),
[“Dynamic Linking”](https://emscripten.org/docs/compiling/Dynamic-Linking.html),
[“Sanitizers”](https://emscripten.org/docs/debugging/Sanitizers.html), and the
[settings reference](https://emscripten.org/docs/tools_reference/settings_reference.html).
Development documentation labeled `6.0.10-git`, accessed 2026-09-13.

## Research question or contribution

Which compiler, JavaScript-runtime, threading, event-loop, memory, and file
system adaptations does Emscripten expose when moving a native language runtime
from a Unix-like process into a browser-hosted WebAssembly module?

## Method

The record reviews the official toolchain overview and the porting sections for
the runtime environment, pthreads, and virtual filesystems. It treats the
documentation as a catalog of mechanisms and browser constraints, not as proof
that an unmodified Erlang Runtime System builds or runs correctly.

## Findings

- Emscripten uses Clang and LLVM to compile C, C++, and other LLVM-compatible
  language runtimes to WebAssembly, then emits JavaScript that supplies host API
  support in browsers, Node.js, or another selected environment.
- A native infinite loop cannot retain control of the browser's UI/main agent
  without freezing page progress. Code in a Worker can retain control or block
  there, subject to Worker messaging, Atomics, watchdog, and lifecycle
  constraints. Main-agent work must return to the cooperative browser event
  loop, use an Emscripten-managed callback loop, or accept Asyncify's code-size
  and execution overhead where stack suspension is required.
- Browser code cannot directly use a host filesystem. Emscripten can preload
  files into the in-memory `MEMFS`; writes disappear on reload unless an
  explicit persistent backend such as `IDBFS` is mounted and synchronized.
- Browser pthreads use `SharedArrayBuffer`, Web Workers, and atomic operations.
  Threaded inputs and the final link must use `-pthread`, and a deployed page
  must satisfy the browser's cross-origin-isolation requirements.
- Emscripten cannot emit one binary that dynamically falls back from threaded
  to non-threaded operation. A product that supports both states needs distinct
  builds and a loader decision.
- `-sPROXY_TO_PTHREAD` can move application `main()` to a worker so that the
  browser UI thread remains responsive. Operations restricted to the browser
  main thread still require an explicit proxy boundary.
- Blocking waits on the browser main thread can busy-wait or deadlock when a
  worker needs that thread. Worker creation also returns through the browser
  event loop unless workers have been provisioned in advance. POSIX does not
  guarantee that a child has run when `pthread_create` returns, but native code
  can immediately join or wait for its effects; Emscripten's strict pool mode
  can turn exhaustion into a hard failure instead of risking deadlock.
- Emscripten's pthread layer does not reproduce every POSIX facility. Its
  documentation identifies unsupported process creation through `fork()`,
  general POSIX signal behavior, priority-related pthread operations, and other
  semantic differences that a runtime port must inventory.
- Shared threaded memory and memory growth interact with JavaScript heap views.
  External JavaScript that retains a view must account for replacement views
  after growth, and allocator selection trades code size and memory use against
  contention behavior.
- Browser networking is not direct POSIX TCP/UDP. Emscripten documents
  WebSocket-backed and proxy approaches with material compatibility and
  performance limits, while direct browser APIs require an explicit host
  bridge.
- Wasm dynamic linking requires coordinated main/side-module settings and can
  retain code that static dead-code elimination would otherwise remove. It is
  not equivalent to an unrestricted native dynamic loader.
- AddressSanitizer, UndefinedBehaviorSanitizer, and related diagnostics are
  available in supported Emscripten configurations, but each has coverage,
  memory, performance, and deployment tradeoffs; they are test tools rather
  than production containment.

## Relevance

For BlazeX, this is the principal first-party toolchain evidence for an ERTS
browser port. It suggests ERTS execution off the UI agent, a small auditable
JavaScript host, and preloaded read-only BEAM/OTP assets. Stage 1 must compare
the normal `PROXY_TO_PTHREAD` control-shell topology with an outer Dedicated
Worker that owns nested pthread Workers; the documentation does not prove those
topologies equivalent. If a future non-threaded ERTS
implementation is built, Emscripten would require it to be a separate artifact
rather than a dynamic fallback inside the threaded binary; no such fallback is
currently available or planned. The evidence also turns pthreads, blocking
calls, signals, filesystem access, memory growth, worker startup, and
main-thread proxying into explicit porting workstreams rather than assumptions.

## Limits

The documentation is generic and fast-moving. It does not build, test, size, or
benchmark ERTS, prove scheduler correctness, define a BEAM-module loader, or
show that the complete OTP library works in a browser. The observed
documentation label is a development version; any implementation must pin an
exact emsdk revision and retain compiler, linker, generated-JavaScript, browser,
and deployment evidence.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [First-party ERTS/Wasm feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [2026-09-13 first-party ERTS WebAssembly runtime deep dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
