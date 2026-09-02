---
title: "Browser host implementation milestones"
kind: note
created: "2026-09-02"
maturity: developing
tags:
  - browser
  - component-library
  - phoenix
  - roadmap
  - webassembly
aliases:
  - "BlazeX browser roadmap"
  - "Browser-host milestones"
---

# Browser host implementation milestones

## Purpose

This roadmap consolidates the current BlazeX research into one ordered program
for the first production host: the web browser. It combines the runtime and
Phoenix plan, the host-neutral renderer gates, the framework-semantics study,
and the MudBlazor-inspired component delivery tiers.

The milestones describe outcomes, boundaries, and completion signals. They do
not prescribe sprint sizes, staffing, dates, internal module layouts, or exact
APIs. Several milestones can overlap once their prerequisites are stable, but
none should be declared complete merely because a demonstration works on one
developer machine.

The browser is the first implementation and quality baseline, not the
definition of the component model. Portable components continue to target
semantic UI, events, effects, resources, and capabilities. Popcorn, AtomVM,
Phoenix, LiveView, HEEx, JavaScript, CSS, and the DOM remain browser-profile
adapters. MudBlazor v9.9.0 remains the catalog and interaction reference; this
roadmap creates no .NET, Razor, package, API, binary, or renderer compatibility
goal.

## What browser-host completion means

At the end of this program, BlazeX should provide a coherent browser product
rather than only a WebAssembly runtime experiment. An application should be
able to author idiomatic Elixir components, execute eligible interaction logic
locally in a browser-hosted AtomVM runtime, render through an accessible DOM
backend, and cross a Phoenix or Plug boundary through explicit untrusted-data
contracts.

The completed browser profile should include:

- a stable host-neutral component and semantic-rendering contract;
- reproducible browser execution through a pinned and supported runtime stack;
- a Phoenix-first host with secure commands, server pushes, navigation, and
  deployment integration;
- a smaller documented Plug hosting profile;
- a BlazeX-owned design system and component catalog inspired by MudBlazor;
- forms, navigation, surfaces, browser capabilities, data components, and
  optional advanced packages;
- deterministic failure, reconnect, persistence, and deployment behavior;
- server prerender and safe interactive activation where claimed;
- package, asset, lazy-loading, diagnostics, and upgrade tooling; and
- published browser, accessibility, security, payload, performance, and
  compatibility guarantees backed by repeatable evidence.

## Program shape

| Horizon | Milestones | Outcome |
| --- | --- | --- |
| Direction and proof | BH-00 through BH-02 | Product scope, feasibility, and portable contracts are credible before the public API expands. |
| Browser platform | BH-03 through BH-07 | Elixir components can boot, render, update, build, and communicate securely through Phoenix. |
| Product surface | BH-08 through BH-14 | The shared UI foundations and principal MudBlazor-inspired component families form a useful application framework. |
| Browser completeness | BH-15 through BH-20 | Resilience, data systems, activation, packages, and Plug support move the platform beyond an MVP. |
| Productization | BH-21 through BH-23 | Tooling, evidence, hardening, and release governance support a dependable public product. |

The sequence is dependency-oriented rather than strictly serial. For example,
security, accessibility, tests, documentation, and performance measurement
begin in the earliest milestones even though later milestones provide their
full product-wide release gates.

## Horizon 0 — Direction and proof

### BH-00 — Product boundary, catalog, and acceptance contract

**Goal.** Establish one unambiguous definition of the browser product before
implementation choices become accidental public commitments. This milestone
turns the research vocabulary, non-goals, quality assumptions, and MudBlazor
family inventory into a governed product contract.

**What needs to be accomplished.** Freeze the distinction among runtime,
host, renderer, capability provider, remote adapter, and packaging shell.
Declare the initial browser and toolchain support envelope, the Phoenix-first
and Plug-secondary product boundary, and the meaning of server, local, static,
and activated rendering claims. Give every MudBlazor v9.9.0 family an explicit
BlazeX disposition, delivery tier, capability need, fallback expectation, and
portability status. Record the initial quality budgets and the decisions that
must be maintained as architecture records.

**Completion signal.** Every planned feature and component claim can be traced
to a versioned catalog row and an observable acceptance condition. The catalog
contains no implied .NET compatibility and no ambiguous promise that browser
support automatically means native-host support.

### BH-01 — Reproducible browser feasibility baseline

**Goal.** Prove that the selected browser dependency stack is reproducible and
worth building upon before BlazeX adds abstraction and product surface.

**What needs to be accomplished.** Produce a pinned Phoenix, LiveView,
LocalLiveView, Popcorn, AtomVM, Elixir, and Erlang baseline that can be built on
a clean machine. Exercise representative state, nested components, form
events, timers or messages, DOM updates, and one authenticated server command.
Record emitted artifacts, private dependency risks, runtime limitations,
browser prerequisites, and cold and warm measurements on representative
desktop and mobile environments.

**Completion signal.** The baseline runs repeatably across the initially
supported browser set, its build inputs and outputs are explainable, and its
known compatibility restrictions are narrow enough to support a framework.
Failure to reproduce the exact runtime profile blocks later framework work.

### BH-02 — Host-neutral semantic kernel gate

**Goal.** Ensure the browser implementation does not define BlazeX in terms of
HTML, DOM events, LiveView renderer data, or Popcorn behavior.

**What needs to be accomplished.** Stabilize the first version of semantic UI
nodes, identity, events, effects, resources, layout intent, tokens,
accessibility, renderer lifecycle, and capability negotiation. Provide a
deterministic headless renderer, a minimal DOM lowering, and the limited
native-control experiment required by the existing research. The native work
is only a portability test for the public contracts; it is not a desktop-host
delivery milestone. Add dependency checks and shared behavior traces that
expose browser-specific leakage before the API grows.

**Completion signal.** The same small interaction set—layout, action, field,
selection, keyed list, surface, focus, file choice, and disposal—passes the
headless, DOM, and native-spike contracts without browser or toolkit objects in
portable component code.

## Horizon 1 — Browser platform

### BH-03 — Browser runtime host and boot lifecycle

**Goal.** Turn the pinned runtime proof into a dependable page-level browser
host capable of serving multiple component roots.

**What needs to be accomplished.** Define runtime discovery, manifest
validation, feature detection, startup, root registration, bundle loading,
readiness, shutdown, and fallback behavior. A page should share an appropriate
runtime instance, support roots added after initial page load, reject
incompatible builds, and expose deterministic behavior when browser
requirements such as cross-origin isolation are not met.

**Completion signal.** Multiple independent roots can mount, update, move,
dispose, and remount without duplicate runtimes or leaked ownership. Startup
failures and unsupported browser configurations produce intentional fallback
UI and diagnostics rather than partial operation.

### BH-04 — DOM renderer and interaction transport

**Goal.** Establish the browser's reference renderer as a versioned adapter
from BlazeX semantics to accessible DOM behavior.

**What needs to be accomplished.** Cover initial rendering, incremental
updates, keyed identity, event normalization, form value transport, focus and
selection preservation, effect ordering, stale-message rejection, root
ownership, and cleanup. Bound the version coupling to LiveView or
LocalLiveView inside the adapter and define how malformed or incompatible
renderer traffic fails.

**Completion signal.** Deterministic renderer fixtures and browser scenarios
produce the documented DOM, accessibility, event, focus, and disposal
outcomes. Application components depend only on BlazeX contracts, while the
renderer adapter is the sole package coupled to browser patching internals.

### BH-05 — Component programming model and lifecycle

**Goal.** Provide an idiomatic Elixir component model that remains familiar to
Phoenix developers while being precise enough for local browser execution.

**What needs to be accomplished.** Define the roles of pure composition,
nested stateful components, and process-root local views. Complete prop and
slot validation, controlled and local state, identity, messages, local events,
lifecycle, context boundaries, dynamic component registration, errors,
retries, and deterministic disposal. Clearly separate local events from
remote commands and public browser state from trusted server state.

**Completion signal.** The supported component semantics have matching BEAM
and browser-AtomVM contract evidence, including ordering, identity, updates,
failures, and final state. Public application code does not import private
runtime or renderer modules.

### BH-06 — Build, compatibility, and client-safety pipeline

**Goal.** Make a browser release inspectable and safe to assemble instead of
depending on manual knowledge about what may run under AtomVM.

**What needs to be accomplished.** Establish explicit client entrypoints,
reachability analysis, unsupported dependency checks, compatibility profiles,
deterministic feature bundles, versioned manifests, content-addressed assets,
size reporting, and production integrity metadata. The build should expose why
code and assets are present and prevent server-only modules, native
dependencies, secret-bearing configuration, or undeclared dynamic dispatch
from silently reaching the client.

**Completion signal.** Equivalent inputs produce equivalent manifests and
artifacts, unsupported code fails with actionable diagnostics, and reviewers
can account for the runtime, application code, assets, licenses, and payload of
every browser entrypoint.

### BH-07 — Phoenix host and trusted command boundary

**Goal.** Make Phoenix the complete reference host for browser delivery and
the authoritative boundary for protected data and operations.

**What needs to be accomplished.** Provide application embedding, static asset
delivery, bootstrap state, sessions, CSRF and origin handling, typed commands,
replies, server pushes, reconnect, routing ownership, and deployment-version
coordination. Define how Phoenix controllers and LiveViews host local roots and
how ordinary application contexts authenticate, validate, authorize, execute,
and audit client requests.

**Completion signal.** A reference application combines server-rendered and
browser-local UI, continues local interaction during bounded network loss, and
cannot use modified client state or forged commands to bypass server policy.
The end-to-end path has correlated diagnostics on both sides of the boundary.

## Horizon 2 — Product surface

### BH-08 — Theme, layout, accessibility, and provider foundation

**Goal.** Build the shared design-system substrate before multiplying
component count.

**What needs to be accomplished.** Define BlazeX-owned themes, semantic
tokens, typography roles, spacing, shape, elevation, motion, density,
direction, responsive state, and bounded layout intent. Establish the common
component contract, controlled-state conventions, accessibility semantics,
focus and keyboard primitives, icon and asset strategy, provider/context
boundaries, and visual-profile policy. Produce a reference gallery and
BlazeX-owned visual baselines.

**Completion signal.** Foundation examples behave consistently under server
LiveView and browser-local rendering across theme, direction, responsive,
keyboard, and accessibility states. The foundation has a measured payload and
does not require arbitrary CSS or DOM access from portable components.

### BH-09 — Presentational and action component core

**Goal.** Deliver the first broadly useful MudBlazor-inspired component set on
top of shared foundations rather than as isolated widgets.

**What needs to be accomplished.** Cover the principal typography, icon,
image, paper, container, stack, grid, divider, skeleton, application-bar,
toolbar, card, button, icon-action, alert, avatar, badge, chip, progress,
simple list, link, and basic table experiences selected by the catalog. Define
states, variants, composition, disabled and busy behavior, accessibility, and
static fallback for each family.

**Completion signal.** A documented gallery demonstrates the declared visual
core under server and browser-local execution, with stable semantic output,
keyboard behavior, responsive behavior, accessibility checks, and per-family
payload accounting.

### BH-10 — Forms, fields, validation, and selection controls

**Goal.** Make BlazeX capable of building serious data-entry applications
without importing server-only form state into the browser.

**What needs to be accomplished.** Own a client-safe form and field model that
preserves raw and parsed values, touched and dirty state, conversion failures,
local validation, normalized server errors, submission state, reset, and
revision handling. Deliver the catalog's core text, numeric, multiline,
hidden, checkbox, switch, radio, slider, select, autocomplete, and related
label, hint, message, and summary experiences.

**Completion signal.** A nontrivial accessible form works in server-live and
browser-local modes, preserves invalid intermediate input and focus, survives
reconnect or remount according to policy, and treats all authoritative
validation and mutation results as server decisions.

### BH-11 — Navigation, layout, and application composition

**Goal.** Support complete browser applications rather than disconnected
component islands.

**What needs to be accomplished.** Define layouts and shells, hosted and local
navigation, links and active state, breadcrumbs, pagination, navigation menus,
expansion, tabs, steppers, page-title and allowlisted head effects, sections,
focus after navigation, navigation locks, browser history, and root ownership
during page changes. Clarify which router remains authoritative in each
deployment profile.

**Completion signal.** A multi-page reference application handles forward,
back, replace, patch, full navigation, canceled navigation, root insertion and
removal, and focus restoration without competing DOM ownership or abandoned
component state.

### BH-12 — Surface, overlay, and transient-feedback system

**Goal.** Provide the shared surface infrastructure needed by the interactive
catalog before implementing every overlay component independently.

**What needs to be accomplished.** Establish a surface outlet, placement and
collision policy, stacking, modality, focus trapping and restoration, outside
interaction, scroll behavior, escape behavior, queueing, ownership, and
disposal. Build the selected popover, menu, tooltip, dialog, message box,
snackbar, overlay, and responsive drawer families on that common system.

**Completion signal.** Nested and concurrent surfaces behave predictably under
mouse, keyboard, touch, resize, navigation, root removal, process failure, and
runtime restart. No listener, timer, observer, focus claim, or opaque resource
survives its owning generation.

### BH-13 — Browser capabilities and host-heavy controls

**Goal.** Expose browser facilities through declared capabilities instead of
letting component code depend directly on JavaScript and Web APIs.

**What needs to be accomplished.** Complete the permission, ownership,
fallback, cancellation, timeout, and cleanup model for browser effects and
opaque resources. Cover the capabilities required by file choice, clipboard,
storage, measurement, viewport observation, scrolling, hotkeys, exit prompts,
drag and drop, gestures, and the selected date, range, time, color, carousel,
split-panel, and similar host-heavy component families.

**Completion signal.** Every supported operation is discoverable, bounded,
testable, and explicitly unavailable when the host cannot provide it. Custom
JavaScript extensions are named and declared; arbitrary script execution and
ambient browser handles are not part of the portable component model.

### BH-14 — Remote services, authorization presentation, and uploads

**Goal.** Supply reusable application-level patterns for components that
combine local interaction with Phoenix-authoritative data and services.

**What needs to be accomplished.** Define sanitized public authentication
state, advisory authorization-aware presentation, secure server command
patterns, server pushes, reconnect/version handling, remote item providers,
and file upload coordination. Establish conflict and stale-reply behavior so
late server results cannot overwrite newer local state. Keep identity,
authorization, persistence, protected data, and final mutations on the server.

**Completion signal.** Reference scenarios cover changing authentication,
revoked access, uploads, remote search or paging, server-originated updates,
reconnect, conflicts, and rejected commands. Hiding or disabling a component
is never presented as an authorization control.

## Horizon 3 — Browser completeness

### BH-15 — Resilience, offline behavior, and state recovery

**Goal.** Make failure and disconnection normal, specified application states
rather than exceptional demonstrations.

**What needs to be accomplished.** Define connectivity status, command retry
and idempotency, explicitly bounded offline behavior, persistence classes and
migrations, stale-tab handling, process and VM watchdogs, restart intensity,
root remount, deployment build mismatch, backgrounding, memory pressure, and
browser lifecycle recovery. Ensure failure scopes and user-visible recovery
choices are consistent across components.

**Completion signal.** The reference applications have deterministic UI and
telemetry for component crashes, renderer faults, VM loss, network loss,
server rejection, stale replies, incompatible deployments, and corrupted or
outdated persisted state. Recovery cannot loop indefinitely or silently lose
authoritative operations.

### BH-16 — Tables, provider contracts, trees, and virtualization

**Goal.** Establish scalable structured-content primitives before attempting
the full advanced grid.

**What needs to be accomplished.** Complete simple and templated tables,
stable row identity, local and remote provider contracts, paging, public sort
and filter identifiers, cancellation, loading and error states, tree views,
and measured viewport virtualization. Define keyboard, focus, announcement,
scroll anchoring, and nonvisual access for large or changing collections.

**Completion signal.** Large local and remote datasets remain responsive under
the published browser budgets, stale provider replies are rejected, server
queries remain bounded and authorized, and essential content and operations
are available to keyboard and assistive-technology users.

### BH-17 — Advanced data grid and visualization packages

**Goal.** Deliver the highest-complexity MudBlazor-inspired families as
independent products that do not distort or bloat the core framework.

**What needs to be accomplished.** Grow DataGrid through explicit capability
levels covering display and columns, sorting and paging, selection, filtering,
editing, grouping and aggregation, hierarchy, and virtualization. Define
optional chart packages by chart family, data contract, interaction model,
fallback, and accessibility strategy. Keep both systems independently
versioned and budgeted.

**Completion signal.** Applications opt into only the advanced capabilities
they use, remote operations remain declarative and authorized, performance
degrades predictably, and charts expose essential information through a
documented nonvisual representation.

### BH-18 — Server prerender, activation, and fallback modes

**Goal.** Provide fast and accessible first output while preserving the
browser-local interaction model after startup.

**What needs to be accomplished.** Progress from stable placeholders to
equivalent server prerender and then to true activation for the supported
component profile. Define deterministic rendering, public state envelopes,
identity and build matching, effect suppression during prerender, mismatch
recovery, no-JavaScript behavior, and family-specific static fallbacks.

**Completion signal.** Supported pages activate without visible subtree
replacement, duplicated data work or effects, lost form values, broken focus,
or accessibility regressions. A mismatch is diagnosable and safely falls back
instead of attaching to incompatible output.

### BH-19 — Hex packages, assets, and lazy feature bundles

**Goal.** Make reusable browser components distributable without hidden code,
asset, or compatibility consequences.

**What needs to be accomplished.** Establish package metadata for client
entrypoints, component contracts, capabilities, runtime and renderer support,
assets, licenses, server-only exclusions, and compatibility ranges. Support
route or feature bundles, lazy loading, prefetch, immutable caching, component
discovery, package conflicts, and third-party documentation. Define the review
and support expectations for ecosystem packages.

**Completion signal.** A third-party Hex package can contribute a documented
browser component without manual asset copying or accidental inclusion of its
entire server dependency graph. Installation produces an explainable manifest,
predictable payload, and explicit compatibility result.

### BH-20 — Plug hosting baseline

**Goal.** Demonstrate that the browser host is not inseparable from the full
Phoenix stack while keeping the initial Plug promise intentionally smaller.

**What needs to be accomplished.** Support hashed static assets, browser
runtime headers, signed bootstrap data, public props, typed HTTP commands,
host-provided session and authorization hooks, and clear fallback behavior in
an ordinary Plug application. Document which Phoenix capabilities—such as
Channels, PubSub, LiveView hosting, realtime, uploads, and prerender—are absent,
optional, or require separate adapters.

**Completion signal.** A representative browser-local application runs behind
Plug with secure request boundaries and no Phoenix application dependency.
The support matrix is explicit, and Plug does not silently inherit claims made
only for the Phoenix profile.

## Horizon 4 — Productization

### BH-21 — Developer experience, observability, and documentation

**Goal.** Make BlazeX understandable to application developers and diagnosable
when browser, runtime, renderer, or server layers disagree.

**What needs to be accomplished.** Provide project setup, development reload,
source-linked build errors, compatibility and payload reports, runtime and
process inspection, event/render/command traces, performance timelines,
redaction controls, browser and server telemetry correlation, and upgrade
guidance. Publish a component explorer, task-oriented guides, architecture and
security explanations, examples for every supported family, and migration
notes between supported releases.

**Completion signal.** A new project can reach a working application from the
published guide, and a developer can identify whether a failure belongs to
application state, AtomVM compatibility, a component, the renderer, a browser
capability, a bundle, or the server boundary without reading framework-private
source.

### BH-22 — Production quality and release-candidate gates

**Goal.** Convert feature completeness into measured confidence across the
actual browser product envelope.

**What needs to be accomplished.** Run the full cross-runtime, renderer,
build, Phoenix, Plug, browser, accessibility, security, supply-chain,
resilience, and performance programs. Cover supported Chromium, Firefox, and
WebKit releases, representative desktop and mobile devices, poor networks,
offline use, multiple tabs, history cache, backgrounding, CSP, cross-origin
assets, and deployment upgrades. Finalize payload, startup, interaction,
memory, accessibility, vulnerability-response, and compatibility policies.

**Completion signal.** Every release-blocking catalog row has current evidence
for its claimed modes; budgets have measured pass or consciously documented
exceptions; critical security and accessibility findings are closed; and the
supported-version matrix can be reproduced in continuous integration and
release qualification.

### BH-23 — Browser 1.0 release and ecosystem governance

**Goal.** Publish a stable browser-host product with bounded promises and a
maintainable path for subsequent hosts and component growth.

**What needs to be accomplished.** Freeze the first stable public contracts,
package split, compatibility policy, deprecation process, support window,
security reporting process, catalog coverage statement, visual profiles,
licenses and attribution, and upgrade path. Ship complete reference
applications demonstrating Phoenix-first local execution, server trust,
forms, navigation, surfaces, remote data, resilience, activation, packages,
and the documented Plug subset. Publish what is intentionally deferred or
omitted.

**Completion signal.** The browser release can be adopted using only public
interfaces and documented tooling, all 1.0 claims are generated from or linked
to executable evidence, and future desktop, native-control, or standalone-Wasm
work can implement new adapters without redefining the component kernel.

## Suggested public maturity checkpoints

These checkpoints communicate product maturity without turning individual
milestones into release dates:

| Checkpoint | Reached after | Meaning |
| --- | --- | --- |
| Technical preview | BH-07 | The browser runtime, renderer, component model, build, and Phoenix trust boundary work end to end. |
| Alpha | BH-10 | The platform supports a useful presentational core and nontrivial forms, but APIs and compatibility remain fluid. |
| Developer preview | BH-15 | Application composition, surfaces, browser capabilities, remote services, and deterministic recovery are available. |
| Beta | BH-20 | Data, activation, packages, and the Plug baseline are present; remaining work is primarily product-wide evidence and refinement. |
| Release candidate | BH-22 | Feature claims, compatibility, accessibility, security, and performance have passed the declared production gates. |
| Browser 1.0 | BH-23 | Public contracts, support policies, examples, and ecosystem governance are stable. |

## Cross-cutting obligations

The following are not late cleanup phases. Each milestone must extend them in
proportion to the surface it adds:

- **Contract evidence.** Every public behavior has deterministic component,
  renderer, browser, and server-boundary evidence appropriate to its claim.
- **Accessibility.** Semantic roles, names, relationships, state, focus,
  keyboard interaction, announcements, direction, and nonvisual alternatives
  are part of component completion.
- **Security.** Browser code and state remain untrusted; capabilities are
  explicit; server operations revalidate and reauthorize; build outputs are
  auditable.
- **Performance.** Runtime, shared foundation, feature package, and component
  costs are measured on representative mobile hardware and constrained
  networks rather than inferred from desktop development.
- **Failure and cleanup.** Every process, command, effect, subscription,
  observer, timer, surface, asset, and resource has ownership, cancellation,
  stale-generation, and disposal behavior.
- **Host neutrality.** Browser conveniences stay in adapters, and any escape
  hatch that reduces portability is named in metadata and documentation.
- **Provenance.** BlazeX owns its API and visual profiles while preserving
  licenses and attribution for any adapted code, styles, icons, or examples.

## Explicitly outside the browser 1.0 program

The roadmap preserves architectural room for these paths but does not make
them browser-release blockers beyond the BH-02 portability proof:

- a production desktop webview shell;
- a production native-control renderer;
- a standalone Wasmtime or WASI application host;
- general Elixir AOT compilation to native WebAssembly;
- WebAssembly Component Model packaging as the primary UI abstraction;
- full ERTS or OTP parity inside the browser;
- arbitrary server module, Ecto, filesystem, port, or NIF execution in client
  bundles; and
- compatibility with .NET, Razor, Blazor binaries, MudBlazor APIs, or NuGet
  packages.

## Connections

- [Elixir WebAssembly component framework for Phoenix and Plug](elixir-webassembly-component-framework-for-phoenix-and-plug.md) — runtime, build, server integration, security, performance, and original staged plan consolidated here.
- [Host-neutral BlazeX architecture and native control backends](host-neutral-blazex-architecture-and-native-control-backends.md) — semantic kernel and cross-renderer constraints that remain binding during browser-first work.
- [MudBlazor-inspired component system for BlazeX](mudblazor-inspired-component-system-for-blazex.md) — target catalog, component dependency order, and F0–F4 product tiers expanded into browser milestones here.
- [Blazor framework semantics beneath BlazeX](blazor-framework-semantics-beneath-blazex.md) — lifecycle, identity, forms, navigation, effects, errors, and packaging semantics incorporated into the roadmap.
- [Can Elixir WebAssembly components integrate with Phoenix and Plug?](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md) — feasibility evidence that BH-01 and the later production gates must resolve.
- [Which MudBlazor component families should BlazeX build?](../40-inquiries/which-mudblazor-component-families-should-blazex-build.md) — catalog and component evidence advanced by BH-00 and BH-08 through BH-17.
- [Can one BlazeX component model target DOM and native controls?](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md) — portability question constrained to the early BH-02 gate for this browser program.

## Sources

- [Popcorn documentation and source](../30-sources/software-mansion-2026-popcorn-documentation-and-source.md)
- [LocalLiveView first release and source](../30-sources/software-mansion-2026-local-live-view-first-release.md)
- [Phoenix LiveView 1.2 documentation and source](../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md)
- [Phoenix LiveView UI foundation surfaces](../30-sources/phoenix-framework-2026-liveview-ui-foundation-surfaces.md)
- [MudBlazor v9.9.0 source architecture](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
- [MudBlazor component documentation](../30-sources/mudblazor-project-2026-component-documentation.md)

