---
title: "The BEAM Book: Understanding the Erlang Runtime System"
kind: source
created: "2026-09-13"
authors:
  - "Erik Stenman"
  - "The BEAM Book contributors"
published: 2025
citation_key: "stenman-2025-beam-book"
container: null
edition: "First edition"
isbn: "978-91-531-4253-9"
doi: null
url: "https://blog.stenmans.org/theBeamBook/"
accessed: "2026-09-13"
tags:
  - beam
  - erlang
  - erts
  - garbage-collection
  - runtime
  - scheduling
aliases:
  - "The BEAM Book"
---

# The BEAM Book: Understanding the Erlang Runtime System

## Reference

Stenman, Erik, and contributors. [*The BEAM Book: Understanding the Erlang
Runtime System*](https://blog.stenmans.org/theBeamBook/). First edition, 2025.
ISBN 978-91-531-4253-9. The [source repository and contributor
history](https://github.com/happi/theBeamBook/) are published under CC BY 4.0.
Accessed 2026-09-13; the online edition reported a 2026-09-05 update.

## Research question or contribution

The book explains how BEAM code is represented, loaded, scheduled, executed,
and reclaimed inside ERTS. It is the primary conceptual guide for identifying
which runtime invariants a first-party browser WebAssembly port must preserve
and which operating-system services need a new host adaptation.

## Findings

- The book distinguishes BEAM, the abstract machine and executable instruction
  format, from ERTS, the complete runtime system that adds process scheduling,
  memory management, I/O, timers, networking, file access, signal handling, and
  multicore execution.
- Erlang processes are lightweight, isolated runtime entities rather than
  operating-system threads. Processes communicate with asynchronous signals
  and messages, and ERTS multiplexes them over scheduler threads.
- Scheduling is preemptive at the Erlang-process level but cooperative inside
  the C runtime. A process receives a reduction budget; exhausting that budget
  returns control to the scheduler. Scheduler run queues, load balancing, and
  work stealing provide multicore utilization.
- BEAM is a register machine. Its X registers carry arguments and temporary
  values, Y registers live in process stack frames, and the loader rewrites
  generic BEAM instructions into runtime-specific forms before execution.
- Each process owns its ordinary heap and stack. ERTS normally applies a
  generational copying collector to a process independently, while large
  reference-counted binaries can live outside individual process heaps.
  Per-scheduler allocator instances reduce contention in the broader memory
  subsystem.
- Message passing usually copies terms between process heaps. The ownership
  model is central to process isolation and local garbage collection, so a
  browser port must not replace it casually with shared mutable JavaScript
  objects.
- Ports are the runtime's common abstraction for communication with the
  external world. The book describes file-descriptor ports, external-program
  ports, and linked-in drivers; only the abstract port protocol is directly
  portable to a browser.
- NIFs and linked-in drivers execute inside the runtime's address space. Their
  ability to block or corrupt the emulator is an architectural property, not
  removed merely by compiling the combined program to WebAssembly.

## Relevance

The source supports treating the proposed browser runtime as an ERTS platform
port rather than as a JavaScript rewrite of Erlang process semantics. The
initial port should preserve BEAM loading, reductions, mailboxes, links,
monitors, timers, per-process collection, and the OTP-visible port abstraction.
Browser APIs should enter through a narrow asynchronous host boundary that
delivers normal runtime messages.

The scheduler discussion also prevents a common category error: one Erlang
process should not become one Web Worker. Web Workers, where required, are
implementation resources for ERTS scheduler threads; Erlang processes remain
runtime-managed data structures.

## Limits

The book is an explanatory internals text, not the normative specification for
one OTP release. Constants, data structures, generated instructions, lock
strategies, and scheduler details can change. Every implementation decision
must therefore be checked against the pinned Erlang/OTP tag used by the port.
The online edition can evolve after the 2025 print edition, so this note records
its access date and observed update date.

The book explains existing native ERTS; it does not claim that upstream ERTS
currently supports a browser WebAssembly target or quantify the work needed to
add one.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [Can BlazeX build and own an ERTS WebAssembly runtime stack?](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [First-party ERTS WebAssembly runtime deep-dive journal](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
