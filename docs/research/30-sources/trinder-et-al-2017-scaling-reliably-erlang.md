---
title: "Scaling Reliably: Improving the Scalability of the Erlang Distributed Actor Platform"
kind: source
created: "2026-09-13"
authors:
  - "Phil Trinder"
  - "Natalia Chechina"
  - "Nikolaos Papaspyrou"
  - "Konstantinos Sagonas"
  - "Simon Thompson"
  - "Stephen Adams"
  - "Stavros Aronis"
  - "Robert Baker"
  - "Eva Bihari"
  - "Olivier Boudeville"
  - "Francesco Cesarini"
  - "Maurizio Di Stefano"
  - "Sverker Eriksson"
  - "Viktoria Fordos"
  - "Amir Ghaffari"
  - "Aggelos Giantsios"
  - "Rickard Green"
  - "Csaba Hoch"
  - "David Klaftenegger"
  - "Huiqing Li"
  - "Kenneth Lundin"
  - "Kenneth MacKenzie"
  - "Katerina Roukounaki"
  - "Yiannis Tsiouris"
  - "Kjell Winblad"
published: 2017
citation_key: "trinder-et-al-2017-scaling-reliably-erlang"
container: "ACM Transactions on Programming Languages and Systems"
edition: "Volume 39, Issue 4, Article 17"
isbn: null
doi: "10.1145/3107937"
url: "https://arxiv.org/abs/1704.07234"
accessed: "2026-09-13"
tags:
  - actor-model
  - beam
  - erlang
  - erts
  - research-paper
  - scalability
  - scheduling
aliases:
  - "Scaling Reliably Erlang study"
---

# Scaling Reliably: Improving the Scalability of the Erlang Distributed Actor Platform

## Reference

Phil Trinder et al. “Scaling Reliably: Improving the Scalability of the Erlang
Distributed Actor Platform.” *ACM Transactions on Programming Languages and
Systems* 39, no. 4, Article 17 (2017).
[doi:10.1145/3107937](https://doi.org/10.1145/3107937).
[Open-access manuscript](https://arxiv.org/abs/1704.07234).

## Research question or contribution

Where did Erlang/OTP encounter scalability limits at VM, language, storage,
and tool levels, and which changes preserved the actor model while improving
single-host multicore and large distributed execution?

## Method

The RELEASE project combined benchmarks and two case studies across
single-host multicore/NUMA systems and clusters, identified shared-state and
distribution bottlenecks, implemented VM and library changes, and evaluated
new distributed-language constructs and tools. This note uses its VM and
methodological findings; its distributed-Erlang design is outside the initial
browser profile.

## Findings

- The paper treats Erlang processes as runtime-managed actors with private
  state and asynchronous messages, while OS scheduler threads execute those
  processes in parallel. Scheduler count, topology, placement, and shared
  structures all materially affect results.
- Its single-host experiments identify shared ETS tables, time retrieval,
  timers, and scheduler load balancing as consequential VM scalability paths.
  Adding schedulers can expose contention rather than automatically improve
  throughput.
- The reported ERTS work includes finer-grained and decentralized ETS
  synchronization, scheduler-utilization-aware balancing, and redesigned time
  and timer mechanisms. These improvements accumulated across OTP releases
  rather than forming one replaceable scheduler loop.
- Shared global state can undermine both scalability and reliability. The
  paper's broader language work partitions distributed connection and naming
  state instead of assuming transparent global coordination remains cheap at
  every scale.
- Evaluation varies scheduler count, runtime version and flags, workload,
  topology, and resource scale. The paper demonstrates that a single endpoint
  number can hide a change in scaling slope or an internal contention point.
- Model-based, property-driven comparison was used to validate parts of the
  new distributed semantics against their implementation, illustrating the
  value of an executable oracle rather than example tests alone.

## Relevance

The browser port should preserve current ERTS scheduling, time, timer, ETS,
and process invariants rather than simplifying them from an old conceptual
description. Starting at one online scheduler may reduce parallelism, but it
does not justify removing the thread substrate or assuming shared structures
are irrelevant.

BlazeX should also copy the paper's measurement discipline: vary scheduler and
Worker counts, ERTS flags, process count, mailbox load, timers, ETS sharing,
and host-call frequency; record throughput, latency distribution, memory, and
cleanup slopes; and compare the same BEAM workload with the pinned native
runtime. A visually successful component click is not a scheduler conformance
or scalability result.

## Limits

The experiments use historical OTP releases, server-class multicore/NUMA
machines, clusters, and distributed workloads—not WebAssembly, browser
Workers, Emscripten, a single UI runtime, or current ERTS 17. Its numerical
scalability results cannot forecast browser performance. Many discussed VM
improvements have since evolved or become ordinary upstream behavior, so the
current tagged source remains authoritative for implementation details.

## Derived work

- [First-party Erlang/OTP ERTS WebAssembly runtime stack](../20-notes/first-party-erlang-otp-erts-webassembly-runtime-stack.md)
- [First-party ERTS/Wasm feasibility inquiry](../40-inquiries/can-blazex-build-and-own-an-erts-webassembly-runtime-stack.md)
- [ERTS WebAssembly runtime stack map](../10-maps/erts-webassembly-runtime-stack.md)
- [2026-09-13 first-party ERTS WebAssembly runtime deep dive](../50-journal/2026-09-13-first-party-erts-webassembly-runtime-deep-dive.md)
