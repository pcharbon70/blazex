---
title: "BlazeX repository ownership and dependency map"
kind: map
created: "2026-09-02"
tags:
  - architecture
  - bh-00
  - dependency-management
  - monorepo
  - ownership
aliases:
  - "BlazeX package ownership map"
  - "BH-00 dependency map"
---

# BlazeX repository ownership and dependency map

## Scope

This map assigns every current BlazeX package, profile, browser bridge,
integration suite, and experiment one primary responsibility and defines the
allowed dependency direction among them. It is the BH-00 current-truth ownership
map; directory READMEs remain the local boundary documents.

The map describes intended projects before their Mix or JavaScript scaffolds
exist. A directory appearing here does not mean it is implemented, supported,
published, or part of every executable profile.

## Dependency rule

Dependencies point inward toward host-neutral contracts and outward toward
concrete adapters only at composition time:

```text
profiles
  -> component libraries + selected runtime/host/renderer/server adapters
  -> adapter contracts and host-neutral foundation
  -> core lifecycle and semantic identities
```

An outer package may depend on an inner contract. An inner package must not
depend on an outer implementation. Runtime, host, renderer, capability provider,
server adapter, and packaging shell remain independent selections.

## Current package ownership

The package inventory contains exactly eighteen intended package boundaries.

| Package | Primary ownership | May depend inward on | Forbidden ownership or dependencies |
| --- | --- | --- | --- |
| `blazex_core` | component behavior, lifecycle, identity, state, semantic events, local messages, typed command contracts | Elixir/OTP subset declared by its runtime compatibility policy | Phoenix, Plug, DOM, JavaScript, Popcorn, concrete renderer, native toolkit |
| `blazex_effects` | host-neutral effects, capabilities, grants, opaque resources, ownership, cancellation, timeout, fallback, disposal | `blazex_core` | Web APIs, DOM handles, Phoenix sockets, OS/file/toolkit objects |
| `blazex_ui_tree` | versioned semantic nodes, layout intent, tokens, accessibility, identities, diffs, opaque resource references | `blazex_core` | HTML/HEEx as canonical output, CSS-only state, renderer implementations |
| `blazex_renderer` | renderer behavior, capability negotiation, generations, materialized-resource lifecycle, diagnostics | `blazex_core`, `blazex_effects`, `blazex_ui_tree` | concrete DOM/native/headless code, Phoenix, Plug |
| `blazex_renderer_headless` | deterministic normalized tree, accessibility, event/effect trace, renderer oracle | `blazex_renderer`, `blazex_core`, `blazex_effects`, `blazex_ui_tree` | browser, Phoenix, Plug, native toolkit |
| `blazex_build` | client entrypoints, reachability, compatibility, bundles, manifests, assets, provenance, diagnostics | host-neutral metadata and declared adapter build contracts | execution-host behavior, component state, server-framework behavior |
| `blazex_test` | reusable cross-runtime, cross-renderer, capability, component, and profile test harnesses | any public contract needed by test consumers as development/test dependencies | production runtime ownership, assumptions that only one profile exists |
| `blazex_ui` | design foundation, themes, icons, layout, navigation, presentational and action families | `blazex_core`, `blazex_effects`, `blazex_ui_tree` | concrete renderer, direct host APIs, Phoenix, Plug, Popcorn |
| `blazex_forms` | portable form/field state, conversion, validation, errors, inputs, selection semantics | `blazex_core`, `blazex_effects`, `blazex_ui_tree`, selected `blazex_ui` foundations | Phoenix changesets as canonical state, DOM input objects, server authority in client state |
| `blazex_surfaces` | portable overlay, menu, popover, dialog, drawer, snackbar, placement/focus semantics | `blazex_core`, `blazex_effects`, `blazex_ui_tree`, selected `blazex_ui` foundations | DOM portals, browser globals, toolkit windows as canonical state |
| `blazex_data` | provider contracts, lists, tables, grids, trees, paging, sorting, filtering, virtualization | `blazex_core`, `blazex_effects`, `blazex_ui_tree`, selected UI/form foundations | direct server queries, renderer calls, Phoenix authorization assumptions |
| `blazex_charts` | optional chart data, interaction, accessibility and renderer requirement contracts | `blazex_core`, `blazex_effects`, `blazex_ui_tree`, selected UI/surface foundations | SVG, canvas, DOM, or one native scene API as canonical state |
| `blazex_runtime_popcorn` | Popcorn/AtomVM browser boot, process/runtime integration, bundle loading, host imports, failure isolation | runtime-facing `blazex_core` contracts and `blazex_build` artifacts | component catalog policy, renderer selection, Phoenix ownership |
| `blazex_host_browser` | browser execution-host lifecycle and concrete Web API capability provider | `blazex_core`, `blazex_effects`, runtime host contracts | portable component logic, Phoenix/Plug requirement, server authorization |
| `blazex_renderer_dom` | server-framework-independent DOM operations, reconciliation, ARIA, focus, normalized browser events | `blazex_renderer`, `blazex_core`, `blazex_effects`, `blazex_ui_tree` | Phoenix, Plug, LiveView, LocalLiveView |
| `blazex_renderer_dom_liveview` | optional LiveView/LocalLiveView render-data, patch, transport, and version adapter | `blazex_renderer_dom`, `blazex_renderer`, public LiveView/LocalLiveView dependencies selected by policy | portable component ownership, inclusion in browser/Plug, native-renderer contract |
| `blazex_phoenix` | Phoenix assets/bootstrap, sessions, trusted commands, pushes, uploads, routing, telemetry, optional SSR coordination | host-neutral public contracts, `blazex_build`, optional `blazex_renderer_dom_liveview` coordination | component kernel ownership, standalone DOM ownership, client trust |
| `blazex_plug` | Plug static/bootstrap/HTTP command baseline and host-provided security hooks | host-neutral public contracts and `blazex_build` | Phoenix, LiveView, LocalLiveView, `blazex_renderer_dom_liveview` directly or transitively |

### Package class rules

1. Component-family packages depend on host-neutral contracts, never on a
   concrete runtime, host, renderer, or server adapter.
2. Renderer implementations depend on `blazex_renderer` and semantic contracts;
   only the named LiveView adapter may depend on LiveView/LocalLiveView.
3. Runtime adapters execute component code but do not select component catalog
   policy or renderer behavior.
4. Host adapters implement effects and lifecycle but do not grant server trust.
5. Server adapters validate remote commands but do not own local events or
   portable state.
6. Build and test packages may inspect broad public metadata, but their
   dependencies must not leak into production runtime graphs.

## Browser JavaScript ownership

| Directory | Primary ownership | Forbidden ownership |
| --- | --- | --- |
| `js/blazex_runtime` | narrow Wasm loader, host imports, event routing, transport attachment, privileged browser effects, diagnostics, fallback presentation | component state machine, public component API, general renderer semantics, server authorization |

JavaScript is a browser bridge, not a second framework. The bridge implements
declared contracts and may not become the only source of a portable behavior.

## Executable profile ownership

| Profile | Required composition | Explicit exclusions | Profile-owned concerns |
| --- | --- | --- | --- |
| `profiles/browser_phoenix` | core/effects/UI tree, selected component packages, renderer contract, standalone DOM, Popcorn runtime, browser host, Phoenix adapter, JavaScript bridge; LiveView DOM adapter optional by mode | future native renderer and desktop host unless a later profile says otherwise | application config, lockfile, assets, release/deployment example, gallery, end-to-end evidence |
| `profiles/browser_plug` | core/effects/UI tree, selected component packages, renderer contract, standalone DOM, Popcorn runtime, browser host, Plug adapter, JavaScript bridge | Phoenix, LiveView, LocalLiveView, `blazex_renderer_dom_liveview` directly and transitively | smaller application config, lockfile, static/HTTP example, profile-specific end-to-end evidence |
| `profiles/headless` | core, effects, UI tree, renderer contract, headless renderer, test support | browser host, DOM renderers, JavaScript bridge, Phoenix, Plug, native toolkit | deterministic CLI/CI composition, snapshots, contract and build inspection |

Profiles may own only composition-specific files and evidence. Reusable logic
must move to the package that owns its contract. No profile is the package root
for BlazeX.

## Integration ownership

| Directory | Primary ownership | Boundary |
| --- | --- | --- |
| `integration/fixtures` | versioned components, semantic trees, event/effect streams, resources, applications, expected outcomes | fixtures remain runner- and backend-independent where possible |
| `integration/conformance` | cross-runtime, cross-renderer, cross-capability, and cross-profile contract suites | profile differences are explicit capabilities, not silent divergent semantics |
| `integration/benchmarks` | payload, startup, memory, event-to-paint, update, server-boundary, and build measurements | every result identifies runtime, host, renderer, profile, mode, and environment |

Package-local unit tests remain with their package. Repository-wide composition
claims require integration evidence.

## Experiment ownership

| Directory | Question | Promotion boundary |
| --- | --- | --- |
| `experiments/native_renderer_spike` | Can the BH-02 semantic vertical slice create actual toolkit controls without browser types in portable code? | shared contracts and traces move to packages/integration; no supported native package exists until a later decision and evidence gate |

An experiment must state its question, completion criteria, removal criteria,
and evidence destinations. It cannot publish support claims, become a hidden
dependency of a profile, or select production technology implicitly.

## Valid composition graphs

### Browser/Phoenix with optional LiveView lowering

```text
profiles/browser_phoenix
  -> selected component libraries
  -> blazex_runtime_popcorn + blazex_host_browser
  -> blazex_renderer_dom
  -> blazex_renderer_dom_liveview (optional mode only)
  -> blazex_phoenix
  -> js/blazex_runtime
  -> host-neutral foundation
```

Phoenix coordinates trusted server work. The browser remains the execution host
for browser-local components, and the standalone DOM renderer remains reusable.

### Browser/Plug without LiveView

```text
profiles/browser_plug
  -> selected component libraries
  -> blazex_runtime_popcorn + blazex_host_browser
  -> blazex_renderer_dom
  -> blazex_plug
  -> js/blazex_runtime
  -> host-neutral foundation
```

The graph is invalid if Phoenix, LiveView, LocalLiveView, or the LiveView DOM
adapter appears at any transitive depth.

### Headless

```text
profiles/headless
  -> selected component libraries or fixtures
  -> blazex_renderer_headless + blazex_test
  -> blazex_renderer + host-neutral foundation
```

No browser or server framework is necessary to evaluate the portable contracts.

## Invalid dependency graphs

| Invalid edge or collapse | Why it is invalid | Correct direction |
| --- | --- | --- |
| `blazex_core -> blazex_phoenix` | server framework defines the kernel | `blazex_phoenix ->` public host-neutral contracts |
| `blazex_ui -> blazex_renderer_dom` | component semantics become DOM semantics | DOM renderer consumes `blazex_ui_tree` output |
| `blazex_effects -> js/blazex_runtime` | portable effects expose browser implementation | browser host/bridge implements effect contracts |
| `blazex_renderer_dom -> LiveView` | standalone renderer becomes unusable in Plug/WebView | `blazex_renderer_dom_liveview -> blazex_renderer_dom` |
| `profiles/browser_plug -> blazex_renderer_dom_liveview` | Plug claim gains LiveView transitively | use standalone DOM only |
| `blazex_runtime_popcorn -> blazex_ui` | one runtime selects product catalog policy | profile selects runtime and component libraries independently |
| `blazex_host_browser -> blazex_phoenix` | browser capabilities require one server | profile composes host and server adapters separately |
| `blazex_phoenix -> component implementation internals` | trusted adapter owns local component behavior | commands target public component/application contracts |
| `experiments/native_renderer_spike -> production profile` | bounded proof becomes accidental product dependency | extract accepted contracts before later package/profile adoption |
| profile-local reusable module | profile becomes hidden framework root | move reusable behavior to its owning package |

## Future package boundary

The following are architecture options, not current directories or commitments:

- desktop execution-host adapters;
- WebView packaging adapters;
- native/non-browser AtomVM runtime adapters;
- toolkit-neutral native renderer helpers;
- toolkit-specific native renderer backends;
- standalone Wasm host adapters; and
- custom-scene/GPU renderer packages.

Adding one requires a decision record, explicit owner, dependency analysis,
profile composition, capability policy, conformance evidence, and an update to
this map. A future adapter depends inward on existing protocols; the protocols
do not acquire its implementation types.

## Review checklist

- Every current package appears exactly once in the package ownership table.
- Every executable profile selects runtime, host, renderer, capabilities,
  server adapter, and shell independently.
- Plug has no Phoenix/LiveView path.
- Headless has no browser/server requirement.
- Portable component packages have no adapter dependency.
- Renderer-specific coupling is isolated in a named renderer package.
- Experiments have no production dependency path.
- Future package names remain illustrative until accepted separately.

## Connections

- [BlazeX canonical vocabulary](../20-notes/blazex-canonical-vocabulary.md) — defines every architecture term used by this map.
- [Host-neutral BlazeX architecture and native control backends](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md) — supplies the semantic and cross-renderer rationale.
- [Browser host implementation milestones](../20-notes/browser-host-implementation-milestones.md) — assigns work to these repository boundaries.
- [BH-00 Phase 1 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-01-terminology-and-architecture-decision-baseline.md) — requires this ownership and dependency evidence.
