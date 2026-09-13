---
title: "Erlang/OTP ERTS build, runtime, and source architecture"
kind: source
created: "2026-09-13"
authors:
  - "Erlang/OTP Project"
published: 2026
citation_key: "erlang-otp-project-2026-erts-build-runtime-source"
container: "Erlang/OTP 29.0.6 and ERTS 17.0.6 documentation and source"
edition: "OTP-29.0.6; ERTS 17.0.6; commit e07fd07837e5aa845657f5fa340637121e451d47"
isbn: null
doi: null
url: "https://github.com/erlang/otp/releases/tag/OTP-29.0.6"
accessed: "2026-09-13"
tags:
  - beam
  - build-systems
  - cross-compilation
  - erlang
  - erts
  - garbage-collection
  - native-integration
  - runtime
  - webassembly
aliases:
  - "ERTS browser-port source inventory"
---

# Erlang/OTP ERTS build, runtime, and source architecture

## Reference

Erlang/OTP Project. [Erlang/OTP 29.0.6 release
record](https://github.com/erlang/otp/releases/tag/OTP-29.0.6), released
2026-09-01, containing ERTS 17.0.6. Source tag `OTP-29.0.6`, commit
[`e07fd07837e5aa845657f5fa340637121e451d47`](https://github.com/erlang/otp/commit/e07fd07837e5aa845657f5fa340637121e451d47).
Accessed 2026-09-13.

The inspected build and runtime sources at that tag were:

- [building and installing Erlang/OTP](https://github.com/erlang/otp/blob/OTP-29.0.6/HOWTO/INSTALL.md)
  and the [cross-compilation guide](https://github.com/erlang/otp/blob/OTP-29.0.6/HOWTO/INSTALL-CROSS.md);
- ERTS [`configure.ac`](https://github.com/erlang/otp/blob/OTP-29.0.6/erts/configure.ac),
  shared [Autoconf macros](https://github.com/erlang/otp/blob/OTP-29.0.6/make/autoconf/otp.m4),
  and the emulator [Makefile template](https://github.com/erlang/otp/blob/OTP-29.0.6/erts/emulator/Makefile.in);
- the ERTS system interface inventory
  [`sys.h`](https://github.com/erlang/otp/blob/OTP-29.0.6/erts/emulator/beam/sys.h)
  and startup implementation
  [`erl_init.c`](https://github.com/erlang/otp/blob/OTP-29.0.6/erts/emulator/beam/erl_init.c);
- [BeamAsm, the BEAM JIT compiler](https://github.com/erlang/otp/blob/OTP-29.0.6/erts/emulator/internal_doc/BeamAsm.md),
  [Erlang garbage collector](https://www.erlang.org/doc/apps/erts/garbagecollection.html),
  [ERTS allocators](https://www.erlang.org/doc/apps/erts/erts_alloc.html), and
  [process-management optimizations](https://www.erlang.org/doc/apps/erts/processmanagementoptimizations.html);
- [ports](https://www.erlang.org/doc/system/ports.html),
  [linked-in port drivers](https://www.erlang.org/doc/apps/erts/erl_driver.html),
  and the [NIF interface](https://www.erlang.org/doc/apps/erts/erl_nif.html).

Corroborating official implementation articles were John Högberg's [“A brief
BEAM primer”](https://www.erlang.org/blog/a-brief-BEAM-primer/) (2020-10-20)
and [“A closer look at the
interpreter”](https://www.erlang.org/blog/a-closer-look-at-the-interpreter/)
(2020-10-27), Lukas Larsson's [“Interpreter
optimizations”](https://www.erlang.org/blog/interpreter-optimizations/)
(2018-06-11), Björn Gustavsson's [“The Road to the
JIT”](https://www.erlang.org/blog/the-road-to-the-jit/) (2020-12-01), and John
Högberg's [“A few notes on message
passing”](https://www.erlang.org/blog/message-passing/) (2021-03-19).

## Research question or contribution

What does the current upstream ERTS source actually require from its build and
operating-system environment, and where should a browser WebAssembly port
attach without replacing BEAM or OTP semantics?

## Method

The release record, documentation, build scripts, public runtime interfaces,
and representative source files were reviewed at one immutable upstream tag.
Statements below identify source facts first; browser-port consequences are
separated as synthesis.

## Findings

### Baseline and cross-compilation

- OTP 29.0.6 identifies ERTS 17.0.6 and is the reproducible baseline for this
  note. The tag matters because BEAM instructions, generated emulator code,
  runtime data structures, and application versions move together.
- The supported cross-build procedure distinguishes build and target hosts and
  requires a build-host Erlang system from the same release. The cross-build
  guide warns that using the wrong release can generate erroneous target code
  without an obvious build failure.
- The guide documents cross-compilation as tested primarily on selected
  Linux/GNU combinations. Its statement that most OTP applications can be
  cross-compiled is not a claim of browser WebAssembly compatibility.
- The reviewed source and documentation do not advertise a supported
  `wasm32`/Emscripten ERTS target. A new target therefore begins as a porting
  and qualification project, not as a documented configure invocation.

### Threading and scheduler substrate

- ERTS configuration invokes its `ethread` discovery and stops with an error
  when no thread library is found. The similarly named option that disables
  threads in `erl_interface` does not make the emulator threadless.
- Selecting one normal scheduler with `+S 1:1` reduces scheduler parallelism;
  it does not remove ERTS's underlying thread dependency or create a
  single-threaded browser build.
- `erl_init.c` initializes runtime subsystems, creates the initial process, and
  starts the scheduler machinery. Thread and scheduler integration is part of
  startup rather than an optional library layered on after boot.
- Native atomic operations are a material performance requirement for the SMP
  runtime. Upstream fallbacks exist for some platforms, but the build comments
  warn that serialized fallbacks can perform very poorly.

### Platform boundary and source organization

- The emulator makefiles combine common sources with operating-system-specific
  sources. ERTS currently has substantial `sys/common`, `sys/unix`, and
  `sys/win32` layers plus common and platform driver directories.
- `erts/emulator/beam/sys.h` inventories the porting boundary: program startup,
  executable and library loading, environment access, time, I/O and preload,
  polling/file descriptors, signals, and scheduler/thread services.
- That organization supports adding an explicit browser system layer and
  browser drivers. Scattering browser conditionals across otherwise common
  emulator code would make upstream rebases and security review harder.

### Interpreter, JIT, and code loading

- The portable execution route is the BEAM interpreter. Its C implementation
  is generated from instruction descriptions and uses loader-time
  specialization; supported native compilers can also use labels-as-values for
  direct-threaded dispatch.
- BeamAsm is an upstream native-code JIT for x86-64 and AArch64. It relies on
  architecture-specific assembly generation and executable memory, so it is
  not a WebAssembly code generator.
- ERTS exposes a build option to disable the JIT. An interpreter-first browser
  proof is therefore aligned with an upstream execution mode, although the
  generated C and computed-goto paths still require correctness and performance
  tests under the selected WebAssembly compiler.

### Memory and process isolation

- The documented collector is a per-process, generational, semi-space copying
  collector based on Cheney's algorithm, with a separate global large-object
  area. A process's heap and stack normally share a block and grow toward one
  another.
- Binaries larger than 64 bytes are normally reference-counted objects outside
  individual process heaps. Message delivery can share those binaries while
  ordinary message terms remain governed by process ownership and copying.
- ERTS has several allocator families and normally creates scheduler-specific
  allocator instances to reduce contention. Some allocator paths use memory
  mapping while `sys_alloc` remains a fallback; WebAssembly linear memory must
  be measured against both paths.
- The garbage-collector documentation describes a distinct strategy for
  32-bit address spaces instead of assuming the large literal region available
  on typical 64-bit systems. That makes a `wasm32` investigation plausible but
  does not prove that all allocator assumptions are already portable.

### Ports, drivers, and NIFs

- Ports are asynchronous, byte-oriented endpoints through which Erlang
  processes interact with external programs and linked-in drivers. The
  process-facing protocol can remain meaningful even when browser APIs replace
  operating-system files, sockets, and child processes.
- Linked-in drivers and NIFs execute inside the emulator. Official
  documentation warns that defective native code can crash or corrupt the
  entire runtime and that long callbacks must be divided or scheduled away
  from normal schedulers.
- Compiling ERTS and extensions into one WebAssembly linear memory preserves
  that shared failure domain. WebAssembly isolates the module from the browser
  host; it does not isolate a statically linked extension from ERTS itself.

## Relevance

The strongest first experiment is an interpreter-only, pinned OTP build with
one normal scheduler on a threaded WebAssembly runtime, with ERTS execution off
the UI agent. Stage 1 must compare Emscripten's `PROXY_TO_PTHREAD` control-shell
topology with an outer Dedicated Worker that creates nested pthread Workers.
Browser APIs should be surfaced by a small, statically linked port driver that
converts capability-checked asynchronous completions into ordinary ERTS
signals or messages.

That recommendation is cross-source synthesis, not an upstream support claim.
Emscripten's [pthreads documentation](https://emscripten.org/docs/porting/pthreads.html)
states that browser pthreads use Workers, `SharedArrayBuffer`, and atomics and
require cross-origin isolation headers. It also states that a single binary
cannot transparently select threaded and non-threaded execution at runtime.
Those constraints make the deployment header contract and a threaded-build
capability probe phase-zero requirements.

The platform layer should initially reject or omit unsupported ambient
facilities, including raw sockets, process creation, arbitrary host file paths,
signals, and dynamic native loading. Emscripten's [API limitation
guide](https://emscripten.org/docs/porting/guidelines/api_limitations.html) and
[networking guide](https://emscripten.org/docs/porting/networking.html) confirm
that browser code has a cooperative event loop, virtualized storage, and no
direct POSIX TCP/UDP surface.

## Limits

No ERTS WebAssembly configure, link, boot, or conformance run is recorded in
this source note. Source inspection identifies likely seams and blockers but
cannot determine the complete patch set. The absence of a documented upstream
target in the reviewed material is not proof that no unmerged or unpublished
experiment exists.

The interpreter, allocator, poller, atomics, and pthread assumptions need
small compile probes before a schedule is credible. Browser and Emscripten
behavior must also be pinned by version; the linked Emscripten pages are living
documentation and were accessed 2026-09-13.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [Can BlazeX build and own an ERTS WebAssembly runtime stack?](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [First-party ERTS WebAssembly runtime deep-dive journal](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
