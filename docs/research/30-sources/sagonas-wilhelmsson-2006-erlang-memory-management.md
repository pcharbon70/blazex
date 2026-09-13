---
title: "Efficient Memory Management for Concurrent Programs that Use Message Passing"
kind: source
created: "2026-09-13"
authors:
  - "Konstantinos Sagonas"
  - "Jesper Wilhelmsson"
published: 2006
citation_key: "sagonas-wilhelmsson-2006-erlang-memory-management"
container: "Science of Computer Programming"
edition: "Volume 62, Issue 2, pages 98-121"
isbn: null
doi: "10.1016/j.scico.2006.02.006"
url: "https://user.it.uu.se/~kostis/Papers/scp_mm.pdf"
accessed: "2026-09-13"
tags:
  - beam
  - erlang
  - garbage-collection
  - memory-management
  - message-passing
  - research-paper
  - runtime
aliases:
  - "Sagonas and Wilhelmsson Erlang memory-management paper"
---

# Efficient Memory Management for Concurrent Programs that Use Message Passing

## Reference

Konstantinos Sagonas and Jesper Wilhelmsson. “Efficient Memory Management for
Concurrent Programs that Use Message Passing.” *Science of Computer
Programming* 62, no. 2 (2006): 98–121.
[doi:10.1016/j.scico.2006.02.006](https://doi.org/10.1016/j.scico.2006.02.006).
[Author preprint](https://user.it.uu.se/~kostis/Papers/scp_mm.pdf).

## Research question or contribution

How can a concurrent functional-language runtime preserve short pauses and
efficient reclamation while many lightweight processes communicate using
copying message semantics?

## Method

The authors compare process-local, shared-heap, and hybrid memory
architectures; develop a hybrid organization with local heaps and a shared
message area; and describe generational incremental collection for that shared
area. They implemented the scheme in the Erlang/OTP system and evaluated two
synthetic workloads plus the concurrent `adhoc`, Yaws, and Mnesia applications
on a 2.4 GHz Intel Xeon Linux system.

## Findings

- Process-local heaps let a runtime collect one process independently without
  synchronizing every scheduler thread, and terminating a process can reclaim
  its local area directly.
- Copying a message between local heaps makes send cost proportional to message
  size, while a single shared heap reduces copying at the cost of global
  synchronization and longer collection pauses.
- The studied hybrid design allocates ordinary data locally and likely message
  data in a shared message area. Pointer-direction invariants prevent references
  from shared areas into local heaps, allowing independent local collection
  without a write barrier.
- The shared message area still has a large, cross-process root set. The paper
  therefore introduces a generational incremental collector that can be
  scheduled by time or by work quantum instead of collecting the whole area in
  one stop-the-world pause.
- The evaluation reports that the incremental collector adds little total
  runtime overhead for the tested workloads and that a time-based configuration
  can target short collection stages. Results vary by allocation pattern,
  reachable-message density, and scheduling quantum.
- Erlang's many small heap objects make per-object metadata and allocator/GC
  representation choices material to both memory footprint and execution cost.

## Relevance

This paper explains why an ERTS-to-WebAssembly effort cannot treat memory as a
generic C allocator detail. BlazeX should measure per-process heaps, message
copying, shared binaries, collection work, peak linear-memory use, and pause
distribution separately. Browser threads and shared Wasm memory must preserve
the runtime's pointer and ownership invariants rather than replacing them with
an unmeasured global heap.

## Limits

This is a 2006 study of historical Erlang/OTP runtime configurations, not a
description of current ERTS internals and not a WebAssembly experiment. Its
hardware, collector implementation, workloads, and reported pause times cannot
predict a modern browser port. Current OTP source inspection and new
Chrome/Firefox measurements remain necessary.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [First-party ERTS/Wasm feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [2026-09-13 first-party ERTS WebAssembly runtime deep dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
