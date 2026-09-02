---
title: "Firefly alternative BEAM compiler and WebAssembly target"
kind: source
created: "2026-09-02"
authors:
  - "Firefly project contributors"
published: 2024
citation_key: "getfirefly-2024-firefly"
container: "Archived Firefly source repository"
edition: null
isbn: null
doi: null
url: "https://github.com/GetFirefly/firefly"
accessed: "2026-09-02"
tags:
  - beam
  - compilers
  - elixir
  - firefly
  - webassembly
aliases:
  - "Firefly compiler"
  - "Lumen compiler"
---

# Firefly alternative BEAM compiler and WebAssembly target

## Reference

Firefly project contributors. [Firefly: An alternative BEAM implementation,
designed for WebAssembly](https://github.com/GetFirefly/firefly). Repository
archived 2024-06-10. Accessed 2026-09-02.

## Research question or contribution

Firefly pursued a compiler and Rust runtime for Erlang/Elixir with native
targets including WebAssembly. It is the closest historical effort to general
Elixir AOT for Wasm.

## Findings

- The compiler lowered Erlang through Core-, Kernel-, SSA-, and lower-level IR
  stages into LLVM-oriented code generation.
- The runtime aimed to implement scheduler, processes, asynchronous I/O, and
  selected OTP behavior without being ERTS.
- WebAssembly and standalone executables were first-class goals.
- Hot code loading was explicitly not a goal, and complete OTP parity remained
  aspirational.
- The project was experimental and its repository was archived in 2024.

## Relevance

Firefly demonstrates both the appeal and scale of a general AOT path. Its
archived status makes it unsuitable as BlazeX's initial foundation and
supports using AtomVM/Popcorn rather than restarting a compiler/runtime effort.

## Limits

The repository's design goals are not evidence of completed compatibility or
production performance. No archived build was attempted.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Elixir WebAssembly components map](../10-maps/elixir-webassembly-components.md)
