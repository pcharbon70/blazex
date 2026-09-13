---
title: "Erlang/OTP boot, security, and browser compatibility"
kind: source
created: "2026-09-13"
authors:
  - "Erlang/OTP Project"
published: 2026
citation_key: "erlang-otp-project-2026-otp-boot-security-compatibility"
container: "Erlang/OTP 29.0.6 and ERTS 17.0.6 documentation and source"
edition: "OTP-29.0.6; ERTS 17.0.6"
isbn: null
doi: null
url: "https://www.erlang.org/doc/apps/erts/init.html"
accessed: "2026-09-13"
tags:
  - boot
  - browser-security
  - erlang
  - erts
  - otp
  - release-engineering
  - security
  - webassembly
aliases:
  - "ERTS WebAssembly boot and security evidence"
---

# Erlang/OTP boot, security, and browser compatibility

## Reference

Erlang/OTP Project. OTP 29.0.6 / ERTS 17.0.6 documentation and source:

- [`init`](https://www.erlang.org/doc/apps/erts/init.html) and the tagged
  [`init.erl`](https://github.com/erlang/otp/blob/OTP-29.0.6/erts/preloaded/src/init.erl);
- tagged C startup source
  [`erl_init.c`](https://github.com/erlang/otp/blob/OTP-29.0.6/erts/emulator/beam/erl_init.c);
- low-level module and boot-script loader
  [`erl_prim_loader`](https://www.erlang.org/doc/apps/erts/erl_prim_loader.html);
- the Kernel [`code` server API](https://www.erlang.org/doc/apps/kernel/code.html),
  including runtime binary loading, replacement, deletion, and purge;
- [boot-script format](https://www.erlang.org/doc/apps/sasl/script.html),
  [release structure](https://www.erlang.org/doc/system/release_structure.html),
  and the [Kernel application introduction](https://www.erlang.org/doc/apps/kernel/introduction_chapter.html);
- [OTP design principles](https://www.erlang.org/doc/system/design_principles.html)
  and [supervision principles](https://www.erlang.org/doc/system/sup_princ.html);
- security advisory [GHSA-54pw-5645-jh86, “binary_to_term crash on crafted
  BIT_BINARY_EXT input”](https://github.com/erlang/otp/security/advisories/GHSA-54pw-5645-jh86),
  published 2026-07-27.

All pages were accessed 2026-09-13. Version-neutral documentation URLs
identified themselves as OTP 29.0.6 where noted during access.

## Research question or contribution

How can a browser ERTS port retain the real OTP boot and supervision model
while giving untrusted Web input no ambient authority and preserving a clear,
patchable security boundary?

## Method

The upstream C-to-Erlang startup chain, release/boot documentation, mandatory
Kernel surface, OTP supervision semantics, and a current ERTS security advisory
were compared with browser hosting constraints. Proposed controls below are
explicitly marked as synthesis rather than attributed to Erlang/OTP.

## Findings

### Upstream boot chain

- `erl_init.c` performs low-level runtime initialization. Its responsibilities
  include allocators and memory, atoms and modules, processes and signals,
  timers, I/O, BIF/NIF infrastructure, garbage collection, and schedulers. It
  then preloads modules, creates the initial process, and starts scheduling.
- `init` is a preloaded module. The first Erlang function evaluated is
  `init:boot(BootArgs)`, which reads and interprets the boot script and
  coordinates system startup.
- `erl_prim_loader` loads all Erlang modules and fetches the boot script. The
  documented native loader backends are `efile` and `inet`; both assume host
  facilities that need deliberate replacement or restriction in a browser.
- A `.rel` file identifies an ERTS version and versioned applications.
  `systools` generates `.script` and `.boot` artifacts, conventionally exposed
  as `start.boot`. The documented minimal OTP release contains Kernel and
  STDLIB.
- Kernel is the first and mandatory OTP application. Its normal services span
  code and file servers, application management, configuration, logging,
  naming, supervision, networking/distribution, sockets, and operating-system
  integration. Preserving OTP therefore requires its process model while
  explicitly adapting or disabling host services that browsers cannot supply.

### What OTP requires from ERTS

- Supervisors, workers, `gen_server`, restart strategies, and most other OTP
  behaviours are Erlang modules executed as BEAM code. They do not need a
  parallel JavaScript reimplementation if compatible ERTS primitives, Kernel,
  and STDLIB can boot.
- OTP supervision handles failures expressed as Erlang process exits. It is not
  a containment boundary for emulator memory corruption, a stuck runtime
  thread, or termination of the hosting Worker.
- Links, monitors, ordered signals, timers, process exits, registered names,
  code loading, and application lifecycle are compatibility obligations. A UI
  demonstration that only evaluates selected functions is not yet an OTP boot.

### Security evidence

- GHSA-54pw-5645-jh86 documents a seven-byte crafted External Term Format
  value that caused an allocation underflow and full emulator crash. The issue
  affected OTP 27 and later before patched releases, including ERTS 15 and
  later; OTP 29.0.4 / ERTS 17.0.4 were listed as patched baselines.
- The advisory explicitly states that OTP supervision, Erlang exception
  handling, and the `binary_to_term/2` `safe` option could not intercept this
  VM-level failure. The option restricts atom creation; it is not complete
  structural validation of hostile ETF.
- OTP 29.0.6 was released after that fix and contains further ERTS and
  application security corrections. A browser artifact therefore needs the
  same rapid pin, advisory review, rebuild, and provenance process as any
  native runtime distribution.

## Relevance

### Proposed boot contract

The strongest browser design is to preserve the upstream boot chain rather
than introduce a second JavaScript-defined application lifecycle. A build-host
OTP installation of the exact pinned release should generate an immutable
minimal release containing `start.boot`, Kernel, STDLIB, application metadata,
and the required BEAM modules. The browser artifact should load those bytes
from a signed, content-addressed manifest or an immutable preloaded image.

This is a proposed architecture. Upstream documents `efile` and `inet`; it does
not document the proposed manifest loader. Embedded mode and an immutable boot
image do not by themselves disable `code:load_binary/3` or all replacement and
purge paths. Every primitive that can admit BEAM must therefore converge on a
patched or interposed low-level check of normalized manifest module name and
digest before parsing. Dynamic loading, replacement, purge, `on_load`, and hot
upgrades should fail outside that rule until a separately authenticated design
and rollback model exist.

The boot proof should advance through independently testable gates:

1. the WebAssembly module instantiates with ERTS off the UI agent and every
   Worker in the chosen Emscripten topology directly registered;
2. C runtime initialization completes and the preloaded `init` module runs;
3. the immutable `start.boot` is read and minimal Kernel/STDLIB services start;
4. spawn, send/receive, timers, links, monitors, exits, and garbage collection
   pass native-versus-browser semantic tests;
5. a `gen_server` under a one-for-one supervisor is killed and restarted with
   the expected observable behavior; and
6. a capability-checked browser event enters through a port, reaches an OTP
   process, and returns a rendered response without blocking the UI thread.

### Proposed security boundary

- Keep ERTS off the UI agent in a directly supervised Worker group. Whole-group
  termination is the browser's hard containment and recovery mechanism; OTP
  supervision remains the in-runtime recovery mechanism.
- Use one small, statically linked browser port driver. Each operation should
  carry the runtime generation, an allowlisted opcode, a request identifier,
  bounded input, and a cancellation/deadline policy. Grants apply to the whole
  runtime instance: the host cannot infer which OTP application originated a
  request, so a separate trust domain needs a separate instance. Completion
  should become a normal ERTS message.
- Do not provide arbitrary JavaScript evaluation, arbitrary property traversal,
  ambient filesystem access, raw TCP/UDP, Erlang distribution, child-process
  creation, shell commands, host environment enumeration, POSIX signals, or
  dynamic native-library loading in the first profile. Unsupported operations
  must fail deterministically rather than report synthetic success.
- Treat all bytes crossing the browser bridge as hostile and never expose ETF
  at that boundary. `binary_to_term(..., [safe])` is not structural or
  memory-safety validation. Use a small length-delimited schema. JavaScript must
  snapshot Wasm-to-JS frames into private memory before semantic validation;
  JS-to-Wasm frames must be built privately, published immutably from an owned
  slot, and copied by the ERTS bridge thread into an ERTS-owned logically
  exclusive buffer before release. Bound nesting, collection lengths, binaries,
  mailbox growth, and outstanding requests.
- Enforce quotas for process count, maximum process heap, total WebAssembly
  memory, binaries, atoms created after boot, ETS objects, timers, mailbox
  high-water marks, and concurrent host operations. Emit saturation metrics so
  limits reveal scaling failures instead of merely hiding them.
- Ship a locked compiler/toolchain/runtime bill of materials, source and patch
  references, deterministic build inputs, artifact digests, and a documented
  advisory-to-release service level.

### Proposed compatibility and security gates

Run applicable upstream Common Test subsets for `erts`, `kernel`, and `stdlib`
and maintain a differential corpus that executes the same BEAM artifacts on
the pinned native and browser runtimes. Fuzz at least the BEAM loader and
external-term decoder internally for defense in depth without exposing ETF as
a browser protocol, plus the boot manifest and browser bridge. Exercise process, atom,
mailbox, binary, timer, and host-request exhaustion under both Chrome and
Firefox, with memory-growth telemetry and deterministic cleanup assertions.

## Limits

The proposed manifest loader, port protocol, quotas, Worker recovery contract,
and test ladder are cross-source design conclusions; they are not current
Erlang/OTP features or upstream browser-support commitments. The exact subset
of Kernel/STDLIB that boots cannot be known until the tagged ERTS build reaches
the module loader and a trace records every missing primitive and host service.

The cited advisory demonstrates why VM-level patching and hostile-input
validation are required, but one vulnerability does not constitute a complete
ERTS security audit. Browser-origin policy, cross-origin isolation, JavaScript
supply chain, Wasm compiler correctness, side channels, and denial-of-service
resilience require separate threat modeling and verification.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [Can BlazeX build and own an ERTS WebAssembly runtime stack?](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [First-party ERTS WebAssembly runtime deep-dive journal](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
