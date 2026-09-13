---
title: "WebAssembly browser security, isolation, and threading standards"
kind: source
created: "2026-09-13"
authors:
  - "WebAssembly Community Group"
  - "WHATWG"
  - "Web Application Security Working Group"
  - "Emscripten contributors"
published: null
citation_key: "webassembly-standards-2026-browser-security-threads"
container: "WebAssembly specifications, HTML Living Standard, CSP Level 3, and Emscripten documentation"
edition: "WebAssembly 3.0 and living standards"
isbn: null
doi: null
url: "https://webassembly.github.io/spec/"
accessed: "2026-09-13"
tags:
  - browser-security
  - cross-origin-isolation
  - emscripten
  - shared-memory
  - threads
  - webassembly
aliases:
  - "Browser Wasm security and threads standards"
---

# WebAssembly browser security, isolation, and threading standards

## Reference

WebAssembly Community Group, WHATWG, Web Application Security Working Group,
and Emscripten contributors. Living specifications and implementation
documentation accessed 2026-09-13. Principal sources:

- [WebAssembly specifications](https://webassembly.github.io/spec/), including
  the [Core Specification 3.0](https://webassembly.github.io/spec/core/), its
  [type-soundness appendix](https://webassembly.github.io/spec/core/appendix/properties.html),
  and the [JavaScript Interface](https://webassembly.github.io/spec/js-api/)
- WHATWG [Web workers](https://html.spec.whatwg.org/multipage/workers.html),
  [JavaScript agents and event loops](https://html.spec.whatwg.org/multipage/webappapis.html#integration-with-the-javascript-agent-formalism),
  and [cross-origin opener and embedder
  policies](https://html.spec.whatwg.org/multipage/browsers.html#cross-origin-opener-policies)
- [Content Security Policy Level 3 WebAssembly
  integration](https://www.w3.org/TR/CSP3/#wasm-integration)
- Emscripten [pthreads support](https://emscripten.org/docs/porting/pthreads.html)

## Research question or contribution

What isolation does browser WebAssembly actually provide, and which standards
and deployment constraints govern a threaded C runtime compiled to Wasm?

## Method

This note compares the normative Core Wasm, JavaScript embedding, HTML, and
CSP requirements with Emscripten's documented pthread implementation. It
records standards-level guarantees separately from browser and toolchain
integration behavior. No browser conformance or performance test was run for
this note.

## Findings

- Core Wasm gives a validated module no ambient access to its execution
  environment. Host effects are available only through definitions supplied
  as imports, so the embedder's import set is a security and capability
  boundary.
- Wasm validation and execution protect module, function, and linear-memory
  boundaries according to the Wasm semantics. The Core specification
  explicitly does not promise that code compiled from an unsafe language
  cannot corrupt its own object layout inside linear memory, and it leaves
  hardware side-channel mitigation to the embedding environment.
- The JavaScript Interface supplies modules, instances, functions, tables,
  globals, and memories. Neither the Core nor JavaScript specification grants
  direct DOM, filesystem, socket, or operating-system access.
- Browser pthreads in Emscripten use Web Workers, shared
  `WebAssembly.Memory`/`SharedArrayBuffer`, and atomic operations. Emscripten
  requires `-pthread` while compiling and linking and documents this support
  as stable.
- Browser exposure and transfer of shared memory are gated by the HTML
  cross-origin-isolated capability. In normal deployment that requires a
  compatible `Cross-Origin-Opener-Policy` and
  `Cross-Origin-Embedder-Policy`; COOP can split browsing-context groups and
  COEP restricts cross-origin subresources that have not opted in.
- The Worker processing model checks embedder policy for each Worker response.
  A dedicated or nested pthread Worker must receive a COEP compatible with its
  creator (`require-corp` for the proposed profile), recursively; page-level
  isolation is not sufficient evidence. The runtime must verify
  `self.crossOriginIsolated` inside every Worker before sharing memory.
- A dedicated worker and its creator can share memory within an agent cluster.
  Emscripten warns that the browser main thread cannot use blocking
  `Atomics.wait`, so code that may synchronously wait or join belongs in a
  worker rather than the UI agent.
- Worker creation is asynchronous on the Web. POSIX does not guarantee that a
  new child has already run when `pthread_create` returns, but native code can
  immediately join or wait for its effects. Emscripten therefore offers a
  pre-created pthread Worker pool, and qualification can make exhaustion a hard
  error rather than risk a deadlock.
- Emscripten cannot produce one artifact that selects threaded execution when
  shared memory is available and transparently falls back to non-threaded
  execution otherwise. Supporting both modes requires separate builds and
  an outer selection policy.
- CSP Level 3 gates Wasm compilation and instantiation. The
  `'wasm-unsafe-eval'` source expression permits Wasm execution sinks without
  also enabling JavaScript `eval`, while `'unsafe-eval'` enables both.
- Terminating a dedicated worker provides a browser-level containment and
  recovery primitive, but the standards do not prove that a toolchain's whole
  multi-worker runtime group has released every resource; that remains an
  implementation lifecycle obligation.

## Relevance

A browser ERTS port should keep ERTS execution off the UI agent in a directly
supervised Worker group, use an explicitly reviewed and versioned import ABI,
pre-create any required pthread workers, compare supported Emscripten Worker
topologies, and treat recursive Worker COEP plus per-context CSP as product
deployment requirements. Cross-origin isolation enables shared-memory execution;
it does not make ERTS C code
memory-safe or turn loaded application code into an untrusted-code sandbox.
The host should expose narrow time, randomness, network, storage, and logging
capabilities rather than a generic JavaScript-call or POSIX-syscall escape.

## Limits

These are living specifications and development documentation and can change.
They define browser primitives, not POSIX or ERTS compatibility. Emscripten's
pthread implementation is toolchain-specific, cross-origin isolation has
application-wide embedding and resource-loading consequences, and no source
here establishes acceptable scheduler, memory, startup, or teardown behavior
for an ERTS build. Standards-compliant isolation also does not eliminate
browser-engine defects or microarchitectural side channels.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [First-party ERTS/Wasm feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [2026-09-13 first-party ERTS WebAssembly runtime deep dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
