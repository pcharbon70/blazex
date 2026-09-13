---
title: "Can BlazeX build and own an ERTS WebAssembly runtime stack?"
kind: inquiry
created: "2026-09-13"
status: open
tags:
  - beam
  - browser
  - elixir
  - erlang
  - erts
  - otp
  - research-program
  - security
  - webassembly
aliases:
  - "First-party ERTS-in-Wasm feasibility inquiry"
---

# Can BlazeX build and own an ERTS WebAssembly runtime stack?

## Why this matters

A browser build of official ERTS could let ordinary version-matched Elixir and
OTP BEAM modules execute locally while preserving the process, mailbox,
supervision, and failure semantics BlazeX wants. It could also replace a
runtime dependency with a BlazeX-owned build, host bridge, compatibility
profile, and security lifecycle.

That value is real only if the result remains recognizably upstream ERTS,
boots a useful OTP subset, does not freeze the UI thread, has a narrow browser
authority boundary, can be updated quickly for security fixes, and stays
within product budgets. A C compiler successfully emitting a `.wasm` file
would prove none of those properties.

This inquiry does not activate a new runtime package or revise the current
browser roadmap. It defines the evidence a later architecture decision would
need. Phoenix and Plug are independent server adapters outside the runtime-port
question. LiveView and LocalLiveView remain explicitly deferred.

## Operational question

Against one pinned Erlang/OTP, ERTS, Emscripten, browser, and Elixir matrix, can
BlazeX:

1. maintain a small reviewable patch stack over upstream ERTS rather than
   replacing BEAM and OTP semantics;
2. cross-build an interpreter-only `wasm32-unknown-emscripten` runtime and boot
   matching `kernel` and `stdlib` from an immutable embedded release;
3. satisfy contemporary ERTS thread, scheduler, atomics, timer, poller,
   allocator, loader, and teardown invariants through shared Wasm memory and a
   directly supervised Worker group, after comparing Emscripten's
   `PROXY_TO_PTHREAD` topology with an outer Dedicated Worker and nested pthread
   Workers;
4. keep the page UI thread responsive while ERTS sleeps, wakes, performs work,
   and waits for asynchronous browser operations;
5. enforce a deny-by-default import table and versioned, typed, bounded host
   protocol with explicit capabilities rather than ambient POSIX or JavaScript
   access;
6. prove OTP process, message, link, monitor, timer, ETS, application, and
   supervisor behavior against a matching native ERTS oracle;
7. package one public Elixir-authored BlazeX component through mount, semantic
   render, browser event, state transition, DOM commit, effects, and disposal
   without JavaScript-owned component logic;
8. terminate a wedged, corrupt, or over-budget runtime with no live owned
   Worker, MessagePort, timer, listener, request, renderer handle, pthread
   registry entry, or accepted stale completion, then show stable memory and
   Worker metrics across repeated cycles in Chrome and Firefox;
9. generate reproducible artifacts with runtime-enforced module/import/
   capability allowlists, conservative BEAM/native analysis, hashes, signed
   manifest, SBOM, provenance, and actionable diagnostics—with ordinary
   `apply`/behaviour dispatch confined to admitted modules and unresolved
   code/native-load or broker-capability edges rejected; and
10. meet explicitly approved payload, startup, memory, worker, event-to-paint,
    sustained-load, and cleanup-slope budgets?

## Working hypotheses

- **H1 — porting upstream is tractable:** the ERTS system layer and build
  seams are localized enough that an explicit browser platform layer can
  reach minimal OTP boot without a pervasive fork.
- **H2 — threads are mandatory:** current ERTS requires a thread library, so
  the least-invasive proof uses Emscripten pthreads, shared memory, a measured
  pre-created Worker pool, and cross-origin isolation even at `+S 1:1`; the
  exact control-shell/Worker topology remains an experiment.
- **H3 — the interpreter is sufficient:** disabling BeamAsm and running the
  portable BEAM interpreter can preserve semantics and meet an initial product
  budget; this must be measured rather than assumed.
- **H4 — capability adaptation beats POSIX emulation:** a small broker for the
  minimal clock/timer/entropy/log services required to boot, rendering, and
  later network/storage/crypto will be safer and more maintainable than
  pretending the browser is Unix.
- **H5 — OTP mostly travels as BEAM:** `kernel`, `stdlib`, and core behaviours
  can remain official matching modules, while OS-dependent applications and
  BIFs require explicit admission, adaptation, or exclusion.
- **H6 — WebAssembly is containment, not source memory safety:** the module
  boundary limits ambient browser access, but ERTS and statically linked C
  code remain one trusted, internally memory-unsafe failure domain.
- **H7 — host and OTP supervision are complementary:** an independently
  scheduled host supervisor with proven ownership and termination control must
  recover a wedged runtime because a supervisor process cannot recover its own
  corrupt VM. If a candidate topology forces termination ownership onto the UI
  agent, its starvation and availability gap must be recorded and tested.
- **H8 — compatibility is enforced and analyzed:** `.app` dependencies alone
  cannot define support; runtime module/import allowlists, conservative BEAM
  and native analysis, on-load behavior, traces, and declared capabilities all
  contribute. Ordinary dynamic BEAM dispatch is permitted only inside the
  admitted module set; unresolved code/native-load or broker-capability edges
  block admission.
- **H9 — lifecycle is the decisive browser risk:** boot can succeed while
  nested pthread Workers, requests, timers, or shared memory leak on repeated
  disposal; scaling and teardown slopes must gate adoption.

## Evidence already established

- [The synthesis](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
  identifies an Emscripten-pthread, interpreter-only runtime that keeps ERTS
  off the UI thread and compares two directly supervised Worker topologies,
  with an immutable OTP release and capability broker.
- [The BEAM Book](../30-sources/stenman-2025-beam-book.md) separates the BEAM
  abstract machine from the scheduler, process, memory, I/O, port, loader, and
  operational responsibilities of ERTS.
- [The OTP 29.0.6 source audit](../30-sources/erlang-otp-project-2026-erts-build-runtime-and-source.md)
  finds no documented browser target and confirms that the emulator requires a
  thread library; `+S 1:1` is not a threadless build.
- [The OTP boot and security record](../30-sources/erlang-otp-project-2026-otp-boot-security-and-compatibility.md)
  supports a BlazeX-pinned embedded release, official OTP supervision, a
  fixed module closure, and strict treatment of all external data.
- [Emscripten's browser-porting model](../30-sources/emscripten-project-2026-browser-porting-runtime.md)
  supplies the closest current C/libc/pthread/filesystem bridge but also makes
  Worker, asynchronous API, cross-origin isolation, and lifecycle constraints
  unavoidable.
- [WebAssembly standards](../30-sources/webassembly-standards-2026-browser-security-and-threads.md)
  make imports the host authority boundary and do not promise source-level C
  memory safety or freedom from hardware side channels.
- [WASI and WebAssembly threading status](../30-sources/webassembly-project-2026-wasi-and-threading-status.md)
  shows why current proposal work is useful direction but not a ready browser
  thread-spawning ABI for ERTS.
- The [binary-security](../30-sources/lehmann-kinder-pradel-2020-webassembly-binary-security.md)
  and [Spectre](../30-sources/narayan-et-al-2021-swivel.md) papers show why
  Wasm isolation must be paired with minimal imports, secret minimization,
  browser isolation, and defense in depth.
- The [Erlang memory-management paper](../30-sources/sagonas-wilhelmsson-2006-erlang-memory-management.md)
  explains the value and aggregate cost of process-local heaps, copying
  messages, and low-pause collection.
- [Scaling Reliably](../30-sources/trinder-et-al-2017-scaling-reliably-erlang.md)
  shows that scheduler balancing, timers, time, ETS, and shared-state
  contention require multidimensional workload and runtime-flag evidence.
- [Browsix](../30-sources/powers-vilk-berger-2017-browsix.md) demonstrates both
  the feasibility and substantial scope of reconstructing Unix abstractions in
  a browser, strengthening the case for a deliberately smaller contract.
- The [whole-application Wasm performance study](../30-sources/jangda-et-al-2019-webassembly-performance.md)
  shows why current ERTS workloads require direct browser measurement rather
  than inference from small native-code kernels.
- The [research journal](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
  records the pinned source inspection, that `emcc` was not found on `PATH`,
  and the absence of executable build evidence.

## Experiment program

### E0 — governed baseline and threat model

- Pin source, peeled commit, toolchain, bootstrap ERTS, browser versions, build
  image, and release inputs.
- Inventory startup dependencies and all imports expected before `init`.
- Approve protected assets, attackers, trust boundaries, non-goals, quotas,
  unsupported facilities, and patch/upstream policy.
- Fix manifest-bound startup arguments, environment, boot/config/code paths,
  signing trust roots, key lifecycle, release freshness, and rollback policy;
  prohibit page/query/storage and ambient Erlang flag overrides.
- Define and prove CSP delivery plus creator-compatible COEP on the page and
  every dedicated and nested pthread Worker response, recursively; verify
  `self.crossOriginIsolated` in every runtime Worker. Define the Worker
  executable-integrity mechanism; until a stronger bootstrap exists, record
  the serving origin, Worker responses, and cache path in the TCB.

**Pass evidence:** reproducible toolchain container, complete initial
dependency ledger, reviewed import/capability ABI, and no undeclared network
or mutable input in the build.

### E1 — minimal ERTS and OTP boot

- Compile the BEAM interpreter and required ERTS substrate to Wasm with
  pthreads and JIT disabled.
- Compare the `PROXY_TO_PTHREAD` control-shell topology with an outer Dedicated
  Worker/nested-pthread topology; keep ERTS off the UI thread, pre-size the
  pool from inventory, use strict pool-exhaustion failure, and register every
  Worker directly.
- Add only bounded monotonic/wall clock, timer/poll wakeup, CSPRNG seed, and
  bootstrap logging services, then boot the pinned `kernel`/`stdlib` release.
- Exercise processes, messages, timers, GC pressure, ETS, links, monitors,
  applications, and a supervisor restart.
- Stop and restart repeatedly while measuring every Worker, pthread registry,
  port, timer, listener, request, renderer handle, generation buffer, shared
  memory, and observable JS/browser memory category.

**Pass evidence:** equivalent observable traces against native ERTS; no live
owned handle or pthread registry entry after disposal; generation buffers are
unreachable; memory and Worker metrics settle within a predeclared envelope
with no positive slope over a predeclared cycle count and settling interval in
active Chrome and Firefox.

### E2 — bounded asynchronous broker

- Harden and generalize the minimal E1 services without broadening authority.
- Version and length-delimit all messages; include request, sequence, and
  runtime-generation identifiers.
- For Wasm-to-JS requests, validate overflow-safe bounds and snapshot into
  private JavaScript memory before semantic use; never retain a Wasm view across
  growth. For JS-to-Wasm responses, build privately, write only a
  producer-owned slot, atomically publish it immutable, then let the dedicated
  ERTS bridge thread copy it into an ERTS-owned logically exclusive buffer
  before releasing the slot.
- Never let an ERTS scheduler thread block on host completion; prove process and
  timer progress at `+S 1:1` while the bridge thread waits.
- Fuzz concurrent frame mutation, pointer/length pairs, frame decoders,
  request ordering, cancellation, timeouts, and late completions.

**Pass evidence:** malformed input cannot cross quotas or invoke an undeclared
operation; every completion from a disposed generation is rejected.

### E3 — deterministic release and compatibility closure

- Generate embedded boot/release artifacts, capability manifest, module
  allowlist, hashes, SBOM, provenance, and import/native-code report.
- Scan `.app` dependencies, BEAM calls, NIF/driver/on-load artifacts, and
  runtime traces.
- Enforce manifest name/hash checks at every BEAM-loading primitive and
  adversarially test `code:load_binary`, replacement, purge, `on_load`, and all
  alternate boot/config/code paths.
- Rebuild independently and compare outputs.

**Pass evidence:** no unexplained artifact variance and no undeclared module,
import, static native object, or host capability; no unresolved code/native-
load or broker-capability edge and no BEAM-loading path that bypasses the
signed manifest. Ordinary dynamic dispatch stays within admitted modules.

### E4 — OTP, Elixir, and BlazeX vertical slice

- Qualify the Tier 1 behaviour subset and pinned minimal Elixir core.
- Package the existing public BlazeX counter component.
- Compare native and Wasm lifecycle/render/event/effect/error/disposal traces.
- Drive the real DOM renderer in both active browsers.

**Pass evidence:** a real BEAM component owns state and completes the end-to-end
interaction while the host only brokers capabilities and rendering.

### E5 — adversarial resource and product trial

- Scale processes, mailboxes, binaries, timers, host requests, mounts, render
  batches, effects, crashes, and restarts independently and jointly.
- Test background suspension, network/storage denial, memory pressure,
  bfcache/navigation, and forced termination at every lifecycle stage.
- Measure payload, startup, memory, worker count, long tasks, latency
  distributions, and cleanup slopes.
- Exercise the approved quota matrix for Wasm/total memory, processes, ports,
  atoms, per-process heaps and shared binaries, mailboxes, ETS, timers, host
  requests, Workers/CPU, renderer state, and diagnostics; for each record the
  enforcing owner, mechanism, unit, breach action, and proof.

**Pass evidence:** approved budgets and monotonic cleanup invariants hold in
Chrome and Firefox; deployment headers work with the intended embedding and
authentication flows.

## Security blockers

Any of these blocks adoption regardless of demo quality:

- arbitrary JavaScript, DOM, network, storage, filesystem, or code-loading
  authority escapes the broker;
- the runtime accepts untrusted BEAM, any loader path bypasses manifest-bound
  name/hash checks, or any browser boundary accepts untrusted ETF;
- an imported function trusts a non-snapshotted shared-memory frame, unchecked
  overflow, identity, redirect hop, URL, or capability;
- runtime grants are claimed per OTP application even though one ERTS instance
  cannot authenticate the caller, or mutually untrusted code shares an
  instance;
- no enforceable quota matrix exists for memory, processes, atoms, mailboxes,
  ETS, timers, requests, Workers/CPU, renderer batches, or logging;
- the runtime leaves a live owned resource, accepts a stale completion, or its
  repeated-cycle memory/Worker metrics have a positive settled slope;
- an ERTS security update cannot be rebuilt and shipped inside the approved
  response window;
- build inputs, patches, or delivered modules cannot be accounted for; or
- client-held data is treated as server authorization or as confidential from
  the browser user/compromised origin, or a non-extractable key is treated as
  immune to oracle abuse.

## Resolution criteria

Resolve **positive** only after E0–E5 produce reproducible evidence and an ADR
accepts a precise support surface, ownership model, security-update duty, and
budget envelope.

Resolve **negative** if the minimum port requires broad POSIX emulation, a
pervasive unmergeable ERTS fork, UI-thread blocking, unbounded imports, unsafe
code loading, uncontrollable Worker groups, positive cleanup slopes, or
product-breaking deployment headers.

Pause if core boot succeeds but compatibility, performance, security staffing,
or long-term upstream maintenance cannot yet be justified. A pause must retain
the pinned artifacts and measurements so a later toolchain or browser change
can be evaluated without repeating the entire investigation.

## Present outcome

Open. Source evidence justifies a bounded cold-boot experiment and establishes
its security constraints. It does not yet prove an ERTS WebAssembly build,
minimal OTP boot, lifecycle cleanup, BlazeX component execution, acceptable
budgets, or sustainable ownership.
