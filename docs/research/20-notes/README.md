---
title: "Notes"
kind: map
created: "2026-09-02"
tags:
  - archive-navigation
  - directory-index
aliases:
  - "Notes index"
---

# Notes (`20-notes`)

## Purpose

Notes preserve ideas, arguments, models, and syntheses in the author's own
words.

## What belongs here

Put independently useful conclusions and developing interpretations here.
Source summaries belong in `30-sources`; unresolved workbenches belong in
`40-inquiries`.

## Index

### Subdirectories

- [Architecture decisions](architecture-decisions/README.md) — permanent,
  impact-reviewed ADRs governing BlazeX product and implementation boundaries.

### Documents

- [BlazeX browser and toolchain support policy](blazex-browser-and-toolchain-support-policy.md) — defines the BH-00 candidate browser windows, evidence classes, support and toolchain states, review cadence, and BH-01 records without claiming a working or supported stack.
- [BlazeX browser rendering and profile modes](blazex-browser-rendering-and-profile-modes.md) — fixes the six output/activation contracts, three independent profile compositions, adapter ownership, capability matrix, and Plug transitive-dependency gate.
- [BlazeX canonical vocabulary](blazex-canonical-vocabulary.md) — freezes the
  BH-00 meanings of runtime, host, renderer, capabilities, adapters, profiles,
  components, rendering modes, and WebAssembly terms, including forbidden
  equivalences and usage examples.
- [Browser host implementation milestones](browser-host-implementation-milestones.md) — consolidates the runtime, renderer, Phoenix/Plug, MudBlazor-inspired
  catalog, resilience, activation, packaging, quality, and release work into
  24 outcome-based milestones for the first production host.
- [Blazor framework semantics beneath BlazeX](blazor-framework-semantics-beneath-blazex.md) — uses Blazor's framework APIs as lower-level design research for
  rendering, identity, forms, lifecycle, effects, and host services; it is not
  the target visual library and defines no .NET compatibility.
- [Elixir WebAssembly component framework for Phoenix and Plug](elixir-webassembly-component-framework-for-phoenix-and-plug.md) — provides the
  full Blazor and Phoenix architecture study, evaluates current Elixir/Wasm
  paths, and develops the recommended BlazeX architecture and roadmap.
- [Host-neutral BlazeX architecture and native control backends](host-neutral-blazex-architecture-and-native-control-backends.md) — separates runtime,
  execution host, renderer, capabilities, and remote adapters; defines the
  semantic UI ABI and preserves fully native controls as an early design goal.
- [MudBlazor-inspired component system for BlazeX](mudblazor-inspired-component-system-for-blazex.md) — establishes MudBlazor v9.9.0 as the target
  catalog and UX reference, audits all 83 source families, and defines native
  Elixir/Phoenix architecture, package boundaries, and F0–F4 delivery tiers.

## Maintaining this index

Index every direct note and describe its claim or role. Keep maturity values
honest and connect each note to evidence, related notes, or a map.
