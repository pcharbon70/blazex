---
title: "BlazeX browser rendering and profile modes"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - bh-00
  - browser
  - phoenix
  - plug
  - rendering
aliases:
  - "BlazeX browser mode contract"
  - "BH-00 rendering and profile matrix"
---

# BlazeX browser rendering and profile modes

## Status and scope

This note gives each BlazeX browser output, activation, profile, and
server-integration claim an observable meaning. It is a product contract for
later milestones, not evidence that any mode currently runs. The
[machine-readable browser product
envelope](../assets/browser-product-envelope-v0.1.json) is the matrix source of
truth; this note explains its semantics.

All rows inherit the [canonical vocabulary](blazex-canonical-vocabulary.md).
In particular, Phoenix and Plug are server adapters, the browser is the
execution host, standalone DOM is a renderer backend, and LiveView lowering is
an optional renderer adapter.

## Cross-mode invariants

1. Stable component and semantic-node identity belongs to BlazeX contracts;
   DOM IDs, LiveView component IDs, process IDs, and toolkit handles do not.
2. Only explicitly public, schema-versioned activation state crosses from a
   server/static phase into browser-local execution. Server domain state and
   secrets never cross implicitly.
3. Effects run only in a mode with an active capability provider. Prerender
   suppresses external effects and records only declared data requirements.
4. A local event is owned by the active local component generation. A remote
   command crosses a separate untrusted server-adapter boundary.
5. Focus and user-entered values are preserved across compatible activation;
   no renderer may claim activation after destructive subtree replacement.
6. Accessibility roles, names, states, relationships, order, announcements,
   and focus intent are semantic obligations in every output mode.
7. Build, schema, identity, or public-state mismatch fails closed to a declared
   replacement/static fallback. It never attaches handlers to unknown output.
8. Replacement tears down the previous generation before the new owner can
   claim resources. Disposal is idempotent, bounded, and observable.

## Rendering and activation mode contract

### `MODE-STATIC-FALLBACK` — static fallback

- **Logic and surface:** no interactive component runtime is required. A
  server, build step, or host application owns bounded noninteractive output.
- **Identity/state:** stable content identity and public labels/values may be
  present; no private local state or resumable process is implied.
- **Effects/events:** no component effects or local event ownership. Links and
  ordinary form submissions may be host-provided fallbacks when documented.
- **Focus/accessibility:** output follows document order, remains readable and
  operable for its bounded purpose, and explains unavailable interaction.
- **Failure/disposal:** it is itself the terminal safe fallback. Any loader or
  retry control must be optional and must not hide the bounded content.
- **Roadmap disposition:** browser 1.0 commitment, with component-family detail
  and executable evidence deferred to BH-18 and catalog/acceptance phases.

### `MODE-SERVER-RENDERED` — server-rendered output

- **Logic and surface:** component-compatible rendering logic executes on the
  server and the server renderer materializes output delivered to the browser.
  This row alone does not imply an interactive LiveView process or activation.
- **Identity/state:** server identity and public output state are recorded, but
  browser-local identity is not established unless a separate prerender
  envelope is present.
- **Effects/events:** server rendering may load authorized data through server
  application services; it does not run browser effects. Interactivity requires
  a separately named server-interactive or activation contract.
- **Focus/accessibility:** delivered output must be semantically complete for
  the claimed noninteractive purpose.
- **Failure/disposal:** server errors use the application's safe HTTP/error
  boundary. No browser-local resources exist to dispose.
- **Roadmap disposition:** conditional by family/profile. It is vocabulary now,
  not a universal browser 1.0 promise.

### `MODE-PRERENDERED` — prerendered output

- **Logic and surface:** a deterministic server/static render creates output
  intentionally paired with a later browser-local root. The server owns the
  surface until successful activation.
- **Identity/state:** root/build/schema IDs and minimal public activation state
  are embedded in an integrity-protected, size-bounded envelope. Secret,
  authoritative, process, or host-resource state is excluded.
- **Effects/events:** external effects and local events are suppressed before
  activation; data needed for initial public output is resolved explicitly.
- **Focus/accessibility:** the output is useful before activation and must not
  present interactive affordances whose behavior does not yet exist without an
  honest unavailable/loading state.
- **Failure/disposal:** mismatch or unavailable runtime leaves the prerendered
  output as bounded static content or invokes a declared replacement policy.
- **Roadmap disposition:** browser 1.0 commitment only for the later supported
  activation subset; BH-18 must prove it.

### `MODE-BROWSER-LOCAL` — browser-local interactive output

- **Logic and surface:** eligible component logic runs in AtomVM-in-Wasm in the
  browser execution host and drives the standalone DOM renderer. Local events
  require no server round trip.
- **Identity/state:** the active browser generation owns local state. Initial
  public props are untrusted data; server authority remains remote.
- **Effects/events:** local events stay local. Named browser capabilities grant
  effects. Typed remote commands cross the selected server adapter.
- **Focus/accessibility:** the DOM renderer maps semantic accessibility and
  focus intent, normalizes input, and preserves active interaction across
  updates.
- **Failure/disposal:** boot/render/capability failure selects a declared
  fallback. Root termination cancels effects and disposes host/renderer
  resources before replacement.
- **Roadmap disposition:** core browser 1.0 commitment, conditional on BH-01
  feasibility and later platform/release gates.

### `MODE-ACTIVATED` — activated browser-local output

- **Logic and surface:** browser-local logic becomes authoritative for local
  interaction after attaching to or reconciling compatible prerendered output.
  The DOM renderer owns the activated surface.
- **Identity/state:** root/build/schema identity and public activation state
  must match. Private server state is reloaded only through authorized commands.
- **Effects/events:** effects start once after successful ownership transfer;
  prerender does not duplicate them. Queued input is either safely replayed by
  policy or rejected, never silently applied to a different generation.
- **Focus/accessibility:** activation preserves focused element, selection,
  user-entered values, semantic relationships, live-region behavior, and
  reading order.
- **Failure/disposal:** mismatch never masquerades as activation. The system
  keeps bounded output, safely replaces through a named policy, or offers retry;
  superseded generations are disposed exactly once.
- **Roadmap disposition:** browser 1.0 commitment for the supported subset,
  conditional on BH-18 identity, state, effect, focus, and mismatch evidence.

### `MODE-HEADLESS` — headless output

- **Logic and surface:** portable component logic executes under a test/build
  process and produces normalized semantic tree, event, effect, resource,
  accessibility, and disposal traces; no visual surface is materialized.
- **Identity/state:** the same portable IDs and state transitions used by
  visual modes are observed deterministically.
- **Effects/events:** deterministic test providers inject events/results and
  record effect ownership, cancellation, timeout, fallback, and disposal.
- **Focus/accessibility:** semantic focus and accessibility invariants are
  inspected without claiming platform API mapping.
- **Failure/disposal:** mismatches and leaks are deterministic test failures.
- **Roadmap disposition:** browser-program conformance commitment rather than an
  end-user display mode; BH-02 must prove it.

## Mode commitment summary

| Mode | BH-00 status | Browser 1.0 disposition | Evidence gate |
| --- | --- | --- | --- |
| Static fallback | defined vocabulary | committed | BH-18 plus family catalog/acceptance rows |
| Server-rendered output | defined vocabulary | conditional by family/profile | Later explicit server-rendering claim |
| Prerendered output | defined vocabulary | committed for activation subset | BH-18 |
| Browser-local interactive | defined vocabulary | committed core mode | BH-01 and subsequent browser platform/release gates |
| Activated | defined vocabulary | committed for activation subset | BH-18 |
| Headless | defined vocabulary | conformance-only commitment | BH-02 |

No row is supported until its named gate and the Phase 2 support policy pass.

## Independent profile compositions

### `PROFILE-BROWSER-PHOENIX`

- Runtime: AtomVM-in-Wasm through the Popcorn adapter.
- Execution host/capabilities: browser and named Web API providers.
- Renderer: standalone DOM; optional LiveView DOM lowering only in a named
  compatible mode.
- Server adapter: Phoenix for sessions, commands, pushes, navigation,
  observability, and later optional prerender coordination.
- Shell: web deployment assembled by the profile.

Phoenix is not the execution host and does not own local events or portable
state. The profile remains planned/unproven until later milestones.

### `PROFILE-BROWSER-PLUG`

- Runtime, execution host, capabilities, renderer, and browser bridge: the same
  independent classes as the Phoenix profile, with standalone DOM only.
- Server adapter: Plug static/bootstrap/HTTP-command baseline plus explicit
  host-provided session, CSRF, authorization, navigation, and telemetry hooks.
- Shell: a smaller web deployment with no Phoenix or LiveView dependency.

The baseline has no Channels, PubSub, LiveView, LocalLiveView, LiveView DOM
adapter, server push/realtime, upload protocol, prerender, or activation claim.
A future separately named adapter/profile may add a replacement only after its
own dependency and support review.

### `PROFILE-HEADLESS`

- Runtime/host: a tested ERTS, AtomVM, or other declared test process.
- Renderer/capabilities: normalized headless renderer and deterministic test
  providers.
- Server adapter/shell: none or explicit test adapter in CLI/CI.

Headless proves portable semantics. It does not imply a browser, Phoenix, Plug,
or native-control support claim.

## Adapter boundaries

| ID | Boundary | Owns | Must not own |
| --- | --- | --- | --- |
| `ADAPTER-PHOENIX-SERVER` | Phoenix server adapter | assets/bootstrap integration, sessions, trusted command handlers, push/realtime coordination, telemetry, optional prerender coordination | browser execution, local event loop, portable component state, DOM renderer core |
| `ADAPTER-PLUG-SERVER` | Plug server adapter | static/bootstrap/HTTP-command baseline and host-provided security/telemetry hooks | Phoenix, LiveView, LocalLiveView, push/realtime/upload/prerender promises |
| `ADAPTER-LIVEVIEW-DOM` | optional LiveView DOM renderer adapter | versioned render-data/patch/transport lowering when selected | portable renderer contract, standalone DOM core, Plug profile dependency |

## Profile capability matrix

Statuses mean: **required** is part of the planned profile contract;
**conditional** needs the named later evidence before the profile may claim it;
**host-provided** is an explicit application hook; **test-double** is simulated
only for conformance; **absent** is not in the baseline; and **not-applicable**
has no meaningful profile behavior.

| Capability | Browser/Phoenix | Browser/Plug | Headless |
| --- | --- | --- | --- |
| Static delivery | required | required | not-applicable |
| Bootstrap envelope | required | required | test-double |
| Sessions | required | host-provided | not-applicable |
| CSRF/origin protection | required | host-provided | not-applicable |
| Typed remote commands | required | required (HTTP baseline) | test-double |
| Server pushes | required | absent | test-double |
| Realtime transport | required | absent | test-double |
| Upload protocol | conditional | absent | test-double |
| Navigation integration | required | host-provided | test-double |
| Prerender | conditional | absent | test-double |
| Activation | conditional | absent | test-double |
| Telemetry | required | host-provided | test-double |

“Required” still means planned and unproven in Phase 2. It does not override the
support-policy evidence state.

## Plug transitive-dependency gate

The browser/Plug dependency closure must contain none of:

- `blazex_phoenix`;
- `blazex_renderer_dom_liveview`;
- Phoenix or Phoenix LiveView application/package dependencies; or
- LocalLiveView application/package dependencies.

BH-20 must produce an automated lock/dependency-tree audit. A package rename,
optional flag, or runtime-disabled application does not satisfy the gate if the
dependency remains in the resolved build or release.

Plug-replaceable facilities use public BlazeX contracts: application session
projection, origin/CSRF hooks, typed HTTP command handlers, standard navigation,
and telemetry callbacks. Phoenix-specific pushes, Channels/PubSub, LiveView
lowering, uploads, prerender, and activation remain absent unless a new named
adapter/profile is accepted and independently evidenced.

## Explicit non-claims

- A server-rendered page is not automatically prerendered or activatable.
- DOM similarity is not activation; identity/state/effect/focus checks are
  mandatory.
- The Phoenix profile does not make Phoenix the browser execution host.
- The optional LiveView DOM adapter does not define the renderer contract.
- The Plug profile does not inherit Phoenix claims through transitive packages.
- Headless success is not browser, WebView, or native-control support.
- These mode names imply no Blazor render-mode, .NET, or MudBlazor API
  compatibility.

## Change control

Mode changes require component-kernel, renderer, accessibility, effects,
security, and product owners. Profile/capability changes additionally require
the relevant server-adapter, release, and dependency owners. Update this note,
the machine-readable envelope, profile/package boundaries, fallbacks, roadmap,
and acceptance records atomically.

## Connections

- [Browser and toolchain support policy](blazex-browser-and-toolchain-support-policy.md)
- [Canonical vocabulary](blazex-canonical-vocabulary.md)
- [Repository ownership and dependency map](../10-maps/blazex-repository-ownership-and-dependency-map.md)
- [ADR-0004 — Renderer backend separation](architecture-decisions/adr-0004-renderer-backend-separation.md)
- [ADR-0005 — Server adapter and trust boundary](architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md)
- [ADR-0006 — Profile composition](architecture-decisions/adr-0006-profile-composition.md)
- [BH-00 Phase 2 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-02-browser-product-and-support-envelope.md)

## Sources

- [Phoenix documentation notes](../30-sources/phoenix-framework-2026-phoenix-1-8-documentation.md)
- [LiveView documentation and source notes](../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md)
- [Plug documentation notes](../30-sources/elixir-plug-team-2026-plug-1-20-documentation.md)
- [LocalLiveView release and source notes](../30-sources/software-mansion-2026-local-live-view-first-release.md)
