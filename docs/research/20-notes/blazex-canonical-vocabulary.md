---
title: "BlazeX canonical vocabulary"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - architecture
  - bh-00
  - host-abstraction
  - terminology
aliases:
  - "BlazeX glossary"
  - "BH-00 canonical terms"
---

# BlazeX canonical vocabulary

## Status and use

This note is the BH-00 canonical vocabulary for BlazeX architecture, product,
catalog, planning, and support records. Later documents may define narrower
terms, but they must not silently assign a different meaning to a term here.
Source notes may preserve an upstream project's wording when the source context
is explicit.

When a word is overloaded in the wider ecosystem, BlazeX documentation must use
the qualified form from this note. In particular, *host*, *component*,
*backend*, and *supported* are never inferred from context when the distinction
changes an architecture or product claim.

## Independent architecture dimensions

These dimensions compose independently. No row is shorthand for another row.

| Dimension | Canonical meaning | Examples | It is not |
| --- | --- | --- | --- |
| Runtime substrate | The engine that executes BEAM bytecode or native Wasm instructions and supplies its language-level process/runtime facilities. | ERTS/BEAM, native AtomVM, AtomVM compiled to Wasm, a restricted native-Wasm runtime | browser, Phoenix, DOM, native widget toolkit |
| Execution host | The process or environment that instantiates a runtime, schedules it, and grants external capabilities. | browser page/worker, desktop native process, system WebView shell, standalone Wasm runtime, server process, test process | runtime substrate, renderer, server adapter |
| Renderer backend | The implementation that materializes semantic UI, routes normalized user events, and owns renderer resources. | standalone DOM, LiveView DOM adapter, native widgets, custom scene, headless trace | component kernel, capability provider, Phoenix |
| Capability provider | The host-side implementation of named effects and resources granted to a component root. | Web APIs, desktop OS services, toolkit services, WASI imports, test doubles | ambient global access, renderer contract, authorization policy |
| Server/remote adapter | The integration that carries untrusted public data and typed commands across a trust boundary to authoritative application services. | Phoenix adapter, Plug adapter, application transport, local-only adapter | execution host, local component event loop, renderer |
| Packaging shell | The deployment container that assembles artifacts, startup policy, permissions, updates, windows/pages, and distribution metadata. | web deployment, Tauri-like shell, native application bundle, standalone runtime package | component API, renderer protocol, runtime substrate |
| Executable profile | A supported composition selecting one runtime, host, renderer, capability provider, server adapter, build policy, and shell. | browser/Phoenix, browser/Plug, headless, future desktop WebView, future native desktop | reusable package, universal framework root |
| Portable component contract | The host-neutral lifecycle, state, semantic UI, event, effect, resource, accessibility, and disposal contract authored by applications and component libraries. | `blazex_core`, `blazex_effects`, `blazex_ui_tree` contracts | HEEx, HTML, DOM events, JavaScript handles, Popcorn API, Phoenix socket, native toolkit class |

### Composition examples

| Profile example | Runtime | Host | Renderer | Capability provider | Server adapter | Shell |
| --- | --- | --- | --- | --- | --- | --- |
| Browser/Phoenix | AtomVM-in-Wasm through Popcorn | browser | standalone DOM plus optional LiveView DOM adapter | browser Web APIs | Phoenix | web deployment |
| Browser/Plug | AtomVM-in-Wasm through Popcorn | browser | standalone DOM only | browser Web APIs | Plug | web deployment |
| Headless | ERTS, AtomVM, or another tested runtime | test or build process | normalized semantic trace | deterministic test doubles | none or test adapter | CLI/CI process |
| Desktop WebView, future | browser AtomVM build or another selected runtime | desktop process plus system WebView | standalone DOM | browser APIs plus explicit desktop grants | Phoenix, Plug, another transport, or none | desktop WebView bundle |
| Native desktop, future | ERTS, native AtomVM, or embedded Wasm runtime | native desktop process | platform/toolkit native controls | OS and toolkit services | Phoenix, Plug, another transport, or none | native application bundle |
| Standalone Wasm, future | AtomVM-in-Wasm or restricted native Wasm | Wasmtime-like or custom embedding | headless, native protocol, or custom scene | explicit host imports/WASI where suitable | optional | standalone runtime package |

These examples describe legal compositions, not current support. Only a
versioned profile with its required evidence can claim support.

## Forbidden architecture equivalences

The following substitutions are invalid:

- Phoenix or Plug is not the execution host; each is a server integration.
- Popcorn is not the component model; it is part of one browser runtime and
  tooling path.
- AtomVM is not a browser or desktop UI host; it is a runtime substrate.
- Wasmtime and Wasmex do not provide a renderer or native widgets by
  themselves.
- LiveView render data is not the portable semantic UI representation.
- The DOM renderer is not the renderer contract; it implements that contract.
- A browser capability provider is not the component kernel.
- A profile is not a package and must not own reusable framework semantics.
- A WebView is not a native-control renderer.
- WASI is not a portable native-widget standard.
- The WebAssembly Component Model is not the BlazeX UI component abstraction.
- Client-side Elixir or Wasm state is not trusted server state.

## Product and framework terms

| Term | Canonical BlazeX meaning |
| --- | --- |
| UI component | A reusable Elixir-authored state, lifecycle, semantic-rendering, event, and effect abstraction. Unqualified *component* in BlazeX product records means this definition. |
| Component family | A catalog grouping with shared product intent and semantics, possibly represented by multiple public components, parts, providers, or supporting types. |
| Component kernel | The smallest host-neutral lifecycle, identity, state, semantic event, effect, and evaluation contracts on which component libraries depend. |
| Semantic UI tree | A versioned renderer-neutral representation of UI intent, layout, tokens, accessibility, identities, and opaque resource references. It is not HTML or a native widget tree. |
| Semantic node | One typed element of the semantic UI tree. A node names intent and renderer requirements, not a required DOM tag or toolkit class. |
| Local event | A normalized, untrusted interaction delivered to the owning component identity within the local component runtime. |
| Remote command | A typed request crossing a server/remote adapter for authentication, validation, authorization, execution, auditing, and a typed result. |
| Effect | A host-neutral request for an operation outside pure component evaluation, including ownership, cancellation, timeout, fallback, and disposal semantics. |
| Capability | A named operation or semantic facility a renderer, host, application policy, or server adapter may provide. Availability is negotiated; it is not ambient authority. |
| Resource | An opaque, generation-scoped identity for host- or renderer-owned state. Portable component state never contains the underlying DOM, JavaScript, OS, file, or toolkit object. |
| Renderer capability | A semantic node, property, layout, accessibility, drawing, focus, or materialization facility supported by a renderer backend. |
| Host capability | An effect or resource facility supplied by the execution host under application policy. |
| Adapter | A reusable package mapping a BlazeX protocol onto one concrete runtime, renderer, host, server framework, or transport. |
| Integration | The documented composition between BlazeX and another framework or system. An integration does not make that system the BlazeX kernel. |
| Backend | A qualified implementation endpoint. Use *renderer backend*, *storage backend*, or another explicit noun; unqualified *backend* is ambiguous. |
| Fallback | A declared alternative result or interaction selected when a mode or capability is unavailable. Silent partial behavior is not a fallback. |
| Visual profile | A named appearance policy such as platform-native, BlazeX Material, or hybrid. Visual profiles may differ while observable semantic contracts remain shared. |
| Portable | Implementable through the declared semantic contracts without importing one host, renderer, runtime, server framework, or toolkit's object types. Portable does not mean already supported everywhere. |
| Renderer-specific | Intentionally dependent on one renderer class or a namespaced extension, with explicit metadata and fallback or unsupported behavior. |
| Host-specific | Intentionally dependent on one execution-host capability or policy, represented through declared effects rather than ambient APIs. |
| Supported | Covered by a versioned profile, compatibility policy, and current required evidence. *Planned*, *implemented*, *demonstrated*, and *supported* are distinct states. |

## Rendering and execution-mode terms

| Term | Canonical meaning |
| --- | --- |
| Static fallback | Bounded noninteractive output available without the claimed interactive runtime or capability. |
| Server-rendered output | UI materialized by server execution and delivered to the client; it does not imply later local activation. |
| Prerendered output | Initial server/static output intentionally paired with a compatible later interactive mode and public activation state. |
| Browser-local interactive | Eligible component logic executes in the browser runtime and drives a browser renderer without requiring a round trip for local events. |
| Activated | A local interactive root has attached to compatible prerendered output with matched identity, build, public state, effect suppression, and mismatch policy. |
| Headless | Component evaluation is observed through a normalized tree/event/effect trace without visual materialization. |
| Local | Inside the selected component runtime and trust domain. Local does not mean trusted or persisted. |
| Remote | Across a server/remote adapter or other explicit transport boundary. |
| Browser host | The browser as an execution host. Do not use this phrase for Phoenix, Plug, LiveView, Popcorn, or a Web server. |
| Browser profile | The complete supported composition that runs with the browser as execution host. |

## WebAssembly terms

| Term | Canonical meaning |
| --- | --- |
| Core Wasm module | A WebAssembly binary using Core WebAssembly instructions, imports, exports, memories, and tables. |
| AtomVM-in-Wasm | AtomVM compiled to a Core Wasm module and used to execute BEAM/AVM code; this is runtime-in-Wasm, not application AOT-to-Wasm. |
| Native Wasm application | Application logic compiled to native WebAssembly instructions without a BEAM bytecode runtime. This is a separate compilation target. |
| Wasm component | Only a WebAssembly Component Model binary with WIT/Canonical ABI imports and exports. Use this qualified term rather than *component* when that standard is meant. |
| WebAssembly Component Model | A standards-level typed binary composition model. It may later encode host interfaces but supplies neither BlazeX lifecycle semantics nor a UI renderer. |
| WIT | The interface language used by the WebAssembly Component Model. WIT is not the BlazeX semantic UI schema. |

## Usage examples and anti-examples

Preferred:

- “The browser/Phoenix profile uses the browser execution host, Popcorn runtime
  adapter, standalone DOM renderer, optional LiveView DOM adapter, browser
  capability provider, and Phoenix server adapter.”
- “The Plug server integration serves assets and typed HTTP commands; the
  browser/Plug profile still uses the standalone DOM renderer.”
- “This family is portable-with-capabilities and currently evidenced only on
  the DOM renderer.”
- “A future Wasm component could expose a typed plugin ABI, but BlazeX UI
  components continue to use the semantic component contract.”

Avoid:

- “Phoenix is the BlazeX host.”
- “Popcorn components are the BlazeX component model.”
- “The LiveView diff is the BlazeX render tree.”
- “The component works natively” when only headless and DOM evidence exists.
- “Works with Plug” when the dependency graph still includes LiveView.
- “Supported” when the only evidence is a local demonstration or a completed
  planning checklist.

## Corpus terminology audit

The Section 1.1 audit covers current synthesis, inquiries, maps, plans, package
and profile boundary documents. Source notes retain upstream terms where their
subject is explicit. The audit made these current-truth corrections:

| Previous wording | Canonical wording | Reason |
| --- | --- | --- |
| Plug host | Plug server integration | Plug does not instantiate the browser runtime or render UI. |
| Phoenix or Plug host in the architecture diagram | Server/remote adapter | The browser is the execution host in that profile. |
| Browser + Plug described as a smaller browser host | Smaller browser profile | The profile is a composition; the browser is its host. |
| Build package becoming a runtime host | Build package acquiring execution-host behavior | *Runtime host* collapsed runtime and host responsibilities. |
| Browser runtime host milestone | Browser execution-host and runtime boot milestone | The milestone covers both the browser host and runtime adapter lifecycle. |
| JavaScript islands hosted by Phoenix | JavaScript islands integrated with Phoenix | Phoenix supplies server integration, not JavaScript execution. |

Accepted contextual uses include *host function*, *host capability*, *browser
host*, and upstream phrases such as Blazor's *hosting model*. Qualified
*component model* means the BlazeX UI component contract unless *WebAssembly
Component Model* or another project's model is named explicitly.

## Connections

- [Host-neutral BlazeX architecture and native control backends](host-neutral-blazex-architecture-and-native-control-backends.md) — supplies the decomposition formalized here.
- [Browser host implementation milestones](browser-host-implementation-milestones.md) — uses these terms for BH-00 through BH-23.
- [Elixir WebAssembly component framework for Phoenix and Plug](elixir-webassembly-component-framework-for-phoenix-and-plug.md) — distinguishes UI components, runtime-in-Wasm, AOT Wasm, and Wasm components.
- [Host-neutral and native-renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md) — provides the curated architecture route.

## Sources

- [WebAssembly Component Model and Jco browser tooling](../30-sources/bytecode-alliance-2026-webassembly-component-model-and-jco.md)
- [Popcorn documentation and source](../30-sources/software-mansion-2026-popcorn-documentation-and-source.md)
- [Phoenix 1.8 documentation](../30-sources/phoenix-framework-2026-phoenix-1-8-documentation.md)
- [Plug 1.20 documentation](../30-sources/elixir-plug-team-2026-plug-1-20-documentation.md)
