---
title: "Not So Fast: Analyzing the Performance of WebAssembly vs. Native Code"
kind: source
created: "2026-09-13"
authors:
  - "Abhinav Jangda"
  - "Bobby Powers"
  - "Emery D. Berger"
  - "Arjun Guha"
published: 2019
citation_key: "jangda-et-al-2019-webassembly-performance"
container: "2019 USENIX Annual Technical Conference (USENIX ATC '19)"
edition: "Pages 107-120"
isbn: "978-1-939133-03-8"
doi: null
url: "https://www.usenix.org/conference/atc19/presentation/jangda"
accessed: "2026-09-13"
tags:
  - benchmarking
  - browser
  - performance
  - research-paper
  - webassembly
aliases:
  - "Not So Fast WebAssembly performance study"
---

# Not So Fast: Analyzing the Performance of WebAssembly vs. Native Code

## Reference

Abhinav Jangda, Bobby Powers, Emery D. Berger, and Arjun Guha. “Not So Fast:
Analyzing the Performance of WebAssembly vs. Native Code.” In *2019 USENIX
Annual Technical Conference*, 107–120. USENIX Association, 2019.
[Conference record and open-access
paper](https://www.usenix.org/conference/atc19/presentation/jangda).

## Research question or contribution

Do small scientific kernels accurately predict WebAssembly performance for
larger native applications, and which compiler or execution effects explain
the remaining gap from native code?

## Method

The authors extended Browsix with WebAssembly support and a SPEC harness, then
compiled compatible SPEC CPU 2006 and 2017 programs to native code and
WebAssembly. They executed each benchmark five times on an Intel Xeon system
under Ubuntu 16.04, Chrome 74, and Firefox 66. The browsers ran without source
modification under their standard sandboxing, while the harness attached Linux
performance counters to the relevant worker thread. Reported runtime begins
after WebAssembly JIT compilation, so startup and compilation are separate from
the principal execution comparison.

## Findings

- The paper's larger SPEC workloads produced an average slowdown of 1.55× in
  Chrome and 1.45× in Firefox relative to its native baseline, with peak
  slowdowns of 2.5× and 2.08× respectively. Those results contradicted a simple
  extrapolation from much smaller kernel benchmarks.
- The measured host-kernel overhead averaged only 0.2% for the selected SPEC
  workloads after the authors corrected substantial allocation and copying
  costs in the test infrastructure. Benchmark scaffolding can otherwise mask or
  exaggerate runtime costs.
- The authors attribute much of the observed difference to more loads and
  stores from register pressure, extra branch and safety checks, weaker
  instruction selection, more executed instructions, and more instruction-cache
  misses in the browser-generated machine code.
- WebAssembly outperformed asm.js in the same framework, but neither that result
  nor WebAssembly's portability establishes native performance parity.
- A credible comparison needs representative whole applications, multiple
  browsers, a matched native baseline, repeated samples, and measurements that
  separate compilation, host-service, and steady-state execution costs.

## Relevance

BlazeX should benchmark an ERTS/Wasm candidate as a complete runtime workload,
not infer viability from a small C kernel or one component click. Required
measurements include download and compilation, boot, BEAM loading, scheduler
and garbage-collection work, steady-state component transitions, JavaScript
boundary traffic, memory, and teardown in each active browser. Host shims and
the measurement harness need their own profiles so their costs cannot disappear
inside a single aggregate number.

## Limits

This is a 2019 study of Chrome 74, Firefox 66, the initial stable WebAssembly
feature set, Clang 4.0, SPEC CPU programs, and a purpose-built browser kernel.
It does not evaluate ERTS, concurrent process scheduling, a managed runtime's
garbage collector, current browsers, WebAssembly threads, or present compiler
optimizations. Its numeric slowdowns are historical evidence about evaluation
method and possible causes, not a forecast or acceptance budget for BlazeX.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [First-party ERTS/Wasm feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [2026-09-13 first-party ERTS WebAssembly runtime deep dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
