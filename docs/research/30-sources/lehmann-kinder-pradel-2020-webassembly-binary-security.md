---
title: "Everything Old is New Again: Binary Security of WebAssembly"
kind: source
created: "2026-09-13"
authors:
  - "Daniel Lehmann"
  - "Johannes Kinder"
  - "Michael Pradel"
published: 2020
citation_key: "lehmann-kinder-pradel-2020-webassembly-binary-security"
container: "29th USENIX Security Symposium (USENIX Security 20)"
edition: null
isbn: "978-1-939133-17-5"
doi: null
url: "https://www.usenix.org/conference/usenixsecurity20/presentation/lehmann"
accessed: "2026-09-13"
tags:
  - binary-security
  - memory-safety
  - research-paper
  - unsafe-languages
  - webassembly
aliases:
  - "Binary security of WebAssembly"
---

# Everything Old is New Again: Binary Security of WebAssembly

## Reference

Daniel Lehmann, Johannes Kinder, and Michael Pradel. “Everything Old is New
Again: Binary Security of WebAssembly.” *29th USENIX Security Symposium
(USENIX Security 20)*, 2020, 217–234. ISBN 978-1-939133-17-5.
[Conference record](https://www.usenix.org/conference/usenixsecurity20/presentation/lehmann).
[Open-access paper](https://www.usenix.org/system/files/sec20-lehmann.pdf).
Accessed 2026-09-13.

## Research question or contribution

To what extent do memory-safety vulnerabilities in source languages remain
exploitable after compilation to Wasm, and how does Wasm binary security
compare with native-code mitigations?

## Method

The authors analyze LLVM/Emscripten-generated Wasm memory organization and
available mitigations, organize exploit construction into write, overwrite,
and malicious-action primitives, and build end-to-end exploits for browser,
Node.js, and standalone Wasm hosts. Their empirical corpus contains 26 Wasm
binaries—real web applications plus 17 C/C++ programs from SPEC CPU
2017—with 19.2 million instructions across 98,924 functions. The SPEC
programs were compiled with Emscripten 1.39.7, primarily at `-O3`.

## Findings

- Wasm protects its managed execution stack, code, tables, and host from
  ordinary out-of-bounds linear-memory access, but it does not make an unsafe
  source program's internal linear-memory object layout safe.
- In the compiler layouts studied, static data, an unmanaged application
  stack, and the heap share linear memory. Overflows can therefore corrupt
  adjacent regions even though they cannot write outside the module's linear
  memory.
- At the time of the study, linear memory offered no native-like read-only
  pages, guard pages between these regions, or address-space randomization.
  Supposedly constant aggregate data and string literals could remain
  writable inside linear memory.
- The paper composes attacks in three stages: obtain an unintended memory
  write, overwrite sensitive stack/heap/static data, then trigger harmful
  behavior through altered data, an indirect call, or a privileged host
  function.
- Its browser demonstration turns a libpng stack overflow into cross-site
  scripting by corrupting a heap string later passed to `document.write`.
  The host import converts an in-module memory bug into an origin-visible
  security effect.
- In the measured corpus, approximately one third of functions used the
  unmanaged linear-memory stack, and approximately half could be reached from
  an indirect call whose target index was obtained from linear memory. These
  are corpus and toolchain measurements, not universal Wasm guarantees.
- The authors recommend reducing code written in unsafe languages and
  importing only necessary host APIs, alongside compiler and runtime
  hardening. Wasm's module sandbox is complementary to, not a replacement
  for, source-level memory safety and binary defenses.

## Relevance

ERTS is a substantial C runtime, so compiling it to Wasm would protect the
browser from direct arbitrary native memory access without making ERTS itself
immune to corrupt inputs or unsafe-memory defects. BlazeX should minimize its
statically linked native surface, prohibit generic JavaScript and raw-HTML
imports, narrowly broker all effects, fuzz every pointer/length boundary, and
exercise native and Wasm sanitizer builds. A worker is a recovery boundary;
BEAM processes within one memory are not independent hostile-code sandboxes.

## Limits

The measurements describe 2020 Wasm, Emscripten 1.39.7, selected real-world
binaries, and SPEC CPU programs rather than ERTS. The demonstrations establish
attack primitives and feasibility, not the presence of a vulnerability in a
future BlazeX runtime. Wasm, compiler, sanitizer, and multi-memory facilities
have evolved since publication, while some proposed mitigations carry code
size or performance costs. The paper focuses on sequential binary
exploitation rather than speculative-execution leakage or application-level
authorization flaws.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [First-party ERTS/Wasm feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [2026-09-13 first-party ERTS WebAssembly runtime deep dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
