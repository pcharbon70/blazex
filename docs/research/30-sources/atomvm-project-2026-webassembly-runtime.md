---
title: "AtomVM WebAssembly runtime and BEAM execution model"
kind: source
created: "2026-09-02"
authors:
  - "AtomVM project contributors"
published: 2026
citation_key: "atomvm-2026-webassembly-runtime"
container: "AtomVM documentation and source repository"
edition: null
isbn: null
doi: null
url: "https://github.com/atomvm/AtomVM"
accessed: "2026-09-02"
tags:
  - atom-vm
  - beam
  - elixir
  - virtual-machines
  - webassembly
aliases:
  - "AtomVM browser runtime"
---

# AtomVM WebAssembly runtime and BEAM execution model

## Reference

AtomVM project contributors. [AtomVM source
repository](https://github.com/atomvm/AtomVM), [project
documentation](https://doc.atomvm.org/main/), and current release material.
Accessed 2026-09-02.

## Research question or contribution

AtomVM is the compact BEAM-compatible runtime that Popcorn compiles to
WebAssembly. Its compatibility and process model determine which Elixir
component code can execute locally.

## Findings

- AtomVM is a from-scratch virtual machine for Erlang/Elixir BEAM bytecode,
  designed primarily for constrained and embedded environments.
- It implements lightweight processes, mailboxes, scheduling, garbage
  collection, timers, monitors/links, and selected OTP/Elixir libraries rather
  than the complete ERTS/OTP surface.
- The Emscripten/WebAssembly port can run in browser and Node environments.
- `.avm` packbeam files aggregate compiled BEAM modules and assets for loading
  by the VM.
- Browser-hosted use still depends on JavaScript/Emscripten bindings for
  environment services.
- Ongoing releases add Elixir, supervisor, distribution, and platform support,
  but compatibility remains version-specific.

## Relevance

AtomVM gives BlazeX real Elixir process semantics at a much smaller scope than
shipping ERTS itself. Its intentional subset means BlazeX needs a declared
client runtime-support profile, transitive dependency analysis, and diagnostics
for unsupported BIFs/NIFs/modules.

## Limits

The general AtomVM project covers microcontrollers and POSIX as well as Wasm;
capabilities on one platform do not automatically exist in the browser port.
The present review relied on documentation and the Popcorn integration rather
than building AtomVM from source or running a conformance suite.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [BlazeX feasibility inquiry](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md)
