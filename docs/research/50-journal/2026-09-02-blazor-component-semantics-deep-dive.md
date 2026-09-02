---
title: "2026-09-02 Blazor component semantics deep dive"
kind: journal
created: "2026-09-02"
tags:
  - blazor
  - design-analysis
  - components
  - package-audit
  - research-session
aliases:
  - "BlazeX component semantics research session"
---

# 2026-09-02 Blazor component semantics deep dive

## Observations

- The user-intended “component” is a Razor/Blazor UI component, not a
  WebAssembly Component Model artifact.
- The product direction is a native Elixir/Phoenix system. Blazor is a source
  of design lessons and problem inventory only; .NET compatibility is not a
  goal at any level.
- Blazor's first-party component surface is mostly framework infrastructure:
  composition, forms, routing, authorization-aware presentation, error
  handling, head/layout coordination, virtualization, and QuickGrid. It is not
  a complete styled widget system.
- Phoenix has close semantic matches for attributes, slots, dynamic/stateful
  components, forms, live navigation, title updates, uploads, hooks, and
  server-side security, but many are server-hosted contracts.
- LocalLiveView 0.1.0 contains more relevant component behavior than the initial
  architecture summary recorded: its package includes hosted and standalone
  patch navigation, `handle_params/3`, `push_patch/2`, form payload decoding,
  nested component deletion bookkeeping, and custom browser event bindings.
- Reuse of LiveView internals is strong evidence for a prototype but does not
  make every public Phoenix.LiveView feature a supported LocalLiveView API.
- No local-specific file upload path, general named section/head manager,
  authentication state provider, true virtualizer, or subtree error boundary
  was found by the targeted package search.
- The design recommendation therefore labels evidence as documented,
  observed, inferred, or proposed instead of collapsing all four into
  “supported.”

## Environment

- Workspace: `/home/ducky/code/blazex` on Linux x86-64.
- Research date: 2026-09-02.
- Documentation baselines:
  - ASP.NET Core / Blazor .NET 10;
  - Phoenix 1.8 and Phoenix LiveView 1.2.11;
  - LocalLiveView 0.1.0;
  - Popcorn 0.3.3.
- Existing package extractions:
  - `/tmp/local_live_view_research`;
  - `/tmp/popcorn_research`.
- Browser component behavior was not executed or benchmarked in this pass.

## Evidence

### First-party source inventory

The Blazor review used the .NET 10 public API namespace catalogs and Microsoft
documentation for components, lifecycle, dynamic and templated components,
cascading values, binding, forms, routing, authorization, sections, head
content, error boundaries, virtualization, QuickGrid, CSS isolation, and
JavaScript collocation.

The Phoenix review used LiveView 1.2.11 documentation for
`Phoenix.Component`, `Phoenix.LiveComponent`, forms, uploads, navigation,
layouts, bindings, JavaScript interoperability, security, and router live
sessions. Search was used to locate first-party pages; detailed claims were
derived from the opened documentation and package source rather than search
snippets.

The grouped source records are indexed in
[`30-sources`](../30-sources/README.md).

### LocalLiveView package inspection

The package archive and checksum were already preserved in the parent research
session. Relevant files for this component-semantics pass included:

```text
pages/guides/navigation.md
lib/local_live_view/local_live_view.ex
lib/local_live_view/server.ex
lib/local_live_view/dispatcher.ex
lib/server/router.ex
priv/static/local_live_view.js
```

Targeted searches covered:

```text
allow_upload consume_uploaded upload live_file_input
Form form phx-change
on_mount attach_hook handle_async assign_async
stream live_title page_title
push_event js_push phx-hook colocated
redirect push_navigate push_patch handle_params terminate
```

Observed results:

- `LocalLiveView` documents and implements `mount/3`, `update/2`,
  `handle_params/3`, `render/1`, `handle_event/3`, `handle_info/2`,
  `push_patch/2`, `push_server_event/3`, and mirror synchronization.
- A `LocalLiveView.Server` GenServer exists per mounted local view under a
  dynamic supervisor.
- The server uses LiveView lifecycle, renderer, diff, session, and component
  internals; it tracks fingerprints and component state.
- Event decoding contains a form path that decodes URL-encoded params and
  reconstructs `_target` key paths.
- Component removal handles `cids_will_destroy` and `cids_destroyed`, pruning
  renderer component state.
- Navigation code distinguishes a connected Phoenix-owned history path from a
  standalone path. It handles patch clicks, `popstate`, local navigation
  events, Phoenix navigation events, and duplicate suppression.
- The JavaScript bridge comments and code indicate that hooks below a local
  root continue through the LiveView client path.
- No occurrence of `allow_upload`, `consume_uploaded_entries`, or
  `live_file_input` was found in LocalLiveView's Elixir/runtime implementation.
  Rendering a file element alone does not provide a file-selection and upload
  workflow.

### Classification method

Each API family was assessed along five axes: authoring intent, Phoenix server
analogue, LocalLiveView evidence, trust boundary, and BlazeX product
disposition. The synthesis uses `Reuse`, `Adapt`, `Build`, `Diverge`, and
`Defer`, plus P0–P3 priorities.

The inventory deliberately separates:

- actual framework component classes;
- Razor language/directive contracts;
- build and package behavior;
- project-template components;
- third-party visual components.

### What was not demonstrated

- No Blazor or Phoenix reference application was generated.
- No component ran in a browser AtomVM during this pass.
- No form, file, focus, navigation, hook, stream, or virtualizer test was run.
- No accessibility tool or screen reader was exercised.
- No QuickGrid benchmark or Phoenix grid comparison was run.
- No exact incremental bundle-size attribution by proposed BlazeX package exists.
- No Plug-only component transport was implemented.
- No SSR/activation or persisted component state was demonstrated.

## Threads

- [Component semantics synthesis](../20-notes/blazor-framework-semantics-beneath-blazex.md)
  contains the complete matrix and recommendation.
- [Component semantics inquiry](../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
  defines the next executable evidence.
- [Component semantics map](../10-maps/blazor-framework-semantics.md)
  organizes the evidence trail.
- [Parent BlazeX architecture](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
  defines the runtime and host model this profile assumes.

## Follow-ups

- Convert the prose P0 matrix into a checked-in machine-readable manifest.
- Generate a pinned reference application and run the same fixtures under
  Phoenix LiveView and LocalLiveView.
- Start with props/slots/dynamic identity and a difficult form, not a counter.
- Record deterministic callback/removal traces and stale-generation behavior.
- Prototype focus/measurement effects and prove disposal after root removal.
- Test title and colocated hooks in hosted and standalone local modes.
- Evaluate Phoenix upload reuse versus a separate BlazeX uploader.
- Measure package-by-package compressed payload and cold/warm startup.
