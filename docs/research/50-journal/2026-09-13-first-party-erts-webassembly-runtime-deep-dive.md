---
title: "2026-09-13 first-party ERTS WebAssembly runtime deep dive"
kind: journal
created: "2026-09-13"
tags:
  - beam
  - browser
  - deep-research
  - erlang
  - erts
  - otp
  - security
  - source-inspection
  - webassembly
aliases:
  - "First-party ERTS-in-Wasm research session"
---

# 2026-09-13 first-party ERTS WebAssembly runtime deep dive

## Objective and scope

This session investigated how BlazeX could own a browser port of official
Erlang/OTP ERTS, how matching OTP and Elixir code would execute on that
runtime, and which security controls must exist from the first proof.

The work treated runtime substrate, browser Worker host, BlazeX DOM renderer,
browser capabilities, and optional server adapters as separate axes. Phoenix,
Plug, LiveView, and LocalLiveView were not used to define the runtime. The
explicitly excluded Popcorn stack was not inspected, cited, or used as
evidence.

## Environment

- Research date: 2026-09-13
- Workspace: `/home/ducky/code/blazex`
- Host: Linux development environment
- Active future browser evidence matrix: Linux Chrome and Firefox
- Upstream source checkout: `/tmp/blazex-erts-research-otp-29.0.6`
- Erlang/OTP tag: `OTP-29.0.6`
- Peeled Git commit: `e07fd07837e5aa845657f5fa340637121e451d47`
- ERTS version: 17.0.6
- Emscripten compiler: `emcc` not found on `PATH`; SDK installation elsewhere
  on the host was not established
- Executable ERTS/Wasm build, browser boot, benchmark, or conformance run: none

The source checkout is temporary research material and is not a project
artifact. The immutable upstream URLs in the source notes are the durable
references.

## Research method

The deep dive used four independent evidence lanes followed by a contradiction
and evidence-limit pass:

1. ERTS internals, build, interpreter, scheduler, memory, I/O, and native
   extension boundaries;
2. OTP boot, application/release structure, behaviours, version compatibility,
   code loading, and secure-coding guidance;
3. Emscripten, Core Wasm, Workers, shared memory, browser security headers,
   filesystem/networking, and WASI status; and
4. scientific and systems papers on Erlang process memory, browser Unix
   adaptation, whole-application Wasm performance, in-module binary security,
   and speculative-execution isolation.

The evidence hierarchy prioritized tagged Erlang/OTP source, official project
documentation, standards, peer-reviewed papers, and implementation-author
articles. Search summaries were discovery aids, not detailed evidence.

## Local source inspection

### Pin confirmation

Commands:

```sh
git -C /tmp/blazex-erts-research-otp-29.0.6 rev-parse HEAD
git -C /tmp/blazex-erts-research-otp-29.0.6 describe --tags --exact-match HEAD
```

Observed:

```text
e07fd07837e5aa845657f5fa340637121e451d47
OTP-29.0.6
```

### Target-triplet parsing

Command:

```sh
/tmp/blazex-erts-research-otp-29.0.6/erts/autoconf/config.sub wasm32-unknown-emscripten
```

Observed:

```text
wasm32-unknown-emscripten
```

This proves only that the bundled GNU target canonicalizer recognizes the
triplet. It does not prove that ERTS configuration, compilation, linking,
startup, or OTP applications support that target.

### Browser-target search

The inspected ERTS tree has `sys/common`, `sys/unix`, and `sys/win32`
platform directories, but no dedicated browser or Wasm system directory.
Searches for `emscripten`, `webassembly`, `wasm32`, and `__wasm` found:

- generic `config.sub` recognition of Wasm architectures and Emscripten/WASI
  operating-system names;
- Wasm-related code in bundled third-party `zstd`/`xxhash` sources; and
- Emscripten handling in bundled AsmJit sources, including its inability to
  generate Wasm code.

No documented first-party ERTS browser platform port, boot target, or
browser-specific conformance suite was found at the pinned tag. This is a
bounded negative source finding, not proof that no external or unpublished
experiment exists.

### Build and platform seams

Inspection of `erts/configure.ac`, emulator makefiles, `sys.h`, `erl_init.c`,
and system directories found:

- non-Windows targets flow through the Unix ERTS OS type in current configure
  logic, so accepting an Emscripten triplet would initially select assumptions
  broader than the browser provides;
- the documented cross-build requires a build-host Erlang system from the same
  release and contains tests whose answers are guessed during cross
  compilation;
- `sys.h` and the system layers span startup, executable/library loading,
  environment access, time, I/O, polling, signals, scheduler/thread services,
  files, terminals, and crash behavior; and
- these seams favor an explicit browser system layer and static browser driver
  over scattered `#ifdef` changes.

### Mandatory threading

Source inspection corrected an initially tempting assumption that `+S 1`
could yield a thread-free emulator:

- ERTS configuration invokes thread-library discovery and fails the emulator
  build when no thread implementation exists;
- the thread-disable option retained by `erl_interface` is not a threadless
  ERTS option;
- `erts_start_schedulers()` creates normal and dirty scheduler threads through
  ERTS's thread abstraction; and
- source and runtime documentation also identify auxiliary and poll-thread
  work.

Therefore `+S 1:1` is a single-normal-scheduler configuration, not a
single-thread build. Emscripten pthreads and shared memory are the
least-invasive first hypothesis. A non-shared-memory version would require a
new thread backend or deeper scheduler refactor and must be estimated as a
separate program.

### Interpreter and JIT

The pinned source confirms that BeamAsm is native architecture-specific JIT
machinery, while the BEAM interpreter remains the portable execution route.
The browser build should begin with JIT disabled.

`erts/emulator/beam/emu/beam_emu.c` contains both a computed-goto path and a
`NO_JUMP_TABLE` switch-dispatch path. WebAssembly's indirect-call and exact
signature rules make both compilation correctness and performance explicit
experiments rather than assumptions.

### Emscripten availability

Command:

```sh
command -v emcc
```

No executable path was returned. No configure or compile command was attempted
after that finding. In particular, this session provides no evidence for:

- C/assembly compatibility;
- ERTS atomics, futexes, TLS, or pthread behavior;
- allocator and linear-memory behavior;
- scheduler idle/wakeup integration;
- release-file loading;
- minimal `kernel`/`stdlib` boot;
- Worker-group teardown; or
- payload, startup, memory, or interaction performance.

## Primary source findings

### ERTS and OTP

- [The BEAM Book](../30-sources/stenman-2025-beam-book.md) supplied the
  conceptual subsystem inventory and the distinction between the BEAM
  abstract machine and industrial ERTS runtime.
- [The pinned ERTS source record](../30-sources/erlang-otp-project-2026-erts-build-runtime-and-source.md)
  established the cross-build constraints, mandatory thread library,
  interpreter/JIT division, system seams, process memory model, and shared
  failure domain of native extensions.
- [The OTP boot and security record](../30-sources/erlang-otp-project-2026-otp-boot-security-and-compatibility.md)
  established the ERTS-to-`init` boot chain, release scripts, a pinned matching
  `kernel`/`stdlib` baseline, code-loader authority, supervision semantics, and
  untrusted-data limits.
- [Sagonas and Wilhelmsson](../30-sources/sagonas-wilhelmsson-2006-erlang-memory-management.md)
  supplied peer-reviewed evidence for process-local heaps and the interaction
  among copied messages, independent collection, and shared areas.
- [Trinder et al.](../30-sources/trinder-et-al-2017-scaling-reliably-erlang.md)
  supplied peer-reviewed evidence that scheduler balancing, time, timers, and
  ETS synchronization are interacting scalability paths whose behavior must be
  measured across runtime flags and workload scale.

### Browser platform and WebAssembly

- [Emscripten](../30-sources/emscripten-project-2026-browser-porting-runtime.md)
  supplied the closest first toolchain but also made pthread Workers,
  `SharedArrayBuffer`, COOP/COEP, pre-created pools, asynchronous browser APIs,
  virtual filesystem semantics, and socket limitations explicit.
- [WebAssembly and browser standards](../30-sources/webassembly-standards-2026-browser-security-and-threads.md)
  established that imports are the authority boundary, Workers are not the
  DOM, the UI agent cannot block on atomics, and Wasm does not promise
  source-language memory safety or side-channel elimination.
- [WASI and WebAssembly threading status](../30-sources/webassembly-project-2026-wasi-and-threading-status.md)
  established that Core Threads leaves spawning to the embedder, legacy
  `wasi-threads` remains a Preview 1 path, and Shared-Everything Threads is
  actively changing rather than a ready browser ERTS host.
- [Browsix](../30-sources/powers-vilk-berger-2017-browsix.md) established that a
  Unix-like browser environment can be engineered but is itself a large host
  subsystem; BlazeX should instead define the smallest browser capability
  surface its supported OTP subset needs.

### Security and performance literature

- [Lehmann, Kinder, and Pradel](../30-sources/lehmann-kinder-pradel-2020-webassembly-binary-security.md)
  showed that C memory corruptions can remain exploitable inside linear memory
  and become host-visible through powerful imports.
- [Narayan et al.](../30-sources/narayan-et-al-2021-swivel.md), in Lucet's
  native x86 embedding rather than a browser or ERTS, showed the narrower but
  important point that sequential Wasm guarantees alone do not establish
  speculative confidentiality. Browser-engine mitigations remain trusted.
- [Jangda et al.](../30-sources/jangda-et-al-2019-webassembly-performance.md)
  found that whole-application results differed materially from small-kernel
  expectations in the browsers and toolchains they measured. The current
  BlazeX implication is to measure ERTS itself, not to reuse their historical
  numeric result as a budget.

## Contradictions and corrections

- **Portable C / unsupported browser target:** ERTS is deliberately portable,
  but the pinned tree still assumes a supported OS layer. Portability makes a
  port plausible; it does not make the target already supported.
- **One scheduler / one thread:** `+S 1:1` limits scheduler parallelism but does
  not remove the runtime's mandatory threading or auxiliary work.
- **Wasm sandbox / memory-safe ERTS:** Wasm bounds the module and its host
  imports. Unsafe C can still corrupt state inside that module.
- **OTP in Wasm / OTP rewrite:** most OTP behaviours remain matching BEAM
  modules. The porting work is ERTS plus host-dependent BIF/driver/application
  boundaries, not a JavaScript reimplementation of supervision.
- **Browser filesystem / POSIX filesystem:** a virtual release image and
  IndexedDB synchronization can expose file-shaped APIs, but durability,
  permissions, locking, and blocking behavior are not ordinary POSIX
  semantics.
- **Fetch or WebSocket / sockets:** mapping the application's intended network
  operations to browser APIs is credible; claiming arbitrary TCP/UDP
  compatibility is not.
- **Worker isolation / hostile BEAM sandbox:** a Worker gives the page a
  termination boundary. BEAM modules in one ERTS instance share trusted
  runtime authority and resource pools.
- **OTP supervision / VM recovery:** a supervisor can restart child processes
  while ERTS is healthy. Only the outer host can terminate and recreate a
  wedged or corrupt VM.
- **Successful counter / viable runtime:** an end-to-end component is
  necessary evidence only after boot, semantics, bridge, security, resource,
  and cleanup gates exist.

## Repository observations

- No first-party ERTS-to-Wasm runtime package, source tree, experiment, or
  build script exists in the repository at this research point.
- Current package ownership remains authoritative and must not be silently
  expanded by a research note.
- `packages/blazex_build` already owns application reachability, manifests,
  reproducibility, provenance, and diagnostics. A future ERTS runtime area
  should expose a build contract to it rather than move ERTS behavior into the
  build package.
- `integration/bh-06/vertical_slice/lib/counter.ex` is the best current
  apples-to-apples first Elixir payload: it uses the public component API and
  exercises mount, semantic output, event transition, and termination.
- The current browser roadmap places full ERTS/OTP browser parity outside the
  existing browser 1.0 commitment. Adoption therefore requires an ADR and
  roadmap amendment rather than a documentation-only substitution.

## Resulting synthesis

The [main note](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
recommends a bounded program built around:

- upstream Erlang/OTP 29.x / ERTS 17.x source with a minimal patch ledger;
- interpreter-only `wasm32-unknown-emscripten` output;
- ERTS execution off the UI agent, with Stage 1 comparing the
  `PROXY_TO_PTHREAD` control-shell topology and an outer Dedicated Worker with
  nested pthread Workers;
- immutable pinned matching `kernel`/`stdlib` release assets;
- a small static ERTS browser system/driver layer;
- a versioned, bounded, generation-aware capability broker;
- no arbitrary code loading, dynamic native extensions, raw sockets, OS
  commands, generic JavaScript calls, or untrusted ETF boundary;
- host-enforced quotas and hard runtime termination;
- signed manifests, reproducible builds, SBOM, provenance, import closure,
  fuzzing, and native-vs-Wasm differential tests; and
- a go/no-go gate at real OTP boot and operational lifecycle cleanup: no live
  owned handles or pthread entries, unreachable generation buffers, and stable
  memory/Worker metrics without a positive repeated-cycle slope before broad
  BlazeX integration.

## Evidence limits and follow-ups

This session answers how to structure a serious experiment, not whether the
experiment passes. The next work must install and pin Emscripten, record a
complete configure failure inventory, build tiny probes for each ERTS
primitive, and attempt the minimal interpreter/OTP boot. Estimates should wait
until that failure inventory distinguishes mechanical build fixes from deep
scheduler, poller, allocator, and loader changes.

The central [feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
remains open. No production support, browser compatibility, security, payload,
performance, or maintenance claim follows from this research alone.
