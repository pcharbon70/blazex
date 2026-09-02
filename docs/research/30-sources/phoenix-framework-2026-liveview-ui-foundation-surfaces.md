---
title: "Phoenix LiveView 1.2 UI foundation surfaces"
kind: source
created: "2026-09-02"
authors:
  - "Phoenix LiveView contributors"
published: 2026
citation_key: "phoenix-2026-liveview-ui-foundations"
container: "Phoenix LiveView v1.2.11 documentation"
edition: "1.2.11"
isbn: null
doi: null
url: "https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html"
accessed: "2026-09-02"
tags:
  - components
  - forms
  - liveview
  - navigation
  - phoenix
aliases:
  - "Phoenix UI foundation catalog"
---

# Phoenix LiveView 1.2 UI foundation surfaces

## Reference

Phoenix LiveView contributors. Phoenix LiveView v1.2.11 documentation.
Accessed 2026-09-02. Principal references:

- [`Phoenix.Component`](https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html)
- [`Phoenix.LiveComponent`](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html)
- [`Phoenix.LiveView`](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html)
- [form bindings](https://phoenix-live-view.hexdocs.pm/form-bindings.html)
- [uploads](https://phoenix-live-view.hexdocs.pm/uploads.html)
- [live navigation](https://phoenix-live-view.hexdocs.pm/live-navigation.html)
- [live layouts](https://phoenix-live-view.hexdocs.pm/live-layouts.html)
- [bindings and viewport events](https://phoenix-live-view.hexdocs.pm/bindings.html)
- [JavaScript interoperability](https://phoenix-live-view.hexdocs.pm/js-interop.html)
- [security considerations](https://phoenix-live-view.hexdocs.pm/security-model.html)
- [`Phoenix.LiveView.Router`](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.Router.html)

## Research question or contribution

These pages define the Phoenix and LiveView primitives that can satisfy the
developer intent of Blazor's built-ins without copying C# APIs.

## Findings

- Function components accept declared `attr` inputs and named or default
  `slot` content. Slot renderers can receive an argument, providing the same
  basic composition power as contextual render fragments. `:global`
  attributes provide controlled attribute forwarding.
- Dynamic function dispatch is possible through `apply/3`, and stateful
  components are rendered with `live_component`. Dynamic dispatch weakens
  compile-time attribute/slot validation and therefore benefits from a bounded
  common contract.
- A LiveComponent is identified by module and ID, owns lifecycle/state, and
  executes inside its parent LiveView process. It does not inherit the parent
  socket's assigns. A nested LiveView is a separate process and failure domain.
- HEEx supports keyed comprehensions in LiveView 1.2. Streams have their own
  DOM identity and bounded collection operations.
- `Phoenix.Component.form` and `to_form` support plain params and changesets.
  Input controls such as the generated `.input` are application code from
  `mix phx.new`, not a stable set of framework-owned typed input components.
- LiveView form events carry current form values, track whether fields have
  been used, preserve focused client input during patches, and can recover
  forms after reconnect. File uploads provide validation, progress,
  cancellation, server streaming, and external uploader hooks.
- Live navigation uses the host router and browser history. `patch` reruns
  `handle_params` within the current LiveView; `navigate` mounts another
  LiveView in the same live session; crossing boundaries falls back to a full
  request.
- Root and app layouts are distinct. The root layout does not dynamically
  patch during live navigation. `@page_title` and `live_title` are the special
  supported title-update path.
- `phx-viewport-top` and `phx-viewport-bottom` can combine with streams for a
  bounded infinite-scrolling DOM, but this is not the same contract as a
  measurement-driven arbitrary-item virtualizer.
- Client hooks, colocated hooks/JavaScript, and `Phoenix.LiveView.JS` provide
  DOM effects and browser interoperation. Colocated code is extracted at
  compile time into the JavaScript build.
- Authentication is normally established through Plug/session handling and
  repeated for the connected LiveView through `on_mount`. Authorization must
  also run for route parameters and every protected event; hiding UI is not a
  security boundary.

## Relevance

Phoenix already supplies most of the high-value foundation for BlazeX: props,
slots, component identity, forms, router coordination, uploads, title updates,
event schemas, JavaScript hooks, and server-enforced security. The gaps are
well bounded: ambient context, a framework-owned typed input catalog,
arbitrary head/section outlets, local browser routing, subtree error
boundaries, and true viewport virtualization.

## Limits

The documentation primarily describes server-resident LiveView. A feature in
Phoenix LiveView is not automatically supported by LocalLiveView or AtomVM.
The design study separately labels direct LocalLiveView source evidence,
inferences from reuse of LiveView internals, and untested proposals.

## Derived work

- [Blazor framework semantics beneath BlazeX](../20-notes/blazor-framework-semantics-beneath-blazex.md)
- [BlazeX component semantics inquiry](../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
- [Component-semantics deep-dive journal](../50-journal/2026-09-02-blazor-component-semantics-deep-dive.md)
