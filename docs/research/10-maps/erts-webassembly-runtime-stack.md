---
title: "ERTS WebAssembly runtime stack"
kind: map
created: "2026-09-13"
tags:
  - beam
  - browser
  - elixir
  - erlang
  - erts
  - otp
  - runtime
  - security
  - webassembly
aliases:
  - "First-party ERTS-in-Wasm map"
---

# ERTS WebAssembly runtime stack

## Scope

This map routes through the evidence for a BlazeX-owned browser port of the
official Erlang/OTP runtime: ERTS internals, cross-building, browser threads
and operating-system gaps, minimal OTP boot, security, performance, and the
experiment needed before adoption.

It preserves four independent axes: ERTS is the runtime substrate; a directly
supervised browser Worker group keeps ERTS off the UI thread; the BlazeX DOM
adapter is the renderer; and any Phoenix or Plug connection is a separate
server adapter. LiveView and
LocalLiveView are deferred and are not part of this runtime investigation.

## Start here

- [First-party Erlang/OTP ERTS WebAssembly runtime
  stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
  is the complete synthesis, recommended architecture, security model, staged
  proof program, and current recommendation.
- [Can BlazeX build and own an ERTS WebAssembly runtime
  stack?](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
  turns the proposal into falsifiable boot, semantics, host-boundary,
  lifecycle, supply-chain, and product-budget criteria.
- [2026-09-13 first-party ERTS WebAssembly runtime deep
  dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
  records the pinned local source audit, commands, negative findings, evidence
  limits, and research method.

## Runtime internals and upstream baseline

- [The BEAM Book](../30-sources/stenman-2025-beam-book.md) explains the
  distinction between BEAM and ERTS plus process representation, instruction
  loading, reductions, scheduler loops, memory, garbage collection, I/O,
  ports, and native extensions.
- [Erlang/OTP ERTS build, runtime, and source
  architecture](../30-sources/erlang-otp-project-2026-erts-build-runtime-and-source.md)
  records the immutable OTP 29.0.6 / ERTS 17.0.6 audit, cross-build path,
  mandatory threading, interpreter/JIT split, platform seams, allocator
  assumptions, and native boundaries.
- [Efficient Memory Management for Concurrent Programs that Use Message
  Passing](../30-sources/sagonas-wilhelmsson-2006-erlang-memory-management.md)
  supplies the scientific basis for process-local heaps, copied messages, and
  low-pause collection as both a semantic asset and aggregate memory cost.
- [Scaling Reliably](../30-sources/trinder-et-al-2017-scaling-reliably-erlang.md)
  records how scheduler balancing, time, timers, and ETS evolved under measured
  contention, cautioning against casually simplifying current ERTS internals.

## OTP boot, compatibility, and authority

- [Erlang/OTP boot, security, and browser
  compatibility](../30-sources/erlang-otp-project-2026-otp-boot-security-and-compatibility.md)
  traces startup from ERTS through `init`, release scripts, `kernel`, `stdlib`,
  behaviours, code loading, and current untrusted-data guidance.
- The [main synthesis](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md#how-otp-fits-into-the-stack)
  explains why official version-matched OTP BEAM modules should execute inside
  ERTS-in-Wasm rather than be rewritten as JavaScript or C.
- The [compatibility experiment](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md#e3-deterministic-release-and-compatibility-closure)
  requires `.app`, BEAM import, native artifact, on-load, runtime trace, and
  declared-capability evidence rather than a dependency list alone.

## Browser platform and WebAssembly boundary

- [Emscripten browser porting, pthreads, and runtime
  services](../30-sources/emscripten-project-2026-browser-porting-runtime.md)
  covers Autoconf/C builds, pthread Workers and shared memory, asynchronous
  browser APIs, virtual filesystems, networking limits, dynamic linking, and
  sanitizers.
- [WebAssembly browser security, isolation, and threading
  standards](../30-sources/webassembly-standards-2026-browser-security-and-threads.md)
  establishes import-scoped authority, linear-memory isolation, Workers,
  `SharedArrayBuffer`, COOP/COEP, CSP, and the limits of those guarantees.
- [Browsix](../30-sources/powers-vilk-berger-2017-browsix.md) demonstrates that
  reconstructing Unix abstractions in a browser is possible but substantial,
  supporting a smaller capability-specific host contract for BlazeX.
- [WASI and WebAssembly threading proposal
  status](../30-sources/webassembly-project-2026-wasi-and-threading-status.md)
  distinguishes Core shared-memory atomics, legacy `wasi-threads`, evolving
  Shared-Everything Threads, and the browser embedder work none of them removes.

## Security trail

- [Everything Old Is New Again](../30-sources/lehmann-kinder-pradel-2020-webassembly-binary-security.md)
  shows how unsafe-language bugs can still corrupt state inside Wasm linear
  memory and turn a powerful host import into an origin-visible exploit.
- [Swivel](../30-sources/narayan-et-al-2021-swivel.md), a Lucet native-x86
  study rather than a browser/ERTS implementation, establishes the narrower
  point that sequential Wasm guarantees alone do not prove speculative
  confidentiality; browser-engine mitigations remain in the trusted base.
- The synthesis's [day-one security
  model](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md#security-from-day-one)
  combines immutable code, capability brokering, bounded protocols, quotas,
  secret minimization, Worker recovery, reproducible builds, and rapid ERTS
  patching.
- The inquiry's [security blockers](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md#security-blockers)
  prevent a visually successful demo from being mistaken for a safe runtime.

## Performance and lifecycle trail

- [Not So Fast](../30-sources/jangda-et-al-2019-webassembly-performance.md)
  supplies the methodological warning that whole native applications can
  expose costs hidden by small kernels and that browser, host-shim, compiler,
  and steady-state measurements must be separated.
- The synthesis's [required
  measurements](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md#required-measurements)
  cover artifact bytes, boot phases, memory, workers, scheduler behavior,
  event-to-paint latency, repeated teardown, and cleanup slopes.
- The inquiry's [minimal boot](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md#e1-minimal-erts-and-otp-boot)
  and [adversarial resource
  trial](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md#e5-adversarial-resource-and-product-trial)
  are the two decisive proof gates.

## Relationship to BlazeX architecture

- [Elixir WebAssembly components](elixir-webassembly-components.md) is the
  broader runtime and component research map. This map isolates the
  first-party ERTS candidate so older runtime evidence cannot be mistaken for
  proof of this implementation.
- [Host-neutral and native-renderer
  architecture](host-neutral-and-native-renderer-architecture.md) keeps ERTS,
  browser Workers, the DOM renderer, and future native renderers independent.
- [BlazeX repository ownership and dependency
  map](blazex-repository-ownership-and-dependency-map.md) remains the truth for
  current packages. No ERTS-in-Wasm package exists yet; any proposed runtime
  area needs a separate ADR and activation.
- [Browser host implementation
  milestones](../20-notes/browser-host-implementation-milestones.md) remains
  the current delivery program. This research defines a possible future
  roadmap amendment rather than rewriting completed or planned milestones.

## Current evidence boundary

The research establishes a plausible architecture and a bounded way to falsify
it. It does not establish a successful cross-build, OTP boot, browser
component, cleanup result, performance envelope, support matrix, or maintenance
commitment. The central inquiry remains open until those artifacts exist.
