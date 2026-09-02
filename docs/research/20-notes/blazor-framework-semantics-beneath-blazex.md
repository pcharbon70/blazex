---
title: "Blazor framework semantics beneath BlazeX"
kind: note
created: "2026-09-02"
maturity: developing
tags:
  - blazor
  - design-analysis
  - components
  - elixir
  - phoenix
  - webassembly
aliases:
  - "BlazeX component semantics study"
  - "Blazor-inspired Phoenix component matrix"
---

# Blazor framework semantics beneath BlazeX

**Status:** Lower-level framework and runtime background

**Date:** 2026-09-02

**Baselines:** ASP.NET Core / Blazor .NET 10; Phoenix 1.8; Phoenix LiveView
1.2.11; LocalLiveView 0.1.0; Popcorn 0.3.3

**Question:** Which ideas from Blazor's built-in Razor component system are
useful when designing a native Elixir/Phoenix, browser-resident BlazeX
framework, and which should be reshaped or omitted?

## Executive summary

BlazeX should be a native Elixir/Phoenix component system. Blazor is useful
here as a mature inventory of UI-runtime problems—not as a target platform,
API contract, or compatibility standard. The study asks what can be learned
from Blazor's treatment of parameters, child content, events, forms,
navigation, authorization-aware presentation, error containment, and
virtualization, then redesigns those concerns around Elixir modules, HEEx,
processes, message passing, supervision, Phoenix, and LocalLiveView.

The product-level scope has since been sharpened: **MudBlazor v9.9.0 is the
reference catalog for BlazeX's visual components and interactions**. This note
is retained because the underlying renderer, lifecycle, forms, routing,
identity, and host-boundary questions still matter. It must not be read as the
BlazeX visual catalog or as a plan to recreate Blazor's basic built-ins.

The later [host-neutral architecture
amendment](host-neutral-blazex-architecture-and-native-control-backends.md)
also supersedes any browser-only implication in this inventory. HEEx,
LiveComponents, DOM effects, and LocalLiveView are implementations of the
first web profile; portable components require semantic renderer and host
capability contracts that can also drive native controls.

There is deliberately **no .NET compatibility objective**. BlazeX will not
load Razor components or assemblies, reproduce C# APIs and type semantics,
match the Blazor renderer protocol, preserve Blazor lifecycle behavior as a
contract, or claim that a Blazor package can run unchanged. Similar behavior
is adopted only where it makes sense for Elixir and Phoenix. Phoenix semantics
win whenever the two ecosystems differ.

The design inventory separates into four bands:

1. **High-fit composition primitives.** Parameters, required inputs, child
   content, templated content, attribute forwarding, event handling, list
   identity, dynamic component selection, layouts, and basic form controls map
   well to `Phoenix.Component`, HEEx, `Phoenix.LiveComponent`, and the
   LocalLiveView render path. These belong in the P0 design baseline.
2. **Host-adapted services.** Routing, title updates, authentication,
   antiforgery, uploads, static assets, and server rendering already have
   Phoenix-shaped owners. BlazeX should expose portable contracts while the
   Phoenix adapter performs the authoritative work. Reimplementing ASP.NET
   Core middleware in the browser would be both wasteful and insecure.
3. **Real framework gaps.** Ambient cascading context, named section outlets,
   arbitrary head management, navigation locks/focus, a local form-state
   abstraction, process-aware error fallbacks, and measured viewport
   virtualization need explicit BlazeX designs. They are feasible, but are not
   all present in LocalLiveView 0.1.0.
4. **Intentional divergences.** Component class inheritance, generic type
   parameters, dependency-injection scopes, mutable component instance
   references, and client-side authorization enforcement are .NET-specific or
   undesirable contracts. BlazeX should define the Elixir alternative rather
   than imitate them.

The most important scope correction is that **Blazor does not ship a general
visual widget library**. Its built-ins are infrastructure components and
lightweight form controls. `Button`, `Modal`, `Tabs`, `Accordion`, date pickers,
charts, and similar styled widgets are HTML, project-template code, or
third-party libraries. The separate [MudBlazor-inspired component-system
study](mudblazor-inspired-component-system-for-blazex.md) now defines the
actual BlazeX visual catalog. QuickGrid remains useful here only as a
lower-level data-rendering reference; the product-level grid target is the
MudBlazor DataGrid family, redesigned around native Phoenix contracts.

The recommended release profile is:

- **P0:** component kernel, props, slots, events, keys, dynamic registration,
  local-view lifecycle, layouts, title, navigation effects, basic forms and
  validation, browser capability effects, secure server commands, and a
  local-view process error fallback;
- **P1:** scoped context, sections, head effects, active links, focus after
  navigation, navigation locks, file selection/upload bridges,
  authorization-aware presentation, state persistence, and virtualization;
- **P2:** QuickGrid-inspired data primitives, typed editor generation, CSS
  isolation, richer package asset conventions, and remote-authentication UI;
- **omit by design:** all .NET/Blazor compatibility, C# and Razor source
  support, arbitrary DI, component
  instance mutation, unrestricted reflection/dynamic dispatch, and any claim
  that browser-visible authorization state secures server operations.

## 1. Scope: what “component-by-component” means

### 1.1 Included

The inventory includes:

- public components and abstract component bases in
  `Microsoft.AspNetCore.Components`;
- routing, forms, authorization, web, sections, and virtualization component
  namespaces;
- `RemoteAuthenticatorView` from the Blazor WebAssembly authentication
  package;
- QuickGrid's first-party component package;
- Razor directives and companion contracts that materially define component
  behavior, including parameters, events, render fragments, binding, keys,
  references, lifecycle, render modes, state persistence, CSS isolation, and
  JavaScript collocation.

Several closely related generic types are one row in the matrix. For example,
`InputRadio<TValue>` and `InputRadioGroup<TValue>` are assessed together, and
`PropertyColumn<TGridItem,TProp>` and `TemplateColumn<TGridItem>` are assessed
as the QuickGrid column family. Every concrete built-in family is named even
when several share one recommendation.

### 1.2 Excluded

The following are intentionally outside this foundational inventory:

- WebAssembly Component Model components and WIT interfaces;
- third-party Blazor UI libraries, including MudBlazor, whose catalog is
  studied separately as the BlazeX product reference;
- components generated into an application template, such as an app's
  `NavMenu`, `MainLayout`, or project-specific `ReconnectModal`, unless the
  underlying framework contract is separately listed;
- ASP.NET Core MVC/Razor Pages Tag Helpers that are not Razor components;
- internal renderer types that application authors do not program against;
- pixel-level reproduction of Bootstrap, Fluent, or any Blazor UI library.

### 1.3 This is a design comparison, not a support matrix

Six questions are recorded for each family:

1. **Problem:** What user or framework problem does the Blazor concept solve?
2. **Elixir expression:** How should Elixir/HEEx express that problem?
3. **Server host:** Does Phoenix/LiveView already provide the behavior?
4. **Local host:** Is the behavior documented or visible in LocalLiveView
   0.1.0, merely inferred from renderer reuse, or absent?
5. **Trust:** Is the feature safe to decide in the browser, or must Phoenix or
   Plug remain authoritative?
6. **Product decision:** Should BlazeX reuse, adapt, build, diverge, or omit?

The disposition terms used below are:

| Disposition | Meaning |
| --- | --- |
| **Reuse** | Phoenix/LiveView already has the desired contract; BlazeX mainly verifies and documents it. |
| **Adapt** | The existing Elixir contract is close, but BlazeX needs a facade, host bridge, or stricter portable subset. |
| **Build** | A new BlazeX component or runtime service is required. |
| **Diverge** | Preserve the use case through a deliberately different Elixir contract. |
| **Defer** | Do not include the feature in the initial BlazeX design baseline. |

Evidence labels are equally important:

| Label | Meaning |
| --- | --- |
| **Documented** | Stated by first-party framework documentation. |
| **Observed** | Present in the locally inspected LocalLiveView 0.1.0 package source. |
| **Inferred** | Likely because LocalLiveView reuses a LiveView renderer path, but not demonstrated as a supported LocalLiveView contract. |
| **Proposed** | A BlazeX design recommendation with no implementation evidence yet. |

P0 means required for a credible first public component framework; P1 means
an important framework expansion; P2 means optional library/tooling; P3 means
tied to later SSR/activation or broad ecosystem work. These are BlazeX product
priorities, not levels of Blazor support.

## 2. Architectural fit before individual ideas

### 2.1 The stateful unit is different

Blazor normally gives every Razor component a class instance managed by one
renderer. Phoenix offers three useful units instead:

| Unit | State | Process/failure boundary | Typical use |
| --- | --- | --- | --- |
| Phoenix function component | No independent state | Caller | Reusable markup and slots |
| Phoenix LiveComponent | Independent assigns/lifecycle | Shares parent LiveView process | Stateful application fragment |
| BlazeX local view / LocalLiveView | Independent assigns, events, mailbox | Browser Elixir process and renderer root | Local interactive island and restart unit |

This is not a defect to hide. BlazeX should expose the three units explicitly.
A Blazor component that is only a parameterized template maps to a function
component. A component that owns small nested state maps to a LiveComponent.
A component requiring independent failure recovery, mailbox behavior, durable
state, or a server bridge maps to a local view.

### 2.2 The renderers share ideas; the programming models remain distinct

Both systems compile templates into structured render data, retain component
identity, dispatch browser events, compute changes, and let JavaScript update
the DOM. LocalLiveView strengthens this analogy by reusing LiveView diff and
browser patching internals inside a Popcorn-hosted AtomVM.

BlazeX should therefore preserve declarative rendering and event semantics,
not .NET objects. There is no reason to emulate `ComponentBase`, reflection
over `[Parameter]` properties, `IServiceProvider`, or direct method calls on a
captured child instance.

### 2.3 The trust boundary is stricter in local mode

Interactive Blazor WebAssembly and BlazeX local views both execute in an
untrusted browser. Phoenix LiveView normally executes state on a trusted
server. Moving HEEx callbacks into AtomVM changes the trust status of every
assign and event even if the API looks familiar.

Consequently:

- authorization views are presentation only;
- client validation is user experience only;
- file metadata is untrusted;
- local route guards cannot protect server data;
- persistence envelopes require integrity/version checks but still contain
  client-controlled state;
- privileged work uses declared, authenticated, authorized server commands.

### 2.4 Phoenix and Plug are not interchangeable capability sets

Phoenix with LiveView can supply the stock DOM patcher, router coordination,
Channels, uploads, session/auth hooks, PubSub, and generated asset conventions.
Plain Plug supplies an HTTP pipeline and adapter boundary. A Plug server
integration can serve BlazeX assets, bootstrap state, receive HTTP commands,
and set security headers, but BlazeX must own or add every richer
realtime/browser service.

The matrices therefore describe a Phoenix-first target. A feature is
“portable to Plug” only when its contract does not assume a LiveView channel,
router, upload process, or browser client internal.

## 3. Design scorecard by capability family

| Family | Phoenix fit | LocalLiveView 0.1.0 | BlazeX direction | Priority |
| --- | --- | --- | --- | --- |
| Parameters, slots, attributes | High | Documented through reused HEEx/components | Reuse with a portable prop schema | P0 |
| Events and binding | High | Event and form decoding observed | Adapt to local events plus typed server commands | P0 |
| Keys and component identity | High | Renderer reuse; component ID handling observed | Normalize identity rules | P0 |
| Dynamic components | High with compile-time caveats | LiveComponents documented; tree-shaking risk | Manifest-bounded registry | P0 |
| Lifecycle and render scheduling | Medium–high | Core callbacks observed; after-render/disposal gaps | Stable local-view lifecycle facade | P0/P1 |
| Cascading context | Low–medium | No public local context contract | Build scoped, serializable context | P1 |
| Layouts and title | High | Ordinary HEEx likely; local title unverified | Reuse layouts; adapt title as host effect | P0 |
| Named sections and arbitrary head | Low | Not demonstrated | Build scoped outlets/head manager | P1 |
| Routing and links | High at host | Patch navigation observed | Host-owned routing with local patch adapter | P0/P1 |
| Basic forms and validation | High on server | Form event decoding observed | Own a client-safe form-state package | P0 |
| File input/upload | High on server | No LocalLiveView upload integration found | Build split local-file/server-upload bridge | P1 |
| Authorization presentation | High on server | Auth propagation unverified | Build advisory view over explicit public auth state | P1 |
| Error boundaries | Process-level analogue | Local view is a process; subtree catch absent | Root fallback P0, subtree boundary later | P0/P2 |
| Virtualization | Partial through streams/viewport | Not demonstrated as component | Build browser-measured virtualizer | P1 |
| QuickGrid | No framework analogue | Not demonstrated | Optional BlazeX-native grid package | P2 |
| CSS isolation | Build-tool gap | Not demonstrated | Optional selector-rewrite pipeline | P2 |
| JavaScript/browser interop | High through hooks | Renderer hooks and Popcorn JS bridge observed | Capability/effect facade | P0 |
| Package/static assets | High through Hex/Phoenix assets | Manual build conventions exist | Manifest and asset convention | P1 |
| SSR state persistence/streaming | Partial | SSR explicitly unfinished | Separate activation program | P3 |

The scorecard is intentionally not a percentage. A missing authorization
boundary or file-upload transport matters more than ten trivial input wrappers.

## 4. Component kernel and composition

### 4.1 Component-by-component matrix

| Blazor contract | Phoenix/LiveView analogue | Local-runtime evidence | BlazeX disposition | Priority |
| --- | --- | --- | --- | --- |
| `IComponent`, `ComponentBase` | Function components, `Phoenix.LiveComponent`, and LiveView callbacks divide the role | `LocalLiveView` defines `mount`, `update`, `render`, event, info, and hook lifecycle on a process | **Diverge:** expose function/live/local units, not one base class | P0 |
| `[Parameter]`, `ParameterView` | Assigns plus `attr/3`; LiveComponents receive passed assigns | Host assigns are normalized and passed through `update/2` in inspected source | **Adapt:** `prop` metadata over HEEx attrs and serializable host props | P0 |
| `[EditorRequired]` | `attr ..., required: true` and `slot ..., required: true` emit compile warnings | HEEx compiler reused | **Reuse:** compile-time requirement plus optional runtime boundary validation | P0 |
| `EventCallback`, `EventCallback<T>` | `phx-*`, `Phoenix.LiveView.JS.push`, `phx-target`, messages, callback-like assigns | Local event targeting/decoding and server push are observed | **Adapt:** local event names; never serialize arbitrary closures across roots | P0 |
| `RenderFragment`, `ChildContent` | Default `:inner_block` slot and `render_slot/1` | Phoenix components are documented as supported locally | **Reuse** | P0 |
| `RenderFragment<T>`, templated components | Named slots and `render_slot(slot, value)` | Inferred from HEEx/renderer reuse | **Reuse**, with BlazeX contract tests for contextual slots | P0 |
| Generic Razor components, `@typeparam` | Elixir data is dynamic; `attr` types and guards document/check a subset | No nominal generic system in BEAM component syntax | **Diverge:** schema/guards/protocols instead of C# type parameters | P0 documentation |
| `CascadingTypeParameter` | No direct Phoenix analogue | Absent | **Omit**; use explicit slot data and prop schemas | — |
| `DynamicComponent` | `.live_component module={...}` for stateful modules; bounded `apply/3` pattern for functions | LocalLiveView documents nested LiveComponents | **Adapt:** registered component IDs and manifest reachability, not arbitrary reflection | P0 |
| `CascadingValue<T>`, cascading parameters | Explicit assigns/slots; LiveComponents do not inherit parent assigns | No public cascading-context feature found | **Build:** root-scoped named context with subscription and serialization rules | P1 |
| Attribute splatting / unmatched attributes | `attr :rest, :global` and `{ @rest }`-style HEEx attribute expansion | Reused HEEx | **Reuse**, retaining Phoenix's allowlist and escaping | P0 |
| `@bind` and `{Value}Changed` convention | Form values plus `phx-change`; explicit value and event props for components | Form decoding observed | **Diverge carefully:** explicit `value`/`on_change`; optional sugar only after semantics are stable | P0 |
| `@key` | HEEx `:key`, stream DOM IDs, LiveComponent module plus ID | Component deletion/ID bookkeeping observed | **Adapt:** one documented identity model across static lists, streams, and components | P0 |
| Component `@ref` | Component IDs, `send_update`, event targets, process messages | No direct instance-reference API | **Diverge:** declarative props/messages; do not expose mutable component instances | P0 documentation |
| Element `@ref`, `ElementReference` | Stable DOM IDs and hooks | DOM remains in parent page while AtomVM runs in an iframe | **Build:** opaque effect handles scoped to a local-view generation | P1 |
| `MarkupString` | HEEx escaping by default; `raw/1` escape hatch | Renderer reuse | **Reuse with security policy:** raw content must be trusted/sanitized | P0 |
| `@inject`, `InjectAttribute` | Explicit modules, behaviours, application config, process state | Full DI container semantics absent and undesirable | **Diverge:** explicit capabilities and server commands | P0 architecture |
| `OwningComponentBase<TService>` | Local view process ownership and explicit resource cleanup | Process lifetime exists; service scopes do not | **Diverge:** generation-scoped resources tied to process supervision | P1 |

### 4.2 Parameter and serialization contract

Blazor can pass arbitrary in-process .NET objects when parent and child share a
renderer. BlazeX needs two different prop tiers:

- **in-renderer props:** ordinary Elixir terms may pass between function and
  live components inside one local-view process, subject to AtomVM support;
- **host-boundary props:** values entering from Phoenix, Plug, persisted state,
  or another runtime must conform to a versioned serializable schema.

This distinction prevents the convenient Phoenix API from concealing a
browser boundary. A proposed declaration is:

```elixir
prop :cart_id, :string, required: true, boundary: :host
prop :items, {:list, :public_item}, default: [], boundary: :host
prop :formatter, {:fun, 1}, boundary: :local
```

The build should reject `:local` props on a root mounted by the server and
should explain the shortest dependency path that introduced a nonportable
value. Functions, PIDs from the server VM, ports, NIF resources, database
structs carrying hidden fields, and opaque Phoenix sockets do not cross.

### 4.3 Events are not delegate serialization

`EventCallback<T>` is a typed .NET delegate bound to a component receiver.
Phoenix events are names plus serializable payloads routed to a LiveView or
LiveComponent. BlazeX should retain the latter because it naturally crosses
the JavaScript/AtomVM boundary and is auditable.

The product contract should distinguish:

- `handle_event/3`: local, synchronous-with-the-event-loop state transition;
- `send/2` / `handle_info/2`: local process messaging;
- `effect/3`: declared browser capability;
- `command/4`: authenticated request to trusted Phoenix or Plug code;
- child-to-parent notification: an event/message target, not an arbitrary
  closure smuggled through the host boundary.

This addresses the same callback use case while making latency, failure,
serialization, and authority explicit in an Elixir/Phoenix design.

### 4.4 Dynamic component safety and tree shaking

Phoenix can dynamically call a component module, but the LocalLiveView bundle
tree shaker cannot infer every atom produced at runtime. BlazeX should require
one of:

```elixir
dynamic_components [Card, Chart, EmptyState]
```

or a package manifest mapping stable public IDs to modules:

```elixir
%{"card" => ShopWeb.Card, "empty-state" => ShopWeb.EmptyState}
```

Unknown IDs fail closed. The manifest gives the build a reachability root,
supports lazy bundles, avoids exposing internal module names, and prevents
server-controlled strings from becoming unrestricted module dispatch.

### 4.5 Cascading context should be small and explicit

Blazor cascading values are convenient for themes, form contexts, and auth
state, but they can obscure dependencies and cause broad rerenders. Phoenix's
explicit assigns avoid that ambiguity. BlazeX should add context only for
values that are genuinely cross-cutting:

- theme or locale;
- form state;
- public authentication presentation state;
- host capabilities;
- section/outlet registries.

The context should be scoped to one local renderer root, keyed by a stable
name rather than an Elixir runtime type, and optionally fixed to avoid
subscriptions. Context must not silently cross a server/local render boundary.
That mirrors Blazor's real render-mode boundary instead of pretending the
whole page is one object graph.

## 5. Lifecycle, rendering, identity, and render modes

### 5.1 Lifecycle matrix

| Blazor lifecycle idea | Closest BlazeX phase | BlazeX design decision |
| --- | --- | --- |
| `SetParametersAsync` | Host prop decode, then `update/2` | Adapt; validate all host props before exposing them to component code |
| `OnInitialized{Async}` | `mount/3` | Close semantic match; async work becomes messages/tasks with explicit cancellation |
| `OnParametersSet{Async}` | `update/2` | Close semantic match; do not mutate the incoming prop contract |
| `BuildRenderTree` / Razor render | `render/1` returning HEEx rendered data | Reuse LiveView compilation/diff path |
| Event callback rerender | Callback updates assigns, renderer diffs changed state | Reuse |
| `StateHasChanged` | Send a message or update assigns in a callback | Diverge; no ambient imperative render request in the portable API |
| `ShouldRender` | Changed-assign tracking and no-op update | Diverge; add only if measurement proves a need |
| `OnAfterRender{Async}` | Browser hook/effect acknowledgement after patch | Build an effect lifecycle; do not run DOM work during SSR |
| `IDisposable` / `IAsyncDisposable` | Local-view removal, process termination, hook `destroyed` | Build deterministic bounded disposal plus forced cleanup |
| Error/recovery | Process crash, fallback root, supervised remount | Adapt at local-view root; subtree behavior is separate |

The inspected LocalLiveView source directly implements `mount`, `update`,
`handle_params`, `handle_event`, `handle_info`, render diffing, component
deletion bookkeeping, and process termination. It does not establish a public
BlazeX-level after-paint or disposal contract. That gap matters for observers,
timers, JavaScript objects, focus, and file handles.

### 5.2 Identity rules

Blazor's `@key`, Phoenix's keyed comprehensions, stream IDs, LiveComponent
module/ID pairs, DOM IDs, and BlazeX local-view IDs solve related but distinct
problems. BlazeX should publish one table of identity scopes:

| Identity | Scope | Preserves |
| --- | --- | --- |
| Local-view instance ID | Page/runtime | Process, root renderer state, durable-state generation |
| LiveComponent module + ID | Parent local view | Component assigns and lifecycle |
| HEEx list key | Siblings under one parent | Element/component association during reorder |
| Stream DOM ID | Stream container | Insert/update/delete identity |
| DOM `id` | Document | Browser targeting, labels, hooks, accessibility |

Keys must be deterministic and unique in their scope. A change in local-view
instance ID means remount, not rename. A deployment generation change
invalidates opaque browser handles and stale command replies.

### 5.3 Host and render-mode mapping

Blazor exposes static server, interactive server, interactive WebAssembly, and
Auto render modes on one Razor component model. BlazeX's analogous choices
should be host/build decisions:

| Blazor idea | BlazeX analogue |
| --- | --- |
| Static server render | Phoenix/Plug HEEx output without local runtime |
| Interactive server | Ordinary Phoenix LiveView |
| Interactive WebAssembly | BlazeX local view in Popcorn/AtomVM |
| Auto | Explicit server-first policy for future visits, not live process migration |

BlazeX should not mimic `@rendermode` as arbitrary nested mode switching.
Server and local roots have serialization, event ownership, and DOM ownership
boundaries. The component manifest can declare supported hosts, while the
mounting application selects one legal host for a root and its subtree.

`EnvironmentBoundary` therefore maps to an explicit capability check such as
`host?(:local)` or a `BlazeX.HostBoundary` function component. It must not be
used to hide secret server code in a client bundle: reachability analysis runs
before runtime conditionals.

## 6. Layout, section, head, resource, and state components

### 6.1 Component-by-component matrix

| Blazor component/contract | Phoenix/LiveView analogue | Local-runtime evidence | BlazeX disposition | Priority |
| --- | --- | --- | --- | --- |
| `LayoutComponentBase`, `Body` | Root layout plus explicit `Layouts.app` function component and slots | HEEx composition available | **Reuse/adapt:** ordinary slot-based layouts | P0 |
| `LayoutView` and nested layouts | Explicit nested function-component composition | Inferred | **Reuse:** no special runtime required | P0 |
| `SectionContent` | No location-independent built-in analogue | Absent | **Build:** scoped section provider | P1 |
| `SectionOutlet` | No location-independent built-in analogue | Absent | **Build:** deterministic outlet registry | P1 |
| `PageTitle` | `@page_title` and `Phoenix.Component.live_title` | Local mutation not verified | **Adapt:** title effect coordinated by host | P0 |
| `HeadContent` | Root layout content is static across live navigation | Absent as dynamic general head API | **Build narrowly:** declared meta/link effects with ownership and deduplication | P1 |
| `HeadOutlet` | No dynamic general outlet; root layout is host-owned | Absent | **Build in JS host**, not inside AtomVM DOM logic | P1 |
| `EnvironmentBoundary` | Config/capability conditionals | Host type known to loader | **Adapt:** explicit host capability component | P1 |
| `ConfigureBrowser` | Endpoint/bootstrap configuration | No analogous UI need | **Diverge:** manifest/bootstrap config, not a component | P2 tooling |
| `ImportMap` | Static asset/build configuration | Browser host can emit/import maps | **Diverge:** host asset policy; no ordinary component API | P2 |
| `ResourcePreloader` | Endpoint/static layout `<link rel=preload>` generation | No local API | **Adapt:** manifest-driven host preload hints | P2 |
| `PersistentComponentState`, `[PersistentState]` | Session/cache plus explicit serialized bootstrap | Local state transfer not complete; SSR is unfinished | **Build:** versioned public state envelope | P3 for SSR, P1 for local durable state |
| `[StreamRendering]` | HTTP streaming/async assigns are different mechanisms | No LocalLiveView SSR | **Defer:** server renderer concern, not a local component primitive | P3 |
| `SupplyParameterFromSession`, `SupplyParameterFromTempData` | Plug session/flash converted to selected assigns | Host can pass normalized assigns | **Adapt:** allowlisted bootstrap props only | P1 |

### 6.2 Layouts are composition, not renderer magic

Phoenix 1.8's explicit app layout component is a good fit for BlazeX. A local
view can render a layout function and pass its body as a slot. Root HTML,
security headers, scripts, and the initial `<head>` remain the host's domain.
This is clearer than treating a browser-local component as owner of the whole
document.

### 6.3 Sections need lifecycle and ownership rules

A named section is more than a global slot. The provider may be lower in the
tree than the outlet and can disappear independently. A BlazeX implementation
needs:

- registry scope: one local renderer root or one coordinated page host;
- stable section ID and provider instance ID;
- conflict rule: error, priority, or explicit stack—not an undocumented race;
- cleanup when the provider component disappears or crashes;
- context semantics based on the provider, matching Blazor's content origin;
- SSR representation and activation behavior;
- prohibition on crossing into a DOM subtree owned by another renderer.

The initial version should support one provider per outlet and fail clearly on
duplicates. Blazor's last-rendered-wins behavior is useful for replacement but
too implicit for a distributed server/local ownership boundary.

### 6.4 Head management must be a host effect

Phoenix LiveView intentionally special-cases the document title but does not
dynamically patch arbitrary root-layout head content during live navigation.
BlazeX can add a host-side head manager, but local code should emit declarative
effects rather than manipulate `document.head` directly:

```elixir
effect(socket, :head_put,
  key: {:meta, "description"},
  tag: :meta,
  attrs: %{name: "description", content: description}
)
```

The host validates tag/attribute allowlists, records the owning local-view
generation, deduplicates keys, and removes entries on disposal. Executable
scripts and arbitrary raw HTML are excluded from the portable contract.

### 6.5 Persistent state is not trusted state

Blazor can persist prerender state to avoid duplicate fetching when an
interactive component restarts. BlazeX will eventually need a similar
envelope for server render to local activation, but the browser receives and
can alter it. Signatures can detect server-envelope tampering; they do not make
subsequent local mutations authoritative.

Every persisted payload should carry schema version, component public ID,
instance ID, build ID, renderer protocol, expiration where appropriate, and a
list of fields permitted to restore. Effects and server commands are never
replayed merely because they appeared in persisted state.

## 7. Routing and navigation components

### 7.1 Component-by-component matrix

| Blazor component/contract | Phoenix/LiveView analogue | Local-runtime evidence | BlazeX disposition | Priority |
| --- | --- | --- | --- | --- |
| `Router` | `Phoenix.Router`, LiveView routes, and `live_session` | LocalLiveView supports current-page patch navigation, not a full discovered page-component router | **Diverge:** host router owns routable pages | P0 architecture |
| `RouteView` | Router mounts a LiveView; layouts are explicit | `live_local` mounts a standalone local view at a Phoenix route | **Adapt:** host route-to-local-root adapter | P1 |
| `RouteAttribute` / Razor `@page` | `live`, `get`, and `live_local` router declarations | `live_local` macro observed | **Diverge:** routes stay explicit in Phoenix/Plug | P0 |
| `NavLink` | `Phoenix.Component.link`; current URI is available to the view | No automatic active-class local component found | **Build:** `BlazeX.Web.nav_link` with exact/prefix matching | P1 |
| `FocusOnNavigate` | Hook/JS focus operations | No dedicated component found | **Build:** accessibility-first navigation effect | P1 |
| `NavigationLock` | No direct component; hooks can intercept browser events | No dedicated local contract found | **Build:** blocker registry with internal/external navigation semantics | P1 |
| `NavigationManager` | `<.link>`, `push_patch`, `push_navigate`, redirect | Local `push_patch/2`, patch-link interception, `popstate`, and host coordination observed | **Adapt:** host-neutral navigation service | P0 |
| `SupplyParameterFromQuery` | `handle_params/3` receives route/query params | Mount and patch `handle_params/3` observed | **Reuse/adapt:** explicit decode schema | P0 |
| Route parameters and constraints | Phoenix router path params and verified routes | Standalone local query handling documented; full local path routing not shown | **Reuse host routing;** pass allowlisted route props | P0 |
| `ExcludeFromInteractiveRouting` | Ordinary `href`/redirect or crossing a `live_session` forces full navigation | Supported by host behavior | **Adapt:** `reload: true` navigation option | P1 |
| Not-found content | Phoenix router/controller fallback and LiveView route handling | No browser-local route catalog | **Diverge:** host owns 404; local widgets own only internal empty states | P0 |

### 7.2 Why BlazeX should not start with a second page router

Phoenix already has compile-time routes, verified route generation, Plug
pipelines, session/auth boundaries, controller fallbacks, and LiveView
navigation semantics. A second route table inside AtomVM would create several
failure modes:

- host and client disagree on whether a path exists;
- a browser route bypasses a Plug or `on_mount` authorization boundary;
- deep-link refresh and crawler behavior differ from in-app navigation;
- deployment changes leave stale client route tables;
- local code appears to protect data it cannot authorize.

For P0, a local view can react to the current URL and patch query/path state
under a host-approved route. For P1, Phoenix can map a route to a local-view
public ID through `live_local` or a host component. A fully offline application
router is a separate product mode and should declare its own shell, cache, and
security model.

### 7.3 LocalLiveView navigation evidence

The inspected 0.1.0 package contains a dedicated navigation guide and code for
two modes:

- **hosted:** Phoenix owns browser history and emits `phx:navigate`; local
  views rerun `handle_params/3` and deduplicate an echo from their own patch;
- **standalone:** LocalLiveView intercepts patch links, writes history, handles
  `popstate`, and invokes local `handle_params/3` without a network call.

`LocalLiveView.push_patch/2` is implemented. `href` and `navigate` retain
Phoenix semantics; the package does not claim to make arbitrary local
components into routable pages. BlazeX should wrap this capability instead of
inventing a second, competing link syntax.

### 7.4 Navigation focus and locks are correctness features

`FocusOnNavigate` is easy to dismiss as convenience, but it repairs screen
reader context after an in-place page update. BlazeX's native facility should:

- run only after a successful DOM patch;
- target an explicit selector with a fallback to the local root;
- avoid stealing focus from an active user edit;
- announce page context through documented ARIA patterns;
- have deterministic SSR/no-JS behavior.

A navigation lock similarly needs more than `beforeunload`. It must coordinate
Phoenix patches, local patches, full links, browser back/forward, and multiple
local roots. The page host should aggregate blockers and ask once. A crashed or
removed root must release its blocker automatically.

## 8. Forms and validation components

### 8.1 The semantic mismatch to resolve

Blazor's `EditContext` is an in-process object tied to a model and field
expressions. Phoenix's `Phoenix.HTML.Form` is a data structure produced from
params or a `Phoenix.HTML.FormData` implementation, commonly an Ecto changeset.
Ordinary Phoenix form validation runs on the server. Ecto, database schemas,
and arbitrary changeset code should not be assumed to compile or belong in an
AtomVM browser bundle.

BlazeX therefore needs a client-safe form kernel rather than “Ecto in Wasm.”
It can render the same HEEx controls on server and client while using adapters:

```text
BlazeX.FormState
├── fields: value, initial value, touched, dirty, pending
├── errors: normalized public messages and codes
├── validation: pure local validators
├── submit: local callback or typed server command
└── adapters
    ├── Phoenix.HTML.Form / params
    ├── public Ecto changeset projection (server only)
    └── persisted local draft
```

### 8.2 Component-by-component matrix

| Blazor component/contract | Phoenix/LiveView analogue | Local-runtime evidence | BlazeX disposition | Priority |
| --- | --- | --- | --- | --- |
| `EditForm` | `Phoenix.Component.form/1` | Form event decoding observed | **Adapt:** `BlazeX.Form.form` over portable form state | P0 |
| `EditContext` | `Phoenix.HTML.Form`, params, changeset metadata, `used_input?` | No client-safe independent context type found | **Build:** `BlazeX.FormState` | P0 |
| `InputBase<TValue>` | App-generated `.input` components; raw HEEx elements | No stable framework base | **Build:** headless input contract, not class inheritance | P0 |
| `InputText` | `<input type="text">` plus app component | Form events supported | **Build thin wrapper** | P0 |
| `InputTextArea` | `<textarea>` plus app component | Form events supported | **Build thin wrapper** | P0 |
| `InputHidden` | `<input type="hidden">` | Ordinary form serialization | **Build thin wrapper** | P0 |
| `InputCheckbox` | Checkbox input and Phoenix normalization | Ordinary form serialization | **Build thin wrapper**, test absent/false semantics | P0 |
| `InputSelect<TValue>` | `<select>`, including multiple values | Ordinary form serialization | **Build thin wrapper** with schema parse | P0 |
| `InputRadio<TValue>`, `InputRadioGroup<TValue>` | Named radio inputs | Ordinary form serialization | **Build thin wrappers** with generated accessible IDs | P0 |
| `InputNumber<TValue>` | Numeric or text/inputmode app component | Form decoding exists; AtomVM numeric limits matter | **Build:** string parse plus explicit range/type errors | P0 |
| `InputDate<TValue>` | Date/time HTML inputs and app parsing | Date-type/runtime support unverified | **Build:** ISO wire values and supported-type matrix | P1 |
| `InputFile` | `live_file_input`, upload configuration, server/external upload pipeline | No `allow_upload`/upload handling found in local package | **Build split contract:** local file handles plus optional server uploader | P1 |
| `Label<TValue>` | Ordinary `<label for>` and generated app components | Markup available | **Build thin wrapper** | P0 |
| `DisplayName<TValue>` | No universal model metadata; app/schema translation | Absent | **Diverge:** explicit label or schema metadata | P1 |
| `DataAnnotationsValidator` | Changesets plus app/pure validation functions | Server changesets not a safe local assumption | **Diverge:** pure validator behaviour and server error adapter | P0 |
| `ValidationMessage<TValue>` | Render normalized field errors, usually in CoreComponents | Markup/events available | **Build** | P0 |
| `ValidationSummary` | Render flattened form errors | Markup/events available | **Build** | P0 |
| `FieldCssClassProvider` | App component computes classes from field/error state | No stable analogue | **Build:** configurable field-state class function | P1 |
| `AntiforgeryToken` | Phoenix CSRF token/meta and Plug verification | Host page/LiveSocket owns token | **Diverge:** host transport responsibility, never local validation | P0 security |
| `FormMappingScope`, `SupplyParameterFromForm` | Plug parser/controller params and LiveView form event names | Local form decoder handles URL-encoded payloads | **Adapt only for static/server forms;** do not clone .NET mapper | P2 |
| `Editor<T>` | Schema-selected function component | No built-in | **Build optional editor registry** | P2 |

### 8.3 Basic input contract

Each BlazeX input should be a function component over a field descriptor, not
a stateful process and not a base-class hierarchy. A minimum descriptor is:

```elixir
%BlazeX.Form.Field{
  form: "profile",
  name: :age,
  id: "profile_age",
  raw: "42",
  value: 42,
  touched?: true,
  dirty?: true,
  errors: []
}
```

An input renders standards-based HTML, forwards allowed global attributes,
sets `aria-invalid`/`aria-describedby`, and emits a standard form event. Parsing
is separate from rendering so an invalid raw value such as `"-"` is not lost
while the typed value remains unchanged. This is especially important for
numbers and dates.

### 8.4 Validation profile

The portable P0 validator API should allow deterministic, side-effect-free
rules over public form data:

```elixir
validator :required, field: :email
validator :format, field: :email, with: :email
validator :range, field: :age, min: 18, max: 130
```

Custom validators may be Elixir functions only if the build proves their
entire call graph is client-safe. Database uniqueness, permission checks,
inventory availability, prices, and other authoritative rules are server
commands. Server replies use stable error codes and field paths; user-facing
messages can be localized without trusting client decisions.

The form model should preserve three distinct outcomes:

- locally invalid: do not submit unless explicitly allowed;
- locally valid but server rejected: merge authoritative errors;
- accepted: update server version/durable state and clear pending markers.

### 8.5 File selection and upload are two capabilities

Blazor `InputFile` exposes browser files as streams. Phoenix LiveView uploads
coordinate client chunks with a server process or an external uploader.
LocalLiveView 0.1.0 has no inspected upload-specific Elixir path, so BlazeX
must not claim a file workflow merely because `<input type="file">` renders.

The proposed split is:

1. `FileInput` returns opaque browser file handles plus untrusted metadata.
2. `File.read_chunk` is a browser effect with explicit size limits.
3. `Upload` selects one configured transport:
   - Phoenix LiveView upload adapter;
   - signed direct-to-object-store upload;
   - Plug HTTP multipart/chunk endpoint;
   - local-only processing for explicitly permitted files.
4. The local view receives progress, completion, cancellation, and typed
   failure events.

Never copy a whole large file through JSON or AtomVM memory by default.
Metadata, MIME type, dimensions, and filenames remain untrusted until the
authoritative receiver validates them.

### 8.6 Form behavior that BlazeX contract tests must preserve

The BlazeX form contract is more than rendered HTML. Tests must cover:

- focused input values surviving unrelated patches;
- selection/caret preservation;
- composition/IME events and Unicode;
- checkbox false/absent semantics;
- multi-select arrays;
- repeated and nested field names;
- touched/unused error visibility;
- debounce/throttle and stale validation replies;
- duplicate submit prevention;
- reconnect/remount recovery;
- reset behavior;
- password non-repopulation;
- browser-native invalid number/date values;
- accessibility relationships for labels, hints, and errors;
- local/offline submit policy and later command reconciliation.

## 9. Authentication and authorization components

### 9.1 Component-by-component matrix

| Blazor component/contract | Phoenix/LiveView analogue | Local-runtime evidence | BlazeX disposition | Priority |
| --- | --- | --- | --- | --- |
| `AuthorizeView` | Conditional HEEx over `current_scope`/user plus app policy functions | Public auth-state propagation not demonstrated | **Build:** advisory `authorized` presentation component | P1 |
| `AuthorizeViewCore` | App policy behaviour/function | No analogous base class needed | **Diverge:** policy behaviour, not inheritance | P1 |
| `AuthorizeRouteView` | Router pipelines, `live_session`, `on_mount`, `mount`, and `handle_params` checks | Local route guard cannot secure server resources | **Reuse host authorization;** optional denied/loading UI slots | P0 security / P1 UI |
| `CascadingAuthenticationState` | Explicit current scope/user assign; `on_mount` | No supported cascade found | **Adapt:** sanitized public auth context over BlazeX scoped context | P1 |
| `AuthenticationStateProvider` | Accounts/context lookup on server plus revocation broadcast | Local client can cache only public advisory state | **Diverge:** host-owned provider with version/expiry | P1 |
| `RemoteAuthenticatorView` | Phoenix auth routes, controllers, `mix phx.gen.auth`, OAuth/OIDC libraries | Browser-local remote-auth orchestration absent | **Defer/adapt:** normal host redirect flow first | P2 |
| `RemoteAuthenticatorViewCore<T>` | App-specific auth state machine | No local analogue | **Do not clone generics;** optional provider behaviour later | P2 |

### 9.2 Authorization-aware presentation must not become security theater

Microsoft's documentation explicitly states that `AuthorizeView` changes
visibility but does not secure its event handler or prevent navigation. Phoenix
LiveView's security guide makes the same point: authenticate on HTTP and
connected mounts, authorize route changes, and authorize every protected
event/action.

BlazeX should make this constraint visible in the API name and documentation:

```elixir
<.authorized_view policy={:can_edit_profile} subject={@public_profile}>
  <:allowed>...</:allowed>
  <:denied>...</:denied>
  <:loading>...</:loading>
</.authorized_view>
```

The component improves presentation. A corresponding server command still
receives server-derived identity and subject, evaluates the authoritative
policy, and rejects unauthorized calls. The client must not submit a role,
price, owner ID, or permission result as proof.

### 9.3 Public authentication state

A local bundle may need a display name, signed-in boolean, coarse roles for
navigation presentation, or an expiry indicator. The server should project a
minimal public record rather than serialize its user/session struct:

```elixir
%{
  status: :authenticated,
  display_name: "A. Example",
  presentation_roles: ["editor"],
  auth_version: 17,
  expires_at: "2026-09-02T18:00:00Z"
}
```

Roles in this record are hints for rendering. Revocation can arrive through a
Phoenix channel, but the server command path independently checks current
authorization. Logging out destroys/revokes the server session and tells local
views to clear cached public state; it does not rely on the local process
cooperating.

### 9.4 Remote authentication and cross-origin isolation

Blazor's `RemoteAuthenticatorView` is coupled to its WebAssembly authentication
package, route actions, JavaScript OIDC client, and access-token services.
Phoenix applications have several auth stacks and may use cookies, redirects,
passkeys, magic links, enterprise identity, or APIs. A generic clone would be
premature.

The P0/P1 answer is a normal full-page host redirect and return URL. Any later
popup/iframe OIDC component must be tested under Popcorn's required COOP/COEP
headers because cross-origin opener relationships and embedded identity pages
can fail under isolation. Tokens should remain in the host's intended storage
and transport; BlazeX should not invent a second token vault inside AtomVM.

## 10. Error boundaries, failure domains, and recovery

### 10.1 Component-by-component matrix

| Blazor component/contract | Phoenix/LiveView analogue | Local-runtime evidence | BlazeX disposition | Priority |
| --- | --- | --- | --- | --- |
| `ErrorBoundary` | Nested LiveView process gives isolation; a LiveComponent error fails its parent view | Each local view is a GenServer under a dynamic supervisor; nested components share it | **Adapt:** local-root fallback and supervised remount | P0 |
| `ErrorBoundaryBase` | Custom error-report/fallback policy module | No subtree catch API found | **Build policy behaviour** | P1 |
| `ErrorContent` fragment | Error slot/function component | HEEx slots available | **Reuse** | P0 |
| `Recover()` | Remount/retry message with generation change | No public analogue found | **Build explicit retry** | P0 |
| Subtree exception containment | Separate nested LiveView/local view process | LiveComponents are not isolated | **Defer true in-renderer subtree boundary;** use a child local root when isolation matters | P2 |

### 10.2 The actual failure boundary

Blazor can catch a descendant render/lifecycle exception inside one renderer
and replace only that subtree. Phoenix LiveComponents and function components
share their parent process; an exception normally fails the view render. A
nested LiveView is isolated because it is another process. LocalLiveView gives
each local root a process, but its nested LiveComponents remain in that root's
process and renderer state.

BlazeX should therefore make the P0 boundary coincide with the real process
boundary:

```text
host page
├── local view A process ── failure fallback A
│   ├── function component
│   └── live component (not separately isolated)
└── local view B process ── failure fallback B
```

An API named `ErrorBoundary` around an ordinary function component would be
misleading unless the renderer can safely restore fingerprints, component
state, effects, and DOM ownership after an exception. Use a separate local
view when a fragment truly needs containment.

### 10.3 Required failure states

The host fallback should distinguish:

- component callback exception;
- renderer/diff protocol error;
- unsupported AtomVM call;
- local process timeout or mailbox overload;
- whole iframe/AtomVM failure;
- stale build/renderer generation;
- missing cross-origin isolation;
- server bridge disconnected or command rejected.

Only the first class necessarily maps to Blazor `ErrorBoundary`. Different
states require different recovery actions. A component retry creates a new
generation and invalidates browser handles and stale replies. A VM crash
remounts all roots. A server disconnect normally leaves local events active
and reports command availability rather than destroying the UI.

### 10.4 Recovery must avoid loops

Blazor warns against calling `Recover` while rendering the same failing
content. BlazeX should enforce a similar invariant:

- retry only from a user event, host policy, or a changed build/state input;
- apply exponential limits to automatic process/VM restarts;
- retain a crash fingerprint and suppress identical hot loops;
- never replay non-idempotent effects or server commands automatically;
- expose a safe reload/fallback link even when AtomVM is unavailable.

## 11. Virtualization and QuickGrid

### 11.1 Viewport virtualization design

| Blazor capability | Phoenix today | BlazeX decision |
| --- | --- | --- |
| Render visible slice plus overscan | Streams plus `phx-viewport-top/bottom` can maintain a bounded infinite-scroll DOM | Build a local measurement-driven `Virtualize` component |
| In-memory `Items` | HEEx enumeration/streams | Accept enumerable/list only within explicit size budget |
| Async `ItemsProvider` with range/count | App pagination functions | Define serializable range request/result and cancellation generation |
| Placeholder template | Slots | Reuse contextual slot |
| Item template | Contextual slots | Reuse |
| Refresh | Reload stream/provider data | Explicit refresh message that invalidates outstanding requests |
| Item size/overscan | App CSS/padding | Browser measurement effect plus deterministic estimates |
| Anchoring/prepend behavior | Stream limits and viewport events | P1 after basic fixed-height list; test scroll anchoring |

LiveView documentation describes streams plus viewport bindings as a
virtualized infinite list. It is a valuable server-side approach, but it is not
identical to Blazor `Virtualize`: the latter calculates a visible range and
spacer sizes from viewport/item geometry and asks an item provider for that
range. BlazeX local execution is well positioned to implement true viewport
virtualization because scroll/measurement events need not traverse the
network.

The P1 implementation should start with fixed or estimated item heights,
`IntersectionObserver`/`ResizeObserver` in the JavaScript host, overscan,
stable item keys, cancellation tokens represented by request generations, and
accessible total-position metadata where known. Variable-height, bidirectional
anchoring belongs to a later design maturity level.

### 11.2 QuickGrid family matrix

| Blazor component/contract | Phoenix/LiveView analogue | BlazeX disposition | Priority |
| --- | --- | --- | --- |
| `QuickGrid<TGridItem>` | App-specific table function components; no framework grid | **Build optional `blazex_grid` package** | P2 |
| `ColumnBase<TGridItem>` | Slot metadata / column map | **Diverge:** data-driven column protocol, no inheritance | P2 |
| `PropertyColumn<TGridItem,TProp>` | Value accessor function plus format metadata | **Build** | P2 |
| `TemplateColumn<TGridItem>` | Contextual column slot | **Reuse slots in a grid wrapper** | P2 |
| `Paginator` | Links/buttons over page state | **Build small component** | P1/P2 |
| `PaginationState` | Assign/map plus `handle_params` | **Build portable struct** | P1 |
| `GridItemsProvider` | Context/data function or server command | **Adapt:** local provider and authenticated server provider | P2 |
| `GridSort<T>` / sort state | Query params and validated sort keys | **Diverge:** stable public column IDs, never arbitrary field/module execution | P2 |

### 11.3 Why QuickGrid is not P0

A grid combines nearly every unresolved contract: contextual slots, dynamic
columns, keys, sorting, pagination, URL state, virtualization, async data,
cancellation, formatting, accessibility, and server trust. Building it first
would cause grid-specific choices to define the component kernel accidentally.

After P0/P1 are stable, a QuickGrid-inspired package becomes an excellent
integration test and performance benchmark. It should target common tabular
display rather than promise enterprise-grid features such as pivoting,
grouping, spreadsheet editing, arbitrary export, or column virtualization.

Server providers receive allowlisted public sort/filter IDs and pagination
bounds. They never accept serialized Elixir functions, Ecto query AST, or raw
database column names from the browser.

## 12. Browser events, JavaScript interop, CSS, and packages

### 12.1 Component-by-component/feature matrix

| Blazor component/feature | Phoenix/LiveView analogue | Local-runtime evidence | BlazeX disposition | Priority |
| --- | --- | --- | --- | --- |
| Browser `EventArgs` classes | Selected event metadata maps from LiveView bindings | Local event decoder observed; extra mouse/drag bindings observed in JS | **Diverge:** versioned serializable event maps | P0 |
| Custom event handlers | Custom `phx-*`/hook push events | JS bridge can push to local process | **Adapt:** registered event schemas | P1 |
| `IJSRuntime` calls | Hooks, `push_event`, `Phoenix.LiveView.JS` | Popcorn `run_js`, opaque tracked objects, stock hooks | **Adapt:** declared effects/capabilities | P0 |
| `IJSObjectReference` | Hook-owned JS object or opaque bridge handle | Popcorn tracked objects exist | **Build:** generation-scoped opaque handles with disposal | P1 |
| `.razor.js` collocation | `ColocatedHook` and `ColocatedJS` extracted at compile time | Child hook processing is visible; local collocated build path not verified | **Reuse Phoenix compiler where possible; verify local bundles** | P1 |
| `ErrorBoundary` logging through browser/server | Telemetry/logging hooks | Limited AtomVM debugging | **Build structured host telemetry** | P1 |
| CSS isolation (`.razor.css`) | No direct Phoenix build feature; ordinary classes/assets | Absent | **Build optional HEEx/CSS scope transform** | P2 |
| Razor class library static assets | Hex package `priv/static`, Phoenix static assets, JS/CSS manifests | Installer copies/builds runtime assets | **Build package manifest convention** | P1 |
| `EnvironmentBoundary` | Host capability condition | Loader knows server/local/static context | **Adapt** | P1 |
| `ImportMap`, `ResourcePreloader` | Endpoint/layout and bundler outputs | JS host owns module loading | **Adapt as build/host services** | P2 |

### 12.2 Event schemas should be smaller than DOM events

Blazor publishes typed event-argument classes. LiveView sends selected fields.
LocalLiveView's inspected JavaScript adds metadata for pointer/mouse/drag events
that stock bindings do not cover in the same way. BlazeX should standardize a
minimal, versioned map per event family:

```elixir
%{
  "client_x" => 120,
  "client_y" => 44,
  "button" => 0,
  "buttons" => 1,
  "alt" => false,
  "ctrl" => false,
  "meta" => false,
  "shift" => false
}
```

Do not serialize an entire DOM `Event`, target element, clipboard, drag data,
or file object. Capabilities with privacy or large-data implications need
separate permissioned effects. High-frequency events require coalescing or
throttling before they cross `postMessage` into AtomVM.

### 12.3 Capability effects instead of ambient JavaScript

The portable API should prefer:

```elixir
socket
|> effect(:focus, selector: "#email")
|> effect(:scroll_into_view, selector: "#error-summary", block: :nearest)
|> effect(:clipboard_write, text: value)
|> effect(:measure, selector: "#list", reply_to: :list_measured)
```

Each capability declares:

- input and result schema;
- whether it is valid during server render, local mount, and after patch;
- privacy/security category;
- cancellation and timeout behavior;
- opaque-handle ownership;
- fallback when JavaScript or the capability is unavailable;
- test implementation.

An escape hatch may register an application JavaScript module under a stable
capability name. Arbitrary JavaScript source strings are not a package-level
portable API even if Popcorn can evaluate them.

### 12.4 CSS isolation is useful but optional

Blazor rewrites selectors and stamps scope attributes on component output.
Phoenix applications commonly use utility classes, CSS modules through their
bundler, or explicit component classes. BlazeX can work without CSS isolation.

If implemented, the transform must understand:

- HEEx roots, multiple roots, conditional roots, and child slots;
- `::deep`-like descendant rules or a deliberately different syntax;
- deterministic scope IDs across server render and local activation;
- package CSS bundling and content hashes;
- CSP and source-map behavior;
- global keyframes, custom properties, and layer ordering;
- lazy bundle load/unload policy.

Because styling can be solved conventionally and a bad transform damages SSR,
this belongs in P2.

### 12.5 Hex component packages need an explicit client manifest

A Razor class library can package components, isolated CSS, JavaScript, and
static web assets. A normal Hex package can already contain BEAM modules and
`priv` assets, but BlazeX needs to know which pieces are safe and reachable in
the browser.

Each client-capable package should declare:

- public component IDs and modules;
- client entrypoints and dynamic component roots;
- required BlazeX, renderer, AtomVM, Popcorn, Elixir, and OTP ranges;
- browser capabilities/effects;
- static JS/CSS/assets and hashes;
- host adapters and optional server command handlers;
- NIF/server-only exclusions;
- CSP, COOP/COEP, cross-origin, and license implications.

Installing a package must not automatically expose every module in the
package—or its transitive server dependencies—to the client bundle.

## 13. Proposed BlazeX framework packages

The framework should be split by responsibility. None of these packages is a
Blazor adapter or clone; each exposes native Elixir/Phoenix APIs.

### 13.1 `blazex_core` — P0

- `BlazeX.LocalView` behavior and renderer facade;
- prop schema, host/local boundary validation, defaults, and required props;
- function and live component support through Phoenix.Component/LiveComponent;
- slots and contextual slots;
- dynamic component registry and manifest roots;
- identity/key conventions;
- local events, messages, browser effects, and server commands;
- process-root error fallback and retry generation;
- host/render capability query;
- deterministic lifecycle traces for BlazeX contract tests.

### 13.2 `blazex_web` — P0/P1

- layout helpers;
- title effect;
- link/navigation service over hosted and standalone LocalLiveView paths;
- active `nav_link`;
- focus-after-navigation and navigation locks;
- scoped context;
- section provider/outlet;
- allowlisted head manager;
- browser effect implementations;
- P1 viewport virtualizer.

### 13.3 `blazex_form` — P0/P1

- client-safe `FormState` and `Field` structs;
- form component and standard form event decoding;
- basic text, textarea, hidden, checkbox, select, radio, and numeric inputs;
- P1 date/time and file inputs;
- labels, hints, field messages, summary, and configurable state classes;
- pure validation behavior and adapters for normalized server errors;
- draft persistence and reconnect/remount recovery policy.

### 13.4 `blazex_auth` — P1

- sanitized public authentication-state contract;
- `authorized_view` presentation component;
- host policy adapter and revocation/version events;
- route-denied/loading slots;
- prominent server-enforcement rules and secure command integration.

This package does not implement an identity provider, password storage, token
issuer, or universal OAuth client.

### 13.5 `blazex_grid` — P2

- portable `PaginationState`;
- table/grid shell with accessibility defaults;
- property and contextual template columns;
- stable sort/filter public IDs;
- local and server item providers;
- optional pagination and P1 virtualizer integration.

### 13.6 `blazex_assets` / build integration — P1/P2

- component and bundle manifest;
- Hex package client entrypoint convention;
- static asset collection, hashes, preload hints, and lazy bundles;
- dynamic-dispatch reachability declarations;
- optional scoped CSS transform;
- colocated hook/JavaScript integration;
- server-only/NIF/unsupported-call diagnostics.

## 14. The P0 BlazeX design baseline

A first public release should make a narrower promise than “all Blazor
components.” The following contract is both useful and testable.

### 14.1 Supported authoring behavior

- HEEx function components with declared attrs, global attrs, default/named
  slots, and contextual slots;
- nested Phoenix LiveComponents inside one local-view process;
- local views with `mount`, `update`, `handle_event`, `handle_info`, and
  `render`;
- build-declared dynamic component selection;
- keyed lists and stable LiveComponent IDs;
- raw HTML only through an explicit trusted/sanitized escape hatch;
- browser effects through registered capabilities;
- server work only through declared command schemas.

### 14.2 Initial BlazeX facilities

- slot-based layouts and a host-coordinated page title;
- `link`/`push_patch` behavior on supported hosted and standalone routes;
- form, text, textarea, hidden, checkbox, select, radio group, number, label,
  validation message, and validation summary;
- local-root error fallback and user-triggered retry;
- standard click, input/change, submit, focus, keyboard, and bounded pointer
  event schemas.

### 14.3 Explicit P0 non-guarantees

- no arbitrary Ecto changesets or database code in the browser;
- no file-upload facility yet;
- no generic component type inference;
- no mutable child instance references;
- no full client-side page router;
- no subtree error boundary inside one local-view process;
- no arbitrary document-head mutation;
- no QuickGrid or CSS isolation guarantee;
- no server-render activation/hydration guarantee;
- no claim that every Phoenix.LiveView API works under LocalLiveView;
- no security guarantee from hidden UI or local policy results.

## 15. Illustrative API translations

These examples are design sketches, not implemented APIs.

### 15.1 Parameter, event, and child content

Blazor intent:

```razor
<Counter Start="10" CountChanged="OnCountChanged">
    <Label>Cart items</Label>
</Counter>
```

BlazeX-shaped HEEx:

```elixir
<.live_component
  module={Counter}
  id="cart-counter"
  start={10}
  notify={@myself}
>
  <:label>Cart items</:label>
</.live_component>
```

The child emits a named message/event to `notify`; it does not receive a
serialized function from the Phoenix server.

### 15.2 Dynamic component

```elixir
<.dynamic
  component={@card_kind}
  id={@card_id}
  props={%{item: @item}}
/>
```

`@card_kind` is a stable manifest ID, not an arbitrary module string. The
runtime resolves it within the currently loaded bundle and checks the declared
prop schema.

### 15.3 Context

```elixir
<.context name={:theme} value={%{mode: :dark}} fixed>
  <.dashboard />
</.context>
```

Consumers declare the context dependency. Context remains within one renderer
root unless the host explicitly serializes a public value into another root.

### 15.4 Form and server validation

```elixir
<BlazeX.Form.form
  for={@form}
  phx-change="validate"
  phx-submit="save"
>
  <BlazeX.Form.text field={@form[:email]} />
  <BlazeX.Form.number field={@form[:age]} />
  <BlazeX.Form.validation_summary form={@form} />
</BlazeX.Form.form>
```

Pure format/range validation can run locally. `save` becomes a declared server
command. The authoritative reply may return normalized field errors and a
record version.

### 15.5 Authorization-aware presentation

```elixir
<BlazeX.Auth.authorized_view
  policy={:edit}
  subject={@public_document}
>
  <:allowed><button phx-click="save">Save</button></:allowed>
  <:denied><p>You cannot edit this document.</p></:denied>
</BlazeX.Auth.authorized_view>
```

The `save` server command repeats authorization using trusted identity and
server-loaded document state.

### 15.6 Virtualized list

```elixir
<BlazeX.Web.virtualize
  id="orders"
  provider={:orders}
  item_key={:id}
  estimate_px={48}
  overscan={5}
>
  <:item :let={order}><.order_row order={order} /></:item>
  <:placeholder :let={range}><.rows_skeleton count={range.count} /></:placeholder>
</BlazeX.Web.virtualize>
```

`:orders` resolves to a build-declared local or server provider. Server
requests carry bounded range, sort, and filter IDs, not executable code.

## 16. BlazeX contract validation program

### 16.1 One manifest row per contract

The repository should eventually maintain a machine-readable matrix rather
than only this prose. Each row needs:

```yaml
id: forms.input-number
blazor:
  api: Microsoft.AspNetCore.Components.Forms.InputNumber<TValue>
  baseline: 10.0
blazex:
  module: BlazeX.Form.Number
  level: adapted
  since: null
hosts: [phoenix-live, phoenix-local]
local_runtime: experimental
tests:
  - invalid-intermediate-value
  - range-overflow
  - focused-patch
security:
  authority: client-advisory
```

Documentation can render tables from this manifest, while CI can reject a
claim that lacks tests or a supported-version row.

### 16.2 Test hosts

Every P0 component scenario should run in at least:

1. ordinary Phoenix static/server render where applicable;
2. Phoenix LiveView server interaction;
3. LocalLiveView under browser AtomVM;
4. standalone local route when the feature claims Plug portability;
5. JavaScript-disabled/static fallback for essential content;
6. future prerender/activation mode only after P3 begins.

The same BlazeX fixture need not use the same internal state object across
hosts. It must satisfy BlazeX's declared normalized-HTML, accessibility,
event-outcome, and failure-behavior contracts.

### 16.3 Test dimensions by family

| Family | Required evidence |
| --- | --- |
| Props/slots | Required/default/invalid props, global attrs, nested/contextual slots, escaping |
| Dynamic components | Unknown ID, lazy bundle, missing prop, tree-shake retention, disposal |
| Lifecycle | Callback order, async completion, removal, crash, remount, stale generation |
| Identity | Append/prepend/reorder/delete, duplicate keys, focused child preservation |
| Forms | Raw/typed values, touched/dirty, errors, focus/caret, submit, reset, reconnect |
| Navigation | Hosted/standalone patch, back/forward, replace, full reload, focus, blocker |
| Auth | loading/allowed/denied UI and independent server-command rejection |
| Errors | component crash, renderer crash, VM crash, retry loop prevention |
| Virtualization | visible range, overscan, cancellation, resize, prepend anchor, accessibility |
| Interop | capability allowlist, timeout, disposal, stale handle, CSP, no-JS fallback |
| Packaging | deterministic manifest, unsupported dependency, asset collision, lazy load |

### 16.4 Differential and golden evidence

For reusable HEEx modules, run the same component under BEAM and AtomVM and
record:

- callback trace;
- normalized initial render tree;
- event payload and final assigns;
- emitted diff;
- final DOM snapshot;
- browser effects in order;
- process exit/restart trace.

Blazor itself is not a CI oracle. During design, a small research fixture may
demonstrate how selected Blazor examples address dynamic composition, form
validation, navigation focus, error retry, virtual lists, and grids. BlazeX
tests must then assert BlazeX's independently documented behavior, not output
parity with .NET or framework-private wire formats.

### 16.5 Accessibility is part of the BlazeX contract

The suite must include keyboard-only navigation, focus order, label/control
association, validation announcements, route-change focus, live-region use,
grid roles, and screen-reader smoke tests. A BlazeX component is defective if
it looks correct while losing route-change focus or error relationships.

## 17. Delivery sequence and exit gates

### Phase A — inventory lock and executable P0 matrix

Deliver:

- checked-in machine-readable capability rows;
- exact framework/toolchain versions;
- P0 API names and non-goals;
- one minimal fixture for every P0 row;
- unsupported API diagnostics rather than silent no-ops.

Exit gate: every P0 claim is documented, has at least one Phoenix and local
test, and distinguishes browser advisory state from server authority.

### Phase B — core, forms, and host effects

Deliver:

- prop schemas, dynamic registry, identity model, lifecycle/disposal;
- browser capability layer;
- `FormState` and basic controls;
- title/navigation adapter and process-root fallback;
- secure typed command path.

Exit gate: a nontrivial form-oriented application works server-live and local,
survives remount/reconnect, and cannot bypass server validation/authorization.

### Phase C — P1 framework facilities

Deliver:

- context, sections/head, active links, focus and locks;
- date/file inputs and upload adapters;
- public auth state and advisory authorization view;
- fixed/estimated-height virtualization;
- package manifests and lazy assets.

Exit gate: each feature works in its claimed host set and has deterministic
cleanup, accessibility, and failure behavior.

### Phase D — optional libraries and SSR

Deliver independently:

- `blazex_grid` reference package;
- CSS isolation experiment;
- state persistence and server-render activation;
- Plug WebSocket/realtime facilities only where product demand justifies them.

Exit gate: optional packages do not expand the P0 runtime surface implicitly,
and SSR does not duplicate effects or lose form/focus state.

## 18. Decisions and unresolved questions

### 18.1 Recommended decisions now

1. Define native Elixir/Phoenix semantics; make no .NET or Blazor
   compatibility promise of any kind.
2. Keep Phoenix as route, auth, upload, and trusted-command authority.
3. Use function components by default, LiveComponents for nested state, and
   local views for process/failure boundaries.
4. Own a client-safe form state rather than port Ecto wholesale.
5. Treat browser operations as declared effects with lifecycle ownership.
6. Bound dynamic components through build manifests.
7. Ship a root error fallback before claiming subtree error boundaries.
8. Implement measured virtualization before QuickGrid.
9. Keep design-system controls outside the core framework contract.
10. Generate published BlazeX capability documentation from executable
    metadata.

### 18.2 Questions that require experiments

- Which Phoenix.Component/LiveComponent features pass unchanged under the
  pinned LocalLiveView/AtomVM stack, including contextual slots, keyed
  comprehensions, streams, colocated hooks, and `send_update`?
- What exact callback/disposal sequence occurs when a local root is removed by
  a Phoenix DOM patch, browser navigation, process crash, or VM restart?
- Can a public renderer extension point replace LocalLiveView's private module
  dependencies without losing component deletion, hooks, and form behavior?
- Which date/time, numeric, regex, Unicode, protocol, and localization
  facilities are reliable in the BlazeX browser-runtime profile?
- Can Phoenix's upload client be safely targeted by a local root, or should
  BlazeX own a separate uploader protocol?
- Does `@page_title` propagate correctly from local diffs in hosted and
  standalone modes, or must all title changes use a custom host effect?
- Can streams and viewport bindings run locally without server assumptions,
  and how do they compare with a dedicated observer-based virtualizer?
- How are colocated hooks and package JavaScript discovered when the component
  lives in the separate LocalLiveView client project?
- What payload and startup cost does each framework package add after tree
  shaking?
- Which P1 features remain feasible under plain Plug without importing most of
  Phoenix LiveView?

## 19. Final assessment

This design study supports building BlazeX as a Phoenix-shaped component
framework, not as a Blazor port or compatibility layer. The hard and valuable parts of
Blazor's component experience are not C# syntax. They are stable composition,
predictable identity and lifecycle, typed-enough forms, host coordination,
contained failures, accessible navigation, efficient large-list rendering,
and a package contract. Phoenix and LiveView already cover much of that model,
and LocalLiveView demonstrates the central local render/event loop under a
WebAssembly-hosted AtomVM.

The gaps are specific enough to plan. P0 should concentrate on the component
kernel, a portable form model, browser effects, secure server commands, and
process-root recovery. P1 adds the cross-tree and browser-heavy facilities.
QuickGrid, CSS isolation, remote-auth UI, and SSR belong after those foundations
have executable BlazeX contract evidence.

This approach also respects the earlier terminology correction. BlazeX UI
components would be Elixir modules and HEEx render units packaged as BEAM
bytecode for a shared Wasm-hosted runtime. They would not each be a WebAssembly
Component Model binary. Similarity to Blazor ends at selected design lessons;
it does not establish compatibility with Razor components, assemblies, APIs,
packages, lifecycle contracts, or the .NET renderer.

## Appendix A: public built-in inventory checklist

This checklist prevents prominent framework components from disappearing
inside grouped analysis. “Covered” points to the section in this note rather
than claiming implementation.

| Namespace/family | Public component types or component-facing contract | Covered in |
| --- | --- | --- |
| Core | `ComponentBase`, `IComponent`, parameters, callbacks, render fragments | Sections 4–5 |
| Core | `CascadingValue<T>`, cascading parameters/type parameters | Section 4 |
| Core | `DynamicComponent` | Section 4 |
| Core | `LayoutComponentBase`, `LayoutView` | Section 6 |
| Core | `RouteView`, `NavigationManager`, route/query supply | Section 7 |
| Core | `ConfigureBrowser`, `ImportMap`, `ResourcePreloader` | Sections 6 and 12 |
| Core | persistent state and stream rendering | Section 6 |
| Routing | `Router`, `NavLink`, `FocusOnNavigate`, `NavigationLock` | Section 7 |
| Forms | `EditForm`, `EditContext`, `InputBase<T>` | Section 8 |
| Forms | `InputText`, `InputTextArea`, `InputHidden` | Section 8 |
| Forms | `InputCheckbox`, `InputNumber<T>`, `InputDate<T>` | Section 8 |
| Forms | `InputSelect<T>`, `InputRadio<T>`, `InputRadioGroup<T>` | Section 8 |
| Forms | `InputFile` | Section 8 |
| Forms | `Label<T>`, `DisplayName<T>`, `Editor<T>` | Section 8 |
| Forms | `DataAnnotationsValidator`, `ValidationMessage<T>`, `ValidationSummary` | Section 8 |
| Forms | `AntiforgeryToken`, `FormMappingScope` | Section 8 |
| Authorization | `AuthorizeView`, `AuthorizeViewCore`, `AuthorizeRouteView` | Section 9 |
| Authorization | `CascadingAuthenticationState`, authentication provider | Section 9 |
| WASM authentication | `RemoteAuthenticatorView`, `RemoteAuthenticatorViewCore<T>` | Section 9 |
| Web | `ErrorBoundary`, `ErrorBoundaryBase` | Section 10 |
| Web | `PageTitle`, `HeadContent`, `HeadOutlet` | Section 6 |
| Web | `EnvironmentBoundary` and interactive render modes | Sections 5–6 |
| Sections | `SectionContent`, `SectionOutlet` | Section 6 |
| Virtualization | `Virtualize<TItem>` and item-provider contracts | Section 11 |
| QuickGrid | `QuickGrid<T>`, `ColumnBase<T>`, `PropertyColumn<T,TProp>`, `TemplateColumn<T>` | Section 11 |
| QuickGrid | `Paginator`, `PaginationState`, provider/sort contracts | Section 11 |
| Build/browser | CSS isolation, collocated JS, RCL assets, event args, JS interop | Section 12 |

## Appendix B: product-level controls absent from basic Blazor

The following common UI controls require application code, HTML/CSS, a
project template, or a third-party library in Blazor. They are not evidence
that BlazeX should omit or externally delegate those controls. They are now
covered by the [MudBlazor-inspired component-system
study](mudblazor-inspired-component-system-for-blazex.md), which treats
MudBlazor v9.9.0 as the target catalog while defining independent Elixir,
Phoenix, HEEx, CSS, state, and host contracts:

- styled buttons, badges, cards, alerts, and navigation shells;
- modal/dialog, popover, tooltip, menu, tabs, accordion, carousel;
- rich select/autocomplete, calendar/date picker, color picker, slider;
- tree, chart, map, editor, spreadsheet, scheduler;
- toast/notification service;
- enterprise data-grid behavior beyond the bounded QuickGrid reference scope;
- application login/register/profile pages.

That product-level study chooses the catalog, accessibility patterns, styling
tokens, controlled-state conventions, overlays, forms, and package sequence.
The present note remains relevant only to the component/runtime substrate
beneath it.

## Connections

- [Elixir WebAssembly component framework for Phoenix and Plug](elixir-webassembly-component-framework-for-phoenix-and-plug.md) — parent architecture study and runtime recommendation.
- [MudBlazor-inspired component system for BlazeX](mudblazor-inspired-component-system-for-blazex.md) — the actual product-level component catalog, architecture, and roadmap.
- [Host-neutral BlazeX architecture and native control backends](host-neutral-blazex-architecture-and-native-control-backends.md) — renderer-neutral amendment and native-control target.
- [Blazor framework semantics map](../10-maps/blazor-framework-semantics.md) — curated path through this lower-level design inventory and its evidence.
- [Which foundational component semantics does BlazeX need?](../40-inquiries/which-foundational-component-semantics-does-blazex-need.md) — executable runtime and framework questions that remain open.
- [2026-09-02 component semantics deep dive](../50-journal/2026-09-02-blazor-component-semantics-deep-dive.md) — source baselines, local inspection, and evidence boundaries.

## Sources

### Blazor

- [Blazor component contracts, composition, styling, and interop](../30-sources/microsoft-2026-blazor-component-contracts-styling-and-interop.md)
- [Blazor forms, routing, and authorization components](../30-sources/microsoft-2026-blazor-forms-routing-and-authorization-components.md)
- [Blazor layouts, sections, errors, virtualization, and QuickGrid](../30-sources/microsoft-2026-blazor-layout-sections-errors-virtualization-and-quickgrid.md)
- [Blazor render modes and components](../30-sources/microsoft-2026-blazor-render-modes-and-components.md)
- [ASP.NET Core component renderer source](../30-sources/dotnet-project-2025-aspnetcore-component-renderer-source.md)

### Phoenix and the browser-local runtime

- [Phoenix LiveView UI foundation surfaces](../30-sources/phoenix-framework-2026-liveview-ui-foundation-surfaces.md)
- [Phoenix LiveView lifecycle and renderer](../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md)
- [LocalLiveView first release and implementation](../30-sources/software-mansion-2026-local-live-view-first-release.md)
- [Popcorn architecture and limitations](../30-sources/software-mansion-2026-popcorn-documentation-and-source.md)
- [AtomVM WebAssembly runtime](../30-sources/atomvm-project-2026-webassembly-runtime.md)
