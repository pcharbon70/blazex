---
title: "Browsix: Bridging the Gap Between Unix and the Browser"
kind: source
created: "2026-09-13"
authors:
  - "Bobby Powers"
  - "John Vilk"
  - "Emery D. Berger"
published: 2017
citation_key: "powers-vilk-berger-2017-browsix"
container: "Proceedings of the Twenty-Second International Conference on Architectural Support for Programming Languages and Operating Systems (ASPLOS '17)"
edition: "Pages 253-266"
isbn: "978-1-4503-4465-4"
doi: "10.1145/3037697.3037727"
url: "https://jvilk.com/assets/pdf/asplos17.pdf"
accessed: "2026-09-13"
tags:
  - browser
  - operating-systems
  - posix
  - research-paper
  - runtime
  - web-workers
aliases:
  - "Browsix browser operating-system paper"
---

# Browsix: Bridging the Gap Between Unix and the Browser

## Reference

Bobby Powers, John Vilk, and Emery D. Berger. “Browsix: Bridging the Gap
Between Unix and the Browser.” In *Proceedings of ASPLOS '17*, 253–266.
[doi:10.1145/3037697.3037727](https://doi.org/10.1145/3037697.3037727).
[Author PDF](https://jvilk.com/assets/pdf/asplos17.pdf).

## Research question or contribution

Can a browser-side compatibility layer supply enough Unix process and I/O
abstractions for existing applications and language runtimes to execute without
moving their service logic to a remote server or rewriting each application?

## Method

The authors built a JavaScript/TypeScript kernel, a system-call convention, and
runtime integrations for C/C++, Go, and Node.js. They evaluated the system with
an in-browser LaTeX editor, a disconnected client/server application, a POSIX
shell and utilities, and HBench-OS microbenchmarks in contemporary Chrome,
Firefox, and Safari builds.

## Findings

- Browsers omit process, pipe, signal, socket, and shared-filesystem contracts
  expected by many Unix applications; compiling application instructions alone
  does not supply those services.
- Browsix centralizes shared services in a JavaScript kernel on the main browser
  thread. Application processes run in Web Workers and reach those services
  through an explicit system-call boundary.
- The system offers asynchronous calls through message passing and a faster
  synchronous path through shared memory and atomics. The synchronous design
  reduces message copies but cannot reproduce every Unix process behavior.
- Runtime integration occurs at a small number of deliberate boundaries:
  process startup and exit, arguments and environment, filesystem calls,
  sockets, signals, and process creation. The case studies nevertheless require
  staged filesystem contents and browser-specific launch code.
- The LaTeX and disconnected client/server demonstrations show that a host shim
  can make substantial existing programs usable in a browser, but the paper's
  system-call microbenchmarks also expose large boundary overheads for small,
  frequent operations.
- Worker scheduling, copying, shared-memory availability, and whether a call is
  synchronous or asynchronous materially affect observable performance and
  semantics.

## Relevance

Browsix provides an architectural precedent, not an implementation dependency:
a first-party ERTS browser port needs an explicit host-services inventory and a
versioned boundary instead of scattering Unix emulation through VM code. It
also argues for batching and measuring high-frequency host calls, keeping the
runtime off the UI thread, and declaring which filesystem, networking, signal,
clock, entropy, and process facilities are real, emulated, rejected, or
unnecessary.

## Limits

The original Browsix implementation primarily compiled programs to JavaScript
and asm.js, predates current browser engines and deployment requirements, and
does not port or evaluate ERTS. Its broad Unix emulation surface is evidence
that a shim is possible, not evidence that BlazeX should reproduce a browser
kernel. Performance numbers and browser limitations must be remeasured against
the present WebAssembly and Worker platform.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [First-party ERTS/Wasm feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [2026-09-13 first-party ERTS WebAssembly runtime deep dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
