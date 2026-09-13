---
title: "Swivel: Hardening WebAssembly against Spectre"
kind: source
created: "2026-09-13"
authors:
  - "Shravan Narayan"
  - "Craig Disselkoen"
  - "Daniel Moghimi"
  - "Sunjay Cauligi"
  - "Evan Johnson"
  - "Zhao Gang"
  - "Anjo Vahldiek-Oberwagner"
  - "Ravi Sahita"
  - "Hovav Shacham"
  - "Dean Tullsen"
  - "Deian Stefan"
published: 2021
citation_key: "narayan-et-al-2021-swivel"
container: "30th USENIX Security Symposium (USENIX Security 21)"
edition: null
isbn: "978-1-939133-24-3"
doi: null
url: "https://www.usenix.org/conference/usenixsecurity21/presentation/narayan"
accessed: "2026-09-13"
tags:
  - microarchitectural-security
  - research-paper
  - side-channels
  - spectre
  - webassembly
aliases:
  - "Swivel WebAssembly Spectre hardening"
---

# Swivel: Hardening WebAssembly against Spectre

## Reference

Shravan Narayan, Craig Disselkoen, Daniel Moghimi, Sunjay Cauligi, Evan
Johnson, Zhao Gang, Anjo Vahldiek-Oberwagner, Ravi Sahita, Hovav Shacham,
Dean Tullsen, and Deian Stefan. “Swivel: Hardening WebAssembly against
Spectre.” *30th USENIX Security Symposium (USENIX Security 21)*, 2021,
1433–1450. ISBN 978-1-939133-24-3.
[Conference record](https://www.usenix.org/conference/usenixsecurity21/presentation/narayan).
[Open-access paper](https://www.usenix.org/system/files/sec21-narayan.pdf).
Accessed 2026-09-13.

## Research question or contribution

How can an in-process Wasm sandbox be compiled and hosted so Spectre attacks
cannot speculatively escape its memory boundary or poison a co-located host or
Wasm tenant into leaking secrets?

## Method

The authors implement two defenses by modifying Lucet's Cranelift
Wasm-to-x86 code generator and runtime. They demonstrate proof-of-concept
breakout and poisoning attacks against unmodified Lucet for conditional-branch,
branch-target, and return-stack-buffer predictors, then evaluate hardened
variants with Sightglass, the Wasm-compatible subset of SPEC CPU 2006, and
server workloads.

## Findings

- Wasm's sequential control-flow and memory checks do not by themselves
  constrain transient execution. Speculation can cross a sandbox boundary or
  induce another protection domain to leak data through a cache side channel.
- Swivel-SFI is a software-only design. It compiles Wasm into linear blocks,
  confines memory accesses, uses a separate return-address stack, avoids
  ordinary returns, and combines branch-target-buffer flushing with either
  address randomization or deterministic branch rewriting.
- Swivel-CET uses Intel Control-flow Enforcement Technology and Memory
  Protection Keys, plus linear blocks and register interlocking. This supports
  a stronger deterministic design but depends on particular hardware and has
  different performance and threat-model tradeoffs.
- On the paper's compatible SPEC CPU 2006 workloads, the randomized/ASLR
  Swivel-SFI and Swivel-CET variants incurred at most 10.3% and 6.1% overhead,
  respectively. Deterministic variants ranged from 3.3% to 86.1% for
  Swivel-SFI and 8.0% to 240.2% for Swivel-CET, with geometric means of 47.3%
  and 96.3%.
- The designs assume a correct compiler, runtime, and operating system plus
  current CPU microcode. Every evaluated scheme except deterministic
  Swivel-CET also assumes hyperthreading is disabled, and several variants
  constrain attacker-controlled cross-sandbox calls.
- Swivel addresses deliberate Spectre leakage, not ordinary sequential secret
  disclosure. The paper still assumes constant-time or other defenses where
  program logic itself can leak secrets.

## Relevance

This work prevents BlazeX from treating Wasm validation, workers, or shared
linear memory as a complete confidentiality boundary. A browser ERTS profile
should avoid embedding long-lived secrets, keep non-extractable keys behind
WebCrypto operations where possible, minimize shared-memory exposure, and
separate mutually untrusted workloads into independently terminable runtime
instances. Browser-engine Spectre defenses and supported-version policy remain
part of the trust base; application supervision cannot mitigate a
microarchitectural disclosure by itself.

## Limits

Swivel targets Lucet's native x86 server embedding, not browser JavaScript
engines, Emscripten pthread workers, or ERTS. Its CET/MPK and kernel-level
mechanisms cannot be directly selected by browser application code. Hardware,
compiler, and browser mitigations have evolved since 2021. The reported
benchmarks do not predict ERTS overhead, and the paper does not address
ordinary memory corruption, over-privileged host imports, cross-origin policy,
storage security, or denial of service.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [First-party ERTS/Wasm feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [2026-09-13 first-party ERTS WebAssembly runtime deep dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
