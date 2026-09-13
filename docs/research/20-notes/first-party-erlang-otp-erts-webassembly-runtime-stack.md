---
title: "First-party Erlang/OTP ERTS WebAssembly runtime stack"
kind: note
created: "2026-09-13"
maturity: developing
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
  - "First-party ERTS-in-Wasm architecture"
  - "Browser ERTS stack"
---

# First-party Erlang/OTP ERTS WebAssembly runtime stack

## Executive conclusion

BlazeX can responsibly investigate a browser build of the official
Erlang/OTP runtime, but this is a runtime-porting program rather than a normal
application feature. The technically credible route is to preserve upstream
ERTS and OTP semantics, compile the interpreter-based runtime to
`wasm32-unknown-emscripten`, boot a minimal immutable `kernel` and `stdlib`
release with all ERTS execution off the browser UI thread, and expose browser
services only through a small capability broker. It is not credible to describe
the work as merely "compiling Erlang to WebAssembly." ERTS depends on threads,
timers, polling,
and allocators, and contains native integrations and reachable or default paths
for memory mapping, files, dynamic loading, ports, signals, and other
operating-system conventions that a browser does not provide directly.[^1]

This route gives BlazeX ownership of the build, patch set, browser platform
layer, host protocol, packaging, security profile, conformance suite, and
release cadence. It should **not** mean rewriting the BEAM instruction set,
scheduler, garbage collector, or OTP behaviours from scratch. Reusing the
official Erlang/OTP source is both the shortest path to semantic fidelity and
the best way to keep security fixes obtainable from upstream.

The first decision gate is deliberately stronger than "the emulator
compiles." BlazeX should proceed only if a pinned ERTS and matching
`kernel`/`stdlib` release can:

1. boot reproducibly inside a directly supervised Worker group;
2. exercise processes, messages, timers, garbage collection, ETS, links,
   monitors, applications, and a supervisor restart;
3. sleep and wake without blocking the browser UI thread;
4. accept only a versioned, bounded, capability-checked host protocol;
5. be hard-terminated with no live Worker, MessagePort, timer, listener,
   request, renderer handle, or Emscripten pthread registry entry remaining,
   and with memory and Worker metrics returning to a predeclared stable
   envelope in both active Chrome and Firefox; and
6. remain inside measured payload, startup, memory, responsiveness, and
   teardown budgets that BlazeX explicitly sets before the experiment.

No ERTS WebAssembly build was produced during this research. The local work
was source inspection against Erlang/OTP 29.0.6; `emcc` was not found on the
research host's `PATH`, so no Emscripten configure or compile was attempted.
The result is therefore a research-backed candidate
architecture, not implementation evidence and not a support claim.

## Scope, terminology, and exclusions

This study concerns one precise arrangement:

- **runtime substrate:** the official ERTS implementation compiled into one
  WebAssembly module;
- **application format:** normal, version-matched BEAM modules loaded by that
  ERTS instance;
- **execution host:** a directly supervised browser Worker group that keeps all
  ERTS execution off the UI thread, plus an explicitly trusted JavaScript
  capability broker;
- **render backend:** a separate BlazeX DOM adapter receiving declarative
  semantic operations;
- **server adapter:** none is required for local execution; Phoenix and Plug
  are independent server-adapter axes outside this runtime port, while
  LiveView and LocalLiveView remain explicitly deferred; and
- **standards status:** the resulting ERTS binary is a Core WebAssembly module,
  not automatically a WebAssembly Component Model component.

An Elixir-authored BlazeX control would therefore compile to BEAM and execute
inside ERTS-in-Wasm. It would not ordinarily become an independent native Wasm
module. Multiple controls in the same trust domain should share one bounded
runtime instance rather than each ship a copy of ERTS.

Within this developing research, **ERTS-in-Wasm** is descriptive shorthand for
the official ERTS implementation compiled into a Core WebAssembly module. It
does not mean application AOT, Component Model packaging, or a new canonical
BlazeX product term. Canonical vocabulary and runtime adoption require their
own governed change.

The explicitly excluded Popcorn stack was not inspected, cited, or used as
technical evidence in this study. Existing BlazeX runtime decisions are not
silently changed by this note. Adopting this candidate would require a
separate architecture decision, implementation plan, and revised product
evidence.

## What must actually be ported

The BEAM Book usefully separates the BEAM abstract machine from the much
larger ERTS implementation. BEAM bytecode interpretation is only the visible
tip. ERTS also owns process representation, scheduling, reductions, message
queues, signals between processes, memory allocators, garbage collection,
timers, I/O polling, ports, native extension boundaries, code loading,
distribution, tracing, and operational machinery.[^2] A browser port must
either preserve, replace, or explicitly prohibit every operating-system
dependency reached by the supported release.

The browser mismatch is structural:

| ERTS expectation | Browser/Wasm reality | Initial decision |
| --- | --- | --- |
| Native threads and synchronization | Web Workers plus shared Wasm memory and atomics | Use Emscripten pthreads in a Worker pool; prove every startup and teardown path |
| Blocking scheduler and poll loops | The page UI thread must not block; browser APIs complete asynchronously | Keep ERTS off the UI thread and build an explicit poll/request-completion bridge |
| Signals, process creation, terminal, and OS commands | No general POSIX signals, `fork`, terminal, or child process API | Compile out or return deterministic `not_supported` results |
| Files and memory mapping | Linear memory and browser storage have different durability and synchronization semantics | Immutable release image plus bounded ephemeral scratch storage |
| TCP/UDP and arbitrary sockets | Browser exposes Fetch, WebSocket, and related origin-governed APIs | No socket illusion; expose allowlisted, typed network capabilities |
| Dynamic libraries, NIFs, and drivers | Dynamic Wasm linking is specialized and native faults still corrupt the VM instance | Ban dynamic native extensions; statically link only audited platform code |
| Native JIT code generation | BeamAsm emits supported machine code for x86-64 and AArch64, not Wasm | Disable JIT and use the BEAM interpreter |
| Unbounded host resources | Browser tabs share finite memory, CPU, workers, and responsiveness budgets | Enforce quotas in both ERTS and the host broker |

The practical goal is not POSIX completeness. It is a deliberately small
browser platform contract under which a useful, tested OTP subset behaves
correctly and unsupported facilities fail clearly.

## What the ERTS literature changes

The literature argues against treating this as a bytecode-interpreter port:

- The BEAM Book makes scheduling, reductions, process signals, memory,
  garbage collection, timers, I/O, ports, loading, and observability part of
  the runtime being preserved, not optional scaffolding around BEAM.[^2]
- Upstream implementation articles trace loader-time instruction
  specialization, interpreter dispatch, message delivery, and the later
  architecture-specific BeamAsm JIT. They support the interpreter as the
  browser starting point, but also identify dispatch and loader assumptions
  that must be measured under Wasm.[^6]
- Sagonas and Wilhelmsson explain why per-process heaps and mostly copied
  messages reduce synchronization and pause coupling, while shared binaries
  and global structures prevent those local properties from becoming an
  aggregate memory bound. Current OTP documentation confirms how the collector
  and off-heap binaries now behave.[^10]
- Trinder and collaborators show that scheduler balancing, time/timer paths,
  ETS, and shared-state contention interact as workloads scale. Removing or
  simplifying them for a browser build without multidimensional evidence would
  risk semantic drift as well as misleading performance results.[^17]

None of these sources proves browser feasibility. Together they define what a
faithful experiment must preserve and what it must measure.

## Recommended system architecture

The invariant is simpler than the final Worker diagram: ERTS must never execute
on the page's UI agent, and the BlazeX supervisor must directly account for and
terminate every Worker in the runtime generation. Stage 1 should compare two
candidate topologies built from Emscripten primitives rather than assume their
equivalence:

```text
Topology A — main-agent Emscripten control shell

Browser page and BlazeX DOM renderer
  |-- capability broker, watchdog, Worker registry
  +-- Emscripten JS control shell and pre-created pthread pool
         |-- application main / ERTS on a pthread Worker
         +-- additional ERTS pthread Workers

Topology B — outer dedicated runtime Worker

Browser page and BlazeX DOM renderer
  |-- capability broker, watchdog, Worker registry
  +-- Dedicated runtime Worker
         |-- Emscripten JS control shell and Wasm instance
         |-- application main / ERTS execution
         +-- nested Emscripten pthread Workers
```

Topology A uses `PROXY_TO_PTHREAD` as the reference Emscripten path: the
browser main agent retains the generated control shell and thread-creation
duties while the application `main()` and ERTS execute on a pthread Worker.
Topology B gives the outer supervisor a cleaner runtime-Worker boundary, but
nested-Worker creation, generated-loader assumptions, asset resolution, and
termination must be proven in every target browser and pinned toolchain. The
experiment should choose only after both topology and teardown evidence exist.

In either topology the shared runtime payload is the same: the upstream ERTS
interpreter compiled to WebAssembly, matching `kernel` and `stdlib` BEAM
modules, an optional tested Elixir subset, a statically linked browser platform
adapter, an immutable content-addressed release image, and bounded disposable
scratch storage.

The browser page and the ERTS instance are separate failure domains only to
the degree the browser Worker boundary provides. The host supervisor can
terminate a wedged or over-budget VM. OTP supervision inside that VM cannot
recover a corrupt or non-responsive ERTS instance, so both layers are needed.

### Artifact model

A reproducible build should produce at least:

- `erts.wasm`, with a checked import and export allowlist;
- a generated, pinned JavaScript loader and runtime-worker bootstrap;
- any pthread worker bootstrap assets required by the chosen Emscripten SDK;
- one immutable release pack containing `.boot`, `.app`, `.beam`, and approved
  `priv` assets;
- a machine-readable compatibility and capability manifest that also fixes the
  only accepted startup arguments, environment, boot image, configuration, and
  code paths;
- content hashes, Subresource Integrity metadata where applicable, an SBOM,
  toolchain and source provenance, and the complete patch ledger; and
- a human-readable report identifying omitted OTP applications and APIs.

The release and runtime must be version-locked as a BlazeX support policy. The
jointly tested upstream set is a matching ERTS, `kernel`, and `stdlib` release;
mixed releases and broader BEAM forward compatibility may work in some cases,
but remain outside this browser profile until explicitly tested. Arbitrary
ERTS, OTP, Elixir, or application-version combinations are not admitted.[^3]

## Porting strategy

### 1. Start from upstream ERTS, not a new VM

ERTS is portable C, but portable does not mean freestanding. A first-party
BlazeX implementation should maintain the smallest reviewable patch stack over
a pinned upstream release and contribute general fixes upstream where
possible. A clean-room BEAM implementation would inherit the full burden of
bytecode compatibility, garbage collection, process signals, scheduler
fairness, timers, code loading, exception semantics, BIFs, ETS, tracing, and
OTP compatibility before it reaches browser integration.

Research on ERTS scalability also shows that scheduler balancing, time,
timers, and ETS synchronization evolved together under measured contention;
they are not incidental server-only decoration that a browser fork can delete
without semantic and performance evidence.[^17]

The initial source baseline inspected here is Erlang/OTP 29.0.6, ERTS 17.0.6,
at Git commit `e07fd07837e5aa845657f5fa340637121e451d47`. This pin is a research
baseline only; the eventual implementation ADR must set an upgrade and
security-support policy.

### 2. Use Emscripten for the first browser target

Emscripten is the closest fit for ERTS's C, libc, Autoconf, pthread, filesystem,
and JavaScript-integration assumptions. The first target should be
`wasm32-unknown-emscripten`, using the ordinary ERTS cross-build flow and a
same-release native bootstrap system. The configuration should begin with:

- JIT disabled;
- kernel polling, dynamic loading, distribution, OS process launching, and
  unused native OTP applications excluded or replaced;
- pthread support enabled across the whole build;
- a finite initial and maximum Wasm memory, with growth policy measured rather
  than assumed;
- no shell, compiler, runtime evaluator, or interactive code path in the
  shipped release; and
- static linking only for the minimal browser platform adapter and approved
  native dependencies.

WASI's capability-oriented design is useful guidance, and a later non-browser
ERTS Wasm target may use WASI. It is not the best first browser ABI: browsers
do not natively provide the POSIX/WASI environment ERTS expects. The original
`wasi-threads` proposal is now a legacy Preview 1, Phase 1 path, while future
work has moved to the actively changing Shared-Everything Threads proposal;
neither is a portable browser thread-spawning contract.[^4]

### 3. Treat threads and cross-origin isolation as a feasibility gate

Contemporary upstream ERTS is not a thread-optional runtime. Its configuration
fails when no thread library is available. `+S 1:1` selects a single normal
scheduler; it does not remove dirty schedulers, auxiliary threads, poll
threads, thread progress, synchronization, or other runtime thread
assumptions. The inspected source creates scheduler and dirty scheduler
threads through ERTS's thread layer.

Emscripten implements pthreads with Web Workers sharing a
`SharedArrayBuffer`-backed `WebAssembly.Memory`. This entails all of the
following from the first proof:[^5]

- the application must be served cross-origin isolated with COOP and COEP;
- all relevant compilation and linking stages must use pthread support;
- the Worker pool must be sized from the measured maximum ERTS topology and
  pre-created because a newly constructed browser Worker cannot start until
  the browser event loop advances; POSIX does not promise that the child has
  already run when `pthread_create` returns, but ordinary native code can
  immediately join or wait for an effect and deadlock on this browser gap;
- qualification builds should use `-sPTHREAD_POOL_SIZE_STRICT=2` so pool
  exhaustion fails visibly instead of hanging, and should test exhaustion and
  exact Worker ownership;
- code on the browser UI thread must never perform a blocking wait;
- threaded and non-threaded builds would be separate artifacts rather than one
  runtime with a dynamic fallback; and
- runtime disposal must close all owned Workers, ports, timers, listeners,
  requests, renderer handles, and pthread registry entries; make all generation
  buffers unreachable; then show that memory and Worker metrics converge to a
  measured envelope with no positive slope over a predeclared number of
  boot/dispose cycles after a predeclared settling period.

A non-`SharedArrayBuffer` variant is possible only as a separate research
program: it would require a new single-thread ERTS thread backend or a deeper
cooperative scheduler refactor. It should not be presented as a configuration
toggle.

### 4. Keep the BEAM interpreter; disable BeamAsm

The ERTS JIT generates native instructions for its supported processor
architectures. It is not an application-to-WebAssembly compiler. The browser
baseline should use the BEAM interpreter and compile the runtime without the
JIT.[^6]

The interpreter source contains a `NO_JUMP_TABLE` path in addition to its
computed-goto dispatch. Exact Wasm function-signature and indirect-call rules
make this a concrete experiment: build both supported interpreter-dispatch
forms if possible, run semantic conformance first, then compare size and
throughput. Correctness must decide the baseline before performance.

### 5. Build a browser platform layer, not a POSIX disguise

The clean boundary is a small ERTS browser system layer plus an asynchronous
host broker. Each supported facility needs explicit semantics:

| Facility | Browser contract | Default |
| --- | --- | --- |
| Monotonic time | host-provided monotonic timestamps; define suspension and clock-jump behavior | minimal bounded form required for boot |
| Wall time | host timestamp, never authority for security decisions | minimal bounded form required for boot |
| Timers/poll wakeup | minimal wakeup bridge for Stage 1; hardened shared request/completion protocol in Stage 3 | required for boot and idle/wakeup |
| Randomness | initial seed from browser CSPRNG; later key operations through handles | seed required for boot profile |
| Console/logging | bootstrap diagnostics followed by structured levels, length/rate caps, and redaction | minimal bounded form required for boot |
| Release files | content-addressed read-only image | enabled |
| Scratch files | in-memory, namespaced, quota-bound, disposable | optional |
| Persistence | explicit IndexedDB or OPFS adapter with schema and quota errors | deferred |
| Network | typed Fetch operations with origin/method/header/size policy; WebSocket requires a separate security contract | deferred until core proof |
| DOM | declarative renderer protocol only; no generic DOM or JavaScript call | renderer adapter only |
| OS process, shell, terminal, raw socket | no browser equivalent | prohibited |

Browsix demonstrates that a substantial Unix-like environment can be built in
a browser, but it also illustrates how much machinery is required to preserve
processes, signals, sockets, pipes, and shared files.[^7] BlazeX should instead
implement only the capabilities its runtime profile declares. Emscripten's
socket emulation and proxies are incomplete or testing-oriented; they are a
poor production authority boundary.[^8]

### 6. Reconcile the non-returning scheduler with browser asynchrony

The BEAM interpreter's scheduler loop is designed as a long-running native
execution context. Browser Fetch, storage, and many platform operations are
asynchronous. Three approaches should be tested in increasing implementation
cost:

1. **Shared request/completion queues with a dedicated bridge thread.** Only a
   designated ERTS bridge/poller thread may wait on atomics while a broker
   Worker or main-thread code performs browser operations. An ERTS scheduler
   thread must never block on a host request; process and timer progress at
   `+S 1:1` while broker I/O is pending is a required proof. This most closely
   preserves ERTS expectations and is the recommended first production
   hypothesis.
2. **Asyncify at controlled wait boundaries.** This can accelerate a proof but
   rewrites call stacks, increases code size, and creates reentrancy and
   performance risks. It must not spread through arbitrary ERTS paths.[^9]
3. **Bounded run-slice API.** Refactor the emulator so a host call advances
   work and returns. This fits an event loop cleanly but changes the deepest
   scheduler assumptions and should be considered only if the threaded wait
   model fails.

Every request and response must carry a runtime-generation identifier. When a
Worker is disposed or restarted, late completions from its former generation
must be rejected atomically.

Shared-memory frames require a stronger rule than bounds checks. For Wasm-to-JS
requests, JavaScript must validate `offset <= memory_length` and
`length <= memory_length - offset` without overflow, then snapshot the bounded
frame into private JavaScript memory before semantic validation or use. It must
not retain or re-read a Wasm view, especially across memory growth. For
JS-to-Wasm responses, JavaScript builds the frame in private memory, writes a
slot only while it owns that slot, and atomically publishes the immutable
frame. The ERTS bridge thread claims the slot and copies it into an ERTS-owned,
logically exclusive buffer before releasing the slot; that buffer is still
physically inside the shared Wasm linear memory. Concurrent-mutation fuzzing
must exercise both directions and attempt to change every header, payload,
generation, and slot state between check and use.

### 7. Preserve ERTS memory semantics while imposing browser budgets

Erlang processes normally have isolated heaps and mailboxes; process-local
generational garbage collection reduces synchronization and pause coupling.
Large binaries and certain structures use shared/global areas. This model is a
valuable fit for UI isolation, but it does not create aggregate limits.[^10]

Wasm32 linear memory has a finite address space and browser-specific growth
costs. Memory growth can invalidate JavaScript views and may create visible
stalls. The runtime profile needs explicit ceilings for:

- initial and maximum Wasm pages;
- runtime-wide process count; per-component ownership only after a separate,
  non-forgeable ownership design is proven;
- total and per-process mailbox length and byte estimate;
- atom count and all string-to-atom paths;
- ETS table count and bytes;
- binary and release-asset sizes;
- timer and pending host-request counts;
- DOM/effect batch sizes; and
- log, trace, and crash-report volume.

The supervisor must terminate the entire Worker group on non-cooperative CPU or
memory exhaustion. ERTS's fairness and garbage collector protect well-behaved
processes from one another; they are not a browser resource sandbox.

### Quota enforcement design

`WebAssembly.Memory.maximum` bounds the aggregate address space available to
the Emscripten-side ERTS C allocations, including allocator arenas, process
heaps, reference-counted binaries, ETS storage, and C pthread stacks. It does
not impose logical limits on those categories, report committed host memory, or
bound JavaScript objects, DOM state, response bodies, browser-native Worker
stacks, engine code, or caches. The feasibility proof therefore needs this
owner-by-owner matrix; exact numeric limits are product inputs, not research
guesses.

| Resource | Enforcing owner and mechanism | Measured unit | Breach action | Required proof |
| --- | --- | --- | --- | --- |
| Wasm linear memory | linker-declared initial/maximum shared memory plus checked allocator failure paths | pages and committed bytes | fail allocation; terminate generation if invariants cannot be preserved | inspect module limits; grow/OOM stress; stable post-disposal envelope |
| Total browser/runtime memory | outer supervisor bounds each owned broker/renderer allocation and samples available Worker/browser metrics; no portable exact per-Worker-total API is assumed | exact owned-pool bytes, observable memory signals, and cycle slope | refuse allocation and terminate the generation; inability to cover an unbounded category blocks a hard-total-memory claim | independent Wasm, JS, response, DOM, and Worker stress with every observability gap recorded |
| Processes, ports, atoms, ETS tables | pinned and probed ERTS `+P`, `+Q`, `+t`, and `+e` guardrails; record effective values because limits can round and `+e` is partly obsolete | live counts | deterministic creation failure or generation termination | boundary tests against effective `system_info` values |
| Per-process heap and shared binaries | `+hmax`/`process_flag(max_heap_size, ...)` with shared off-heap binary accounting enabled where supported | words including configured off-heap contribution | kill offending process; escalate on repeated/system-owner breach | adversarial heap/binary tests and native-vs-Wasm trace |
| Mailboxes and aggregate binaries | runtime-wide admission control plus instrumented length/byte estimates; patch ERTS if a hard aggregate ceiling is required | messages and estimated bytes | reject/drop only by declared protocol or terminate generation | sender fan-in and off-heap-binary scaling slopes |
| ETS bytes and timers | runtime-wide governor and accounting; do not mistake the table-count flag for a byte limit | tables, estimated bytes, active timers | terminate generation on a hard breach | many-small and few-large tables; timer storms |
| Host requests, network/storage bytes, logs | broker counters before allocation and while streaming; bounded queues, concurrency, deadlines, and rate buckets | requests, bytes, records per interval | reject/cancel with typed error; terminate on protocol violation | slow/oversized response, cancellation, and backpressure tests |
| Workers and CPU responsiveness | fixed Worker registry, measured pool ceiling, strict exhaustion, and an independently scheduled host watchdog | Workers, heartbeat delay, long tasks, elapsed budget | terminate every Worker in the generation | runaway loop/allocation while the watchdog remains schedulable |
| Renderer state and effects | renderer-owned node/effect/listener registries and bounded atomic batches | nodes, listeners, effects, batch bytes | reject batch and dispose generation on invariant failure | malformed and scaling batches plus repeated teardown |

These ERTS flags are guardrails, not a complete sandbox, and the eventual
profile must pin and probe their exact behavior in the chosen OTP build.[^18]
Runtime-wide limits are the enforceable baseline. Per-component process, ETS,
timer, mailbox, or port quotas are only soft telemetry unless ERTS and the
component kernel propagate an unforgeable owner identity across every resource
creation and delegation path; claiming hard per-component isolation requires
that separate mechanism and adversarial proof.

## How OTP fits into the stack

### OTP is mostly BEAM code, not another Wasm port

OTP behaviours such as `supervisor`, `gen_server`, and `gen_statem` are
principally Erlang modules. They should remain the official, matching BEAM
modules and execute on ERTS-in-Wasm. Reimplementing them in JavaScript or C
would split semantics and make upstream compatibility harder. The minimum
embedded release starts `kernel` and `stdlib` from a generated `.boot` script;
other applications are admitted only after dependency and capability
analysis.[^3]

An application's `.app` dependency list is necessary but insufficient. The
build must also inspect BEAM imports, native artifacts and on-load functions,
privileged modules, runtime traces, and the declared host capabilities. A
module that starts successfully can still reach an unsupported BIF or port on
a later event.

Embedded boot does not itself prevent `code:load_binary/3`, module replacement,
purging, or other runtime loader paths. Every primitive that can admit BEAM
code must converge on a patched or interposed ERTS loader check that binds the
module name and digest to the signed release manifest. Startup boot/config/code
paths are immutable; runtime replacement, purge, `on_load`, and loader-error
paths must be denied or proven within the same rule. Removing convenience APIs
from the release is defense in depth, not the enforcement boundary.

### Proposed compatibility tiers

| Tier | Candidate surface | Admission rule |
| --- | --- | --- |
| 0 — boot substrate | ERTS, `kernel`, `stdlib`, applications, code server, processes, messages, timers, links, monitors, ETS, and the minimal bounded host clock/timer/entropy/log services boot reaches | required for the first gate; pinned-release conformance |
| 1 — resilient OTP core | supervisors, `gen_server`, `gen_statem`, application lifecycle, and the admitted OTP `logger` core | admit after native-vs-Wasm trace and fault tests |
| 2 — Elixir component runtime | pinned minimal Elixir core, including only needed Registry/Logger/Task/Agent facilities, plus BlazeX component, semantic tree, event, effect, and disposal contracts | admit through runtime-enforced allowlists plus conservative import/capability analysis; ordinary `apply` and behaviour dispatch are allowed only within the admitted module set, while unresolved code/native-load or broker-capability edges block admission |
| 3 — optional brokered services | network, persistence, and cryptographic operations beyond the Tier 0 boot primitives | one capability at a time with abuse tests and deterministic errors |
| Excluded initially | distribution/EPMD, raw sockets, OS commands, arbitrary ports, shell, compiler/eval, hot code loading, dynamic NIFs/drivers, terminal UI, ODBC, OS monitors, SSH, release-handler upgrades, desktop GUI apps | unavailable unless a later ADR and evidence explicitly admit it |

Unsupported calls must fail explicitly and predictably. Silent partial POSIX
emulation would make libraries appear compatible until a rare path fails.

### Elixir compatibility

Elixir itself is not a new native runtime layer: compiled Elixir modules are
BEAM modules and rely on ERTS, OTP, and version-specific standard libraries.
The first Elixir gate should therefore package the smallest pinned Elixir core
needed by one public BlazeX component. It should run the same component under
native ERTS and browser ERTS, comparing lifecycle, semantic render output,
events, state transitions, effects, errors, and disposal.

The existing public BlazeX counter vertical-slice fixture is a suitable first
payload because it already exercises a real component boundary. Passing it is
not broad Elixir compatibility; it is the first end-to-end proof after the
runtime and OTP substrate gates.

## Security from day one

### Security model

WebAssembly provides a valuable containment boundary: code has no ambient host
access and can reach only imported functions, while linear-memory accesses are
bounds checked by the engine. It does **not** turn ERTS's C implementation into
memory-safe code. Research on real C-to-Wasm binaries shows that classic
memory-corruption primitives can still corrupt data and control-relevant state
inside one Wasm instance, potentially changing what it sends through trusted
imports.[^11] Swivel demonstrated in Lucet's native x86 embedding—not in a
browser or ERTS—that sequential Wasm guarantees alone do not establish
speculative confidentiality. Browser-engine mitigations therefore remain in
the trusted base, and same-origin secrets must not be assumed safe merely
because ERTS lives in a Worker.[^12]

The trust model is consequently:

- ERTS, the static platform adapter, admitted BEAM modules, generated loader,
  broker, manifest verifier and trust root, browser engine, page bootstrap, and
  any same-origin script or service worker that can replace assets are trusted
  computing base;
- the compiler, linker, build image, dependencies, signing system, CDN, origin,
  caches, and update channel are supply-chain or delivery trust boundaries;
- all browser-delivered events, stored data, network data, URLs, server
  messages, and decoded terms are untrusted;
- application BEAM code is trusted but fallible, not sandboxed from other code
  inside the same ERTS instance;
- a compromised *allowed* dependency already executes with the runtime
  instance's authority, while an undeclared module must be rejected by the
  loader before execution;
- the browser user controls downloaded code and state, so client data is never
  server authority and confidentiality from the user or a compromised origin
  is not guaranteed; and
- OTP supervision is a resilience mechanism, not isolation for hostile code.

### Non-negotiable controls

| Threat | Day-one control |
| --- | --- |
| Tampered, stale, or rolled-back Wasm/BEAM | TLS; content-addressed immutable assets; manifest signatures; release sequence and expiry policy; rollback state; documented key distribution, rotation, revocation, and recovery; hashes/SRI; pinned source/toolchain; reproducible builds; SBOM and provenance. A signature resists origin/service-worker compromise only when both verifier and trust anchor arrive through a stronger independent channel; ordinary origin-delivered JavaScript can otherwise be replaced too. SRI protects only while the trusted page and expected hash remain intact |
| Undeclared BEAM code | immutable boot/config/code paths; manifest-bound module names and hashes enforced at every ERTS BEAM-loading primitive; deterministic denial of replacement, purge, `on_load`, and alternate-loader paths outside policy |
| Compromised allowed BEAM dependency | minimized release allowlist, review and vulnerability response; separate Worker+Wasm runtime instance for a different trust domain, because one ERTS instance does not isolate applications |
| XSS or generic interop abuse | locked asset origin and strict CSP; Trusted Types as limited defense in depth; no generated script/HTML channel and no generic `eval`, DOM, or "call JavaScript" import; explicitly govern service workers and every same-origin script |
| Capability escalation | deny-by-default import table; broker-enforced origin, operation, credential, method, header, size, concurrency, and rate policy |
| Malformed or racy bridge data | binary framing; version/type/sequence/generation checks; overflow-safe bounds; atomic slot ownership; private-JS request snapshots; producer-owned immutable response publication followed by an ERTS-owned logical copy; concurrent-mutation fuzzing in both directions |
| CPU, worker, atom, mailbox, ETS, binary, timer, or memory exhaustion | the explicit owner/mechanism/unit/action/proof quota matrix above; independently schedulable watchdog; finite Wasm maximum; bounded queues; backpressure; hard whole-generation termination |
| Untrusted Erlang External Term Format | no untrusted ETF at any browser boundary. `binary_to_term(..., [safe])` limits atom creation but is not structural or memory-safety validation. Any unavoidable untrusted ETF path requires a patched, pinned ERTS plus a separately isolated/prevalidated decoding design; length and shape checks alone are insufficient |
| C memory corruption | minimize native code; exact indirect-call signatures; native and Wasm sanitizer builds where supported; fuzz loader, bridge, parsers, and adapters; isolate and restart the Worker |
| Secret leakage | no embedded server credentials or client-held authorization; minimize valuable plaintext in shared memory; treat non-extractable WebCrypto keys as non-exportable handles, not as protection from use as an oracle; scope each handle to runtime generation, operation, purpose, origin, lifetime, and rate |
| Stale asynchronous work | request IDs, runtime generations, cancellation, deadlines, and rejection of every completion belonging to a disposed instance |
| Storage corruption or rollback | treat persisted bytes as untrusted; schema/version/signature checks; namespace and quota enforcement; explicit durability semantics |
| Diagnostic disclosure | structured allowlisted fields, redaction, rate/size limits, no raw memory or secret-bearing crash dump in production |

Official OTP guidance reinforces that loaded Erlang code is trusted and that
unsafe deserialization, unbounded atom creation, resource exhaustion, and
native extensions remain dangerous.[^13] A 2026 Erlang/OTP advisory showed
that a crafted external term could crash the entire VM even when the `safe`
decoder option was used before the affected releases were patched.[^14] The
lesson is not merely to update ERTS; it is to avoid making ETF the external
browser boundary and to plan rapid runtime security updates.

### Capability broker rules

The broker should expose a fixed operation vocabulary, not arbitrary
JavaScript calls. Grants attach to the whole signed release/runtime instance
and are checked again at use time. The broker cannot authenticate which OTP
application inside one ERTS instance originated a request; a distinct trust
domain therefore requires a separate Worker+Wasm instance unless a later
design adds unforgeable caller-bound delegation.

- **Fetch:** exact scheme/host/port and URL-pattern allowlists; allowed methods
  and headers; CORS mode required and `no-cors` prohibited; explicitly set
  `credentials: "omit"`; start with `redirect: "error"` so a
  307/308 cannot send an authorized body to an unchecked location. A later
  explicit redirect operation must authorize every hop and re-evaluate
  credentials and sensitive headers before following it. Apply streaming
  request/response byte caps, concurrency, rate, and deadline limits. Deny
  literal loopback, link-local, private-network, and local-device targets unless
  a distinct profile explicitly owns them. Browser JavaScript cannot reliably
  inspect DNS resolution or defeat rebinding, so stronger private-network
  exclusion requires a trusted resolver or external network boundary. Do not
  treat CORS as authorization or CSRF protection.
- **WebSocket:** keep deferred until it has a separate contract. The browser API
  has neither Fetch's CORS mode and arbitrary-header controls nor a
  `credentials: "omit"` switch and may attach ambient cookies. Admission needs
  a credentialless dedicated origin or equivalent isolation, strict Origin and
  application-token validation, a typed frame vocabulary, message and buffered
  byte caps, backpressure, rate limits, deadlines, and generation-bound close.
- **Persistence:** explicit namespace and schema; quota and eviction surfaced
  as real results; no claim of synchronous POSIX crash durability.
- **Cryptography:** entropy from the browser CSPRNG; private material as
  non-extractable WebCrypto handles where useful; explicit sign/verify or
  encrypt/decrypt operations rather than copying keys into Wasm memory. Handle
  authorization is generation-, operation-, purpose-, origin-, lifetime-, and
  rate-scoped because non-extractable keys can still be abused as an oracle.
- **Rendering:** semantic node and effect batches only. An explicit sink
  allowlist governs HTML tag and namespace, properties and attributes, URL
  schemes, navigation/form actions, CSS/style, SVG/MathML, `srcdoc`, event
  handler attributes, and HTML-parsing APIs; the initial profile should omit
  dangerous sinks rather than sanitize arbitrary markup. Validate identity,
  focus targets, batch size, and disposal state, and fuzz complete batches.
- **Logging:** structured codes and scalar fields; bounded and redacted before
  leaving the Worker.

### Browser delivery policy

The threaded baseline requires cross-origin isolation. A starting policy is:

```http
Content-Security-Policy:
  default-src 'none';
  script-src 'self' 'wasm-unsafe-eval';
  worker-src 'self';
  connect-src 'self' https://each-explicit-api.example;
  img-src 'self' data:;
  style-src 'self';
  object-src 'none';
  base-uri 'none';
  form-action 'none';
  frame-ancestors 'none';
  require-trusted-types-for 'script';
  trusted-types blazex
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Resource-Policy: same-origin
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
```

`'wasm-unsafe-eval'` permits Wasm compilation without granting general
JavaScript string evaluation in supporting browsers. This is a starting
profile, not a complete policy: `'self'` trusts every same-origin script-serving
endpoint, so production should use a locked asset origin plus hashes or nonces.
Use external same-origin Worker files; `worker-src 'self'` intentionally does
not authorize `blob:`. Send a restrictive generated CSP and a creator-compatible
COEP (`require-corp` in this profile) on every dedicated and nested pthread
Worker-script response, recursively. The page's CSP does not govern an external
Worker's global environment, and page-level isolation alone does not prove the
Worker chain. Verify `self.crossOriginIsolated` inside every runtime Worker.
Disable service workers for the feasibility profile, or treat their
installation and cache/update logic as TCB. Add HSTS where domain ownership
permits and publish an explicit least-privilege `Permissions-Policy`.

Startup must fail closed unless the page is a secure context,
`crossOriginIsolated` is true, `SharedArrayBuffer` and required Atomics exist,
and Worker loading follows an executable-integrity mechanism approved in Stage
0. The Worker constructor has no SRI parameter, and a content-addressed URL does
not protect against a malicious or compromised serving origin. Until a stronger
bootstrap is proven, that origin, each Worker response, and its cache path are
explicit members of the TCB. Trusted Types
protects only covered DOM sinks, so browser-specific negative tests must still
exercise attributes, URLs, styles, SVG/MathML, forms, navigation, and renderer
batches. `frame-ancestors 'none'` and `form-action 'none'` are profile choices;
an embedding or authentication requirement needs a separately reviewed policy.
COOP/COEP changes popup, OAuth, analytics, CDN, and third-party-resource
behavior, so compatibility is a product gate rather than a deployment
footnote.[^15]

## Build, verification, and upgrade discipline

### Reproducible build pipeline

1. Pin the Erlang/OTP tag and peeled commit, Emscripten SDK, LLVM/Binaryen,
   bootstrap ERTS, Elixir version, build image, and every input archive.
2. Generate Autoconf outputs in a controlled environment and cross-configure
   for `wasm32-unknown-emscripten`, recording every guessed cross value.
3. Apply a numbered patch ledger with upstream issue/reference, rationale,
   affected files, tests, and removal condition.
4. Compile ERTS and the approved static native subset with hardening and
   diagnostics appropriate to release or sanitizer builds.
5. Build matching `kernel`/`stdlib`, a generated embedded boot, the permitted
   Elixir/BlazeX set, and a read-only release image. Patch the lowest common
   BEAM-loader boundary to enforce manifest module names and hashes during boot
   and runtime loading, including replacement, purge, and `on_load` paths.
6. Generate the only accepted argv/environment from the signed manifest. Do
   not accept page URL, query, local storage, ambient `ERL_FLAGS`/`ERL_AFLAGS`/
   `ERL_ZFLAGS`/`ERL_LIBS`, or caller-provided overrides. Reject alternate
   `-boot`, `-config`, `-args_file`, `-loader`, `-pa`, `-pz`, `-path`,
   `-eval`, `-run`, `-s`, distribution, node-name, and cookie options before
   ERTS argument parsing can grant authority.
7. Inspect Wasm imports, exports, memory/table declarations, custom sections,
   native artifacts, BEAM imports, and on-load hooks. Combine conservative
   analysis with runtime-enforced fixed allowlists. Ordinary BEAM `apply` and
   behaviour callbacks may dispatch only within the admitted module set;
   unresolved code/native-load or broker-capability edges are admission
   blockers rather than a claim of complete static closure.
8. Emit hashes, SRI, signed manifest, SBOM, provenance, compatibility report,
   size report, and reproducibility comparison. Define manifest trust roots,
   key distribution/rotation/revocation, release sequence/expiry, rollback
   prevention, and compromised-origin/service-worker recovery.
9. Run native-vs-Wasm differential tests, fuzzers, and the active Chrome and
   Firefox suites before promotion.

Security releases need an explicit maximum response target and a mechanism to
rebuild every browser artifact when ERTS, Emscripten, LLVM, a static library,
or a broker dependency is patched. A first-party stack is a continuing
maintenance obligation, not a one-time binary.

### Test strategy

- **Native ERTS oracle:** same OTP/Elixir/application versions, deterministic
  seeds and fixtures, compare observable process/lifecycle/render traces.
- **ERTS subsystem conformance:** BEAM loading, exceptions, GC pressure,
  process creation, reductions, message ordering, links, monitors, timers,
  ETS, application boot, supervisor restarts, logging, and shutdown.
- **Platform adapter tests:** time discontinuity, background suspension,
  randomness, poll wakeups, filesystem quotas, unsupported facilities, broker
  cancellation, and runtime-generation rollover; at `+S 1:1`, processes and
  timers must continue progressing while the dedicated bridge thread waits for
  host I/O.
- **Parser and boundary fuzzing:** BEAM loader, release/manifest parser,
  overflow-safe pointer/length pairs, atomically owned bridge frames,
  concurrent shared-memory mutation, network and storage schemas, URLs, and
  complete renderer batches.
- **Authority-negative tests:** startup argument/environment injection,
  alternate boot/code paths, `code:load_binary`, replacement/purge/`on_load`,
  undeclared imports/modules, redirect hops, credential/header forwarding,
  `no-cors`, cryptographic-handle misuse, and renderer sink escapes.
- **Resource scaling:** increase processes, mailboxes, binaries, timers,
  workers, mounts, events, effects, and disposal cycles independently and in
  combination; record slopes as well as final counts so cleanup bugs are not
  hidden by a generous absolute threshold.
- **Adversarial lifecycle:** terminate during boot, blocked wait, GC, broker
  request, render commit, and disposal; assert no stale completion or live
  Worker/port/timer/listener/request/renderer handle survives the generation,
  the pthread registry empties, generation buffers become unreachable, and
  observed metrics settle without a positive repeated-cycle slope.
- **Browser matrix:** active Linux Chrome and Firefox first; all other browser,
  OS, mobile, and assistive-technology claims remain deferred until their own
  evidence exists.

The 2019 large-application performance study found materially larger
native-to-Wasm gaps than earlier small kernels, though contemporary engines
have evolved.[^16] Its durable lesson is methodological: BlazeX must measure
its own ERTS workload in current browsers and must not derive budgets from
microbenchmarks or historical headline numbers.

### Required measurements

- raw and Brotli-compressed bytes by runtime, loader, worker code, release,
  Elixir core, component bundle, and symbols;
- fetch, compile, instantiate, runtime initialization, OTP boot, first mount,
  first interaction, and warm restart timing;
- initial, steady, peak, post-GC, and post-disposal Wasm, JS, response, DOM, and
  observable Worker memory;
- worker and shared-memory count before boot, at steady state, and after
  termination;
- process spawn, local message, timer, ETS, and supervisor recovery behavior;
- event-to-state, state-to-semantic-batch, renderer commit, and event-to-paint
  latency distributions;
- UI main-thread blocking and long tasks;
- repeated mount/dispose, request/cancel, crash/restart, and route-load leak
  slopes; and
- build duration, reproducibility, import closure, vulnerability age, and
  patch-stack size.

Numeric budgets should be set from product requirements and baseline
measurements, not invented in this research note.

## Staged research and implementation program

### Stage 0 — threat model and governed baseline

- approve the trust zones, protected assets, attackers, non-goals, and browser
  authority boundary;
- pin upstream source/toolchain inputs and define patch/upstream/upgrade rules;
- inventory ERTS startup's threads, syscalls, memory, loader, file, timer, and
  I/O dependencies;
- define import/export, release-manifest, capability, and telemetry schemas;
- fix the argv/environment and loader enforcement point; and
- predeclare unsupported facilities plus every quota's owner, mechanism, unit,
  breach action, and proof.

**Gate:** reviewed threat model, dependency inventory, signed-off ABI, and
reproducible empty toolchain build.

### Stage 1 — interpreter-only cold boot

- add the browser system layer and Emscripten cross-build;
- disable JIT and excluded platform features;
- compare the `PROXY_TO_PTHREAD` control-shell topology with the outer
  Dedicated-Worker/nested-worker topology; keep ERTS off the UI thread and
  directly register every Worker;
- add only the bounded monotonic/wall clock, timer/poll wakeup, entropy seed,
  and bootstrap logging services needed to boot an immutable `kernel`/`stdlib`
  release at `+S 1:1` with its required runtime threads; and
- prove process/message/timer/GC/ETS/link/monitor/supervisor behavior and hard
  teardown.

**Gate:** repeatable Chrome and Firefox boot, idle/wakeup, crash, restart, and
operational teardown: no live owned resource or pthread registry entry, all
generation buffers unreachable, and memory/Worker metrics settled inside a
predeclared envelope with no positive cycle slope. The import allowlist remains
intact and the selected topology is recorded.

### Stage 2 — deterministic release and compatibility tooling

- build conservative BEAM/import/native/capability analysis plus fixed runtime
  allowlists and lower-boundary BEAM-loader enforcement;
- generate the embedded boot, release pack, manifest, SBOM, hashes, provenance,
  and unsupported-API report;
- prove byte-for-byte reproducibility or explain every permitted variance; and
- add native-vs-Wasm differential traces.

**Gate:** an independently rebuildable, pinned-release Tier 0 artifact with no
undeclared module, native object, import, or capability and no unresolved
code/native-load or broker-capability edge. Ordinary dynamic dispatch remains
confined to the admitted module set.

### Stage 3 — asynchronous host bridge

- harden the Stage 1 bootstrap services into bounded shared request/completion
  queues with atomic slot ownership: private-JS snapshots for Wasm-to-JS,
  producer-owned immutable publication for JS-to-Wasm, and an ERTS-owned
  logically exclusive copy before slot release;
- permit only the dedicated bridge/poller thread to block on host completion and
  prove scheduler/process/timer progress at `+S 1:1` while I/O is pending;
- generalize time, timer wakeup, randomness, structured logging, cancellation,
  deadlines, and runtime generations without broadening authority;
- fuzz overflow-safe frame bounds, concurrent mutation, pool exhaustion, and
  request/response ownership; and
- force termination at each asynchronous lifecycle point.

**Gate:** the broker cannot invoke undeclared capabilities, malformed input
cannot escape limits, and stale completions never reach a replacement runtime.

### Stage 4 — OTP and Elixir conformance slice

- qualify Tier 1 OTP behaviours;
- admit the minimal pinned Elixir core;
- package the existing public BlazeX counter component; and
- compare native and Wasm mount, semantic render, interaction, state, effect,
  fault, and disposal traces.

**Gate:** one real Elixir-authored BlazeX component completes the full browser
vertical slice in Chrome and Firefox without JavaScript-owned component state.

### Stage 5 — renderer and lifecycle integration

- connect only the versioned semantic tree/event/effect protocol to the DOM
  renderer;
- add an explicit DOM sink allowlist, focus, selection, accessibility, resource
  ownership, backpressure, and atomic stale-update rejection;
- scale multiple components in one shared runtime; and
- prove page/runtime teardown and watchdog recovery.

**Gate:** functional, accessibility, resource, scaling, and disposal evidence
passes without broadening the ERTS import surface.

### Stage 6 — optional browser capabilities

- add network, persistence, and cryptographic operations one at a time;
- require explicit manifest grants, broker policy, adversarial tests, and
  deterministic unsupported behavior for each; and
- keep authorization and domain invariants server-side.

**Gate:** each capability has an isolated security review and can be removed
without changing the component kernel.

### Stage 7 — hardening, performance, and maintenance proof

- complete sanitizer, fuzz, supply-chain, CSP/Trusted Types, cross-origin
  isolation, failure-injection, and browser-compatibility suites;
- establish and meet measured product budgets;
- rehearse an upstream ERTS security update and toolchain update; and
- reduce or formally own every remaining patch.

**Gate:** an architecture decision has enough evidence to accept, constrain,
pause, or reject the first-party stack. Passing a demo alone is insufficient.

## Repository ownership if adopted

No present package should be relabeled as owning this runtime. A later ADR
could introduce a dedicated logical toolchain/runtime owner for upstream pins,
patches, platform C code, Emscripten configuration, loader, Worker bootstrap,
conformance, and runtime artifacts. A path such as `runtime/erts_wasm` is only
illustrative here; the ADR and repository-ownership review must choose the
actual package name and location. A separate browser profile adapter would
compose that runtime with the existing BlazeX DOM renderer and capability
host.

The existing build package should consume a declared runtime build contract
and continue to own reachability, release assembly, manifests,
reproducibility, and diagnostics. It should not absorb ERTS implementation
behavior. The renderer-neutral component kernel must remain free of browser,
Emscripten, DOM, and server-framework types.

## Alternatives considered

### Rewrite the BEAM and OTP stack

Rejected as the default interpretation of "our own stack." It maximizes
semantic and security risk while discarding upstream fixes. BlazeX ownership
is better expressed through the platform port, packaging, compatibility
profile, bridge, and evidence program.

### Compile each Elixir component directly to native Wasm

This is a different compilation model. It may suit restricted kernels later,
but it does not preserve general ERTS process, mailbox, code-loading, or OTP
semantics and cannot substitute for the runtime investigated here.

### Put ERTS on the browser UI thread

Rejected. A scheduler or blocking wait can freeze rendering and input, and the
page loses a clean hard-termination boundary.

### Emulate a complete Unix host

Rejected for the first profile. It increases trusted code, bundle size, and
semantic ambiguity while granting application code capabilities the product
does not need.

### Use browser WASI as the initial ABI

Deferred. Capability design should remain adaptable to future WASI, but the
current browser, thread, networking, storage, and DOM surfaces still require a
browser-specific embedder.

### Begin with a threadless build

Rejected as a simple configuration. Current ERTS requires a thread library.
Creating a cooperative single-thread fork remains an optional high-risk
research branch only if cross-origin isolation proves unacceptable.

## Principal unresolved questions

1. Can Emscripten pthreads satisfy every ERTS startup, TLS, futex, thread
   progress, dirty scheduler, auxiliary, poll, and shutdown invariant?
2. What is the exact minimum worker/thread topology at `+S 1:1`, and can every
   Worker be directly closed after forced termination with empty pthread
   registries and stable post-settling resource slopes?
3. Which `mmap`, page-protection, signal, poll, crash-dump, terminal, dynamic
   loader, and file assumptions are reached before minimal OTP boot?
4. Does ERTS's 32-bit term/tag representation behave correctly and perform
   acceptably under Wasm32 for the target workloads?
5. Which computed-goto, function-pointer cast, setjmp/longjmp, atomic, or
   alignment patterns need source changes for WebAssembly validation?
6. Where can scheduler I/O waits integrate with the host without changing
   reductions, timer ordering, process signals, or garbage-collector
   invariants?
7. How should browser suspension, background throttling, clock adjustment,
   and bfcache interact with Erlang monotonic time and timeout semantics?
8. Which ordinary `kernel`, `stdlib`, Elixir, and Logger paths implicitly need
   files, terminals, sockets, dynamic code, or native libraries?
9. Can useful cryptographic APIs map to asynchronous WebCrypto without
   pretending that their existing synchronous/native semantics are preserved?
10. Is mandatory cross-origin isolation compatible with the applications,
    embeddings, authentication popups, analytics, and third-party assets
    BlazeX intends to support?
11. What precise OTP and Elixir API surface constitutes a support promise?
12. What payload, startup, memory, worker, latency, and sustained-resource
    budgets make the runtime commercially useful?
13. Can BlazeX carry the security-update and upstream-rebase obligation for
    ERTS plus the browser toolchain over multiple OTP releases?

## Recommendation

Authorize only Stages 0 and 1 as a bounded feasibility program after a formal
ADR. Use upstream Erlang/OTP, Emscripten pthreads, an interpreter-only embedded
release, ERTS execution off the UI thread in a directly supervised Worker
group, a deny-by-default capability broker, and strict browser delivery
headers. Make operational teardown, runtime-enforced import/module allowlists,
resource limits, and native-vs-Wasm semantics first-class acceptance evidence.

If the cold-boot proof requires broad POSIX emulation, cannot close and account
for its whole Worker group without positive resource slopes, cannot preserve
the OTP Tier 0 semantics, or requires an unbounded import surface, stop and
reassess. If it passes, proceed through the bridge and compatibility stages
before integrating BlazeX controls. This order
keeps a compelling demo from concealing an unsafe or unmaintainable runtime.

## Related research

- [ERTS WebAssembly runtime-stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [First-party ERTS-in-Wasm inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [Research journal](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
- [The BEAM Book source note](../30-sources/stenman-2025-beam-book.md)
- [Erlang/OTP ERTS build and source note](../30-sources/erlang-otp-project-2026-erts-build-runtime-and-source.md)
- [OTP boot, security, and compatibility note](../30-sources/erlang-otp-project-2026-otp-boot-security-and-compatibility.md)
- [Emscripten browser runtime note](../30-sources/emscripten-project-2026-browser-porting-runtime.md)
- [WebAssembly standards and browser security note](../30-sources/webassembly-standards-2026-browser-security-and-threads.md)
- [WASI and WebAssembly threading status note](../30-sources/webassembly-project-2026-wasi-and-threading-status.md)
- [Erlang process-memory paper](../30-sources/sagonas-wilhelmsson-2006-erlang-memory-management.md)
- [Browsix paper](../30-sources/powers-vilk-berger-2017-browsix.md)
- [WebAssembly performance paper](../30-sources/jangda-et-al-2019-webassembly-performance.md)
- [Binary-security paper](../30-sources/lehmann-kinder-pradel-2020-webassembly-binary-security.md)
- [Swivel paper](../30-sources/narayan-et-al-2021-swivel.md)
- [Scaling-reliably paper](../30-sources/trinder-et-al-2017-scaling-reliably-erlang.md)

## Sources

[^1]: Erlang/OTP project, [ERTS documentation](https://www.erlang.org/doc/apps/erts/) and [Erlang/OTP source](https://github.com/erlang/otp/tree/OTP-29.0.6/erts), accessed 2026-09-13.
[^2]: Erik Stenman and contributors, [*The BEAM Book: Understanding the Erlang Runtime System*](https://blog.stenmans.org/theBeamBook/), first edition, 2025.
[^3]: Erlang/OTP project, [System Principles](https://www.erlang.org/doc/system/system_principles.html), [Release Structure](https://www.erlang.org/doc/system/release_structure.html), and [OTP Design Principles](https://www.erlang.org/doc/system/design_principles.html), OTP 29.0.6, accessed 2026-09-13.
[^4]: WebAssembly/WASI project, [WASI proposals](https://github.com/WebAssembly/WASI/blob/main/docs/Proposals.md), [legacy `wasi-threads`](https://github.com/WebAssembly/wasi-threads/blob/main/README.md), [Shared-Everything Threads](https://github.com/WebAssembly/shared-everything-threads/blob/main/proposals/shared-everything-threads/Overview.md), and [Core WebAssembly Threads](https://github.com/WebAssembly/threads/blob/main/proposals/threads/Overview.md), accessed 2026-09-13.
[^5]: Emscripten project, [Pthreads support](https://emscripten.org/docs/porting/pthreads.html) and [Wasm Workers](https://emscripten.org/docs/api_reference/wasm_workers.html), accessed 2026-09-13.
[^6]: Erlang/OTP project, [A brief BEAM primer](https://www.erlang.org/blog/a-brief-BEAM-primer/), [A closer look at the interpreter](https://www.erlang.org/blog/a-closer-look-at-the-interpreter/), [Interpreter optimizations](https://www.erlang.org/blog/interpreter-optimizations/), [A few notes on message passing](https://www.erlang.org/blog/message-passing/), [The Road to the JIT](https://www.erlang.org/blog/the-road-to-the-jit/), and [BeamAsm source documentation](https://github.com/erlang/otp/blob/OTP-29.0.6/erts/emulator/internal_doc/BeamAsm.md), accessed 2026-09-13.
[^7]: Bobby Powers, John Vilk, and Emery D. Berger, [“Browsix: Bridging the Gap Between Unix and the Browser”](https://arxiv.org/abs/1611.07862), ASPLOS 2017, doi:10.1145/3037697.3037727.
[^8]: Emscripten project, [Networking](https://emscripten.org/docs/porting/networking.html), accessed 2026-09-13.
[^9]: Emscripten project, [Asyncify](https://emscripten.org/docs/porting/asyncify.html), accessed 2026-09-13.
[^10]: Erlang/OTP project, [Erlang Garbage Collector](https://www.erlang.org/doc/apps/erts/garbagecollection.html), OTP 29, accessed 2026-09-13; and Konstantinos Sagonas and Jesper Wilhelmsson, [“Efficient Memory Management for Concurrent Programs that Use Message Passing”](https://user.it.uu.se/~kostis/Papers/scp_mm.pdf), *Science of Computer Programming* 62(2), 2006, doi:10.1016/j.scico.2006.02.006. The current documentation establishes present behavior; the paper explains the historical design and tradeoffs.
[^11]: Daniel Lehmann, Johannes Kinder, and Michael Pradel, [“Everything Old Is New Again: Binary Security of WebAssembly”](https://www.usenix.org/conference/usenixsecurity20/presentation/lehmann), 29th USENIX Security Symposium, 2020.
[^12]: Shravan Narayan et al., [“Swivel: Hardening WebAssembly against Spectre”](https://www.usenix.org/conference/usenixsecurity21/presentation/narayan), 30th USENIX Security Symposium, 2021.
[^13]: Erlang/OTP project, [Secure Coding and Handling of Untrusted Data](https://www.erlang.org/docs/29/system/secure_coding.html), [NIF documentation](https://www.erlang.org/doc/apps/erts/erl_nif.html), and [Common Caveats](https://www.erlang.org/doc/system/commoncaveats.html), accessed 2026-09-13.
[^14]: Erlang/OTP project, [GHSA-54pw-5645-jh86: Crafted External Term Format input can crash the emulator](https://github.com/erlang/otp/security/advisories/GHSA-54pw-5645-jh86), published 2026, accessed 2026-09-13.
[^15]: W3C, WHATWG, and MDN, [Content Security Policy Level 3](https://www.w3.org/TR/CSP/), [Web workers](https://html.spec.whatwg.org/multipage/workers.html), [Cross-Origin-Opener-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cross-Origin-Opener-Policy), and [Cross-Origin-Embedder-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cross-Origin-Embedder-Policy), accessed 2026-09-13.
[^16]: Abhinav Jangda, Bobby Powers, Emery D. Berger, and Arjun Guha, [“Not So Fast: Analyzing the Performance of WebAssembly vs. Native Code”](https://www.usenix.org/conference/atc19/presentation/jangda), 2019 USENIX Annual Technical Conference, 2019.
[^17]: Phil Trinder et al., [“Scaling Reliably: Improving the Scalability of the Erlang Distributed Actor Platform”](https://arxiv.org/abs/1704.07234), *ACM Transactions on Programming Languages and Systems* 39(4), 2017, doi:10.1145/3107937.
[^18]: Erlang/OTP project, [`erl` runtime-system flags](https://www.erlang.org/doc/apps/erts/erl_cmd.html), [`process_flag/2` and maximum heap behavior](https://www.erlang.org/doc/apps/erts/erlang.html), and [System Limits](https://www.erlang.org/doc/system/system_limits.html), OTP 29, accessed 2026-09-13.
