---
title: "LocalLiveView 0.1.0 first release and implementation"
kind: source
created: "2026-09-02"
authors:
  - "Software Mansion"
  - "Mateusz Front"
published: "2026-08-24"
citation_key: "software-mansion-2026-local-live-view"
container: "Software Mansion blog, Hex package, and source repository"
edition: "0.1.0"
isbn: null
doi: null
url: "https://swmansion.com/blog/local-live-view-first-release/"
accessed: "2026-09-02"
tags:
  - atom-vm
  - elixir
  - liveview
  - phoenix
  - webassembly
aliases:
  - "Local LiveView first release"
---

# LocalLiveView 0.1.0 first release and implementation

## Reference

Mateusz Front and Software Mansion. [“The first release of Local
LiveView!”](https://swmansion.com/blog/local-live-view-first-release/), 2026-08-24.
The review also used the [LocalLiveView source
tree](https://github.com/software-mansion/popcorn/tree/main/local-live-view),
[Hex 0.1.0 metadata](https://hex.pm/packages/local_live_view/0.1.0), package
guides, and extracted package source.

## Research question or contribution

LocalLiveView is a direct implementation of browser-local, Elixir-authored
LiveView-style components. It tests whether the existing LiveView API, HEEx
rendering, and DOM client can be reused with state executing in Popcorn rather
than on the Phoenix server.

## Method

The release post and guides were compared with package modules for the local
application, dispatcher, server/diff handling, host component, channel/mirror
integration, generated installation files, bundled JavaScript, and the
packaged navigation guide.

## Findings

- A server LiveView can render a `<.local_live_view>` host element naming a
  local view module and initial assigns.
- One shared Popcorn/AtomVM runtime serves multiple local views. Each local
  view is represented by an Elixir process managed under a supervisor and
  addressed through a dispatcher.
- Local modules use familiar `mount`, `render`, `handle_event`, `update`, and
  `handle_info` patterns and can render LiveComponents/function components.
- The implementation reuses private LiveView modules including diff,
  lifecycle, renderer, and utility code inside AtomVM.
- Browser JavaScript provides a fake/socket-shaped transport so the stock
  LiveView client can consume locally produced join/event/diff messages and
  apply its normal DOM patches.
- Event ownership is adapted so events beneath a local-view root reach the
  local transport instead of a server LiveView.
- Patch navigation is implemented in hosted and standalone modes. The hosted
  path coordinates browser history with Phoenix and consumes `phx:navigate`;
  the standalone path handles patch-link clicks and `popstate` directly.
  `handle_params/3` and `push_patch/2` run the state update inside AtomVM.
- Form event payloads are URL-decoded in the local server and preserve the
  nested `_target` path used by LiveView forms.
- Component deletion messages prune removed nested LiveComponent state from
  the local renderer. The package search did not find a corresponding
  LocalLiveView upload pipeline such as `allow_upload` or
  `consume_uploaded_entries`.
- `push_server_event` performs optimistic local work and then forwards a
  server event through a host bridge. Mirror sync uses a Phoenix Channel and a
  signed mirror token to synchronize selected JSON-compatible assigns.
- Local client code lives in a separate `local/` Mix project, reducing the
  chance of accidentally bundling server-only modules or secrets.
- The first-party release post reports an experimental tree-shaken Kanban demo
  at approximately 1.8 MB for all compressed assets, a fourfold reduction.
- Removing private LiveView API dependencies and adding server-side rendering
  are explicitly listed as future work.

## Relevance

The project validates BlazeX's central runtime/render loop and strongly favors
adoption, hardening, and upstream collaboration over building a parallel VM
and renderer. It also identifies the most urgent framework work: stable public
boundaries, compatibility, SSR, packaging, diagnostics, and a host-neutral
server-command contract.

## Limits

Version 0.1.0 was released only days before this review. The blog's size result
was not reproduced end to end. Private API dependence, no completed SSR,
Popcorn's runtime restrictions, and cross-origin isolation make this evidence
appropriate for a prototype recommendation, not a production guarantee.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Blazor framework semantics study](../20-notes/blazor-framework-semantics-beneath-blazex.md)
- [BlazeX feasibility inquiry](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md)
- [Local package audit journal](../50-journal/2026-09-02-elixir-webassembly-components-deep-dive.md)
- [Component semantics audit journal](../50-journal/2026-09-02-blazor-component-semantics-deep-dive.md)
