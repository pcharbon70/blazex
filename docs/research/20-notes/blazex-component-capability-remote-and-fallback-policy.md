---
title: "BlazeX component capability, remote, and fallback policy"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - bh-00
  - capabilities
  - component-catalog
  - fallback
  - security
aliases:
  - "BH-00 component capability policy"
  - "BlazeX component fallback policy"
---

# BlazeX component capability, remote, and fallback policy

## Decision and scope

Portable components request named semantic capabilities from `blazex_effects`
and renderer contracts. Host and renderer adapters grant, deny, or substitute
them. Components never import a browser API, Phoenix socket, DOM event, native
widget, filesystem object, or unrestricted script facility.

The machine authority is the [capability registry
v0.1.0](../assets/component-catalog/blazex-capability-registry-v0.1.0.json)
plus each family assignment in [component classification
v0.1.0](../assets/component-catalog/blazex-component-classification-v0.1.0.json).

## Capability groups

| ID | Contract | Typical use | Lifecycle |
| --- | --- | --- | --- |
| `BX-CAP-ACCESSIBILITY` | Semantic accessibility mapping and announcements | Every family; especially charts, feedback, forms, and surfaces | Renderer contract |
| `BX-CAP-CLIPBOARD` | Bounded user-mediated copy/paste | Text and data affordances | Request |
| `BX-CAP-FILES` | User-selected opaque file resources | File upload/selection | Leased resource |
| `BX-CAP-FOCUS` | Semantic focus move/restore/contain | Inputs, navigation, surfaces | Renderer contract |
| `BX-CAP-KEYBOARD` | Normalized scoped key intents | Interactive controls, shortcuts, grids | Subscription |
| `BX-CAP-MEASUREMENT` | Geometry, viewport class, placement constraints | Responsive context, surfaces, virtualizers | Subscription |
| `BX-CAP-NETWORK` | Authenticated remote provider/command attachment | Remote forms/data/uploads | Request |
| `BX-CAP-NOTIFICATIONS` | Optional host notification beyond in-app UI | Snackbar enhancement | Request |
| `BX-CAP-POINTER` | Normalized activation, drag, resize, gesture, capture | Buttons, drag/drop, split, swipe | Scoped resource |
| `BX-CAP-STORAGE` | Bounded nonsecret preferences/drafts | Theme/preferences and optional drafts | Leased resource |
| `BX-CAP-SURFACE` | Place, stack, dismiss, and dispose transient surfaces | Popover, menu, dialog, snackbar | Leased resource |
| `BX-CAP-SYSTEM-THEME` | Normalized color/contrast/motion preferences | Theme context | Subscription |
| `BX-CAP-TIME` | Owner-scoped timers and animation intent | Carousel, progress, transient feedback | Leased resource |
| `BX-CAP-WINDOW` | Navigation, visibility, viewport, scroll, close lifecycle | exit prompt, scroll navigation, responsive shell | Subscription |

Required means the full classified behavior cannot be supported without the
capability and therefore needs a declared missing-capability fallback. Optional
means an enhancement may be omitted while the family remains coherent.
Capabilities do not imply that the browser host, DOM renderer, native backend,
Phoenix, or Plug currently implements them.

## Effect and resource ownership

- Renderer-semantic interactions use normalized events and semantic identities;
  renderer ownership does not expose backend objects.
- Components own requests and state transitions; shared services own global or
  cross-root coordination such as surfaces, viewport observation, and queues.
- Host adapters own concrete grants and opaque resource handles.
- Subscriptions and leased/scoped resources require cancellation where work may
  outlive a turn, bounded timeout/host policy, generation checks, and
  idempotent cleanup.
- A component disposal, root removal, denied grant, provider replacement, or
  stale generation invalidates every owned effect and resource.

## Remote-authority vocabulary

| Value | Meaning |
| --- | --- |
| `local-only` | Full classified semantics use local state/capabilities; ordinary application actions may still navigate or submit. |
| `optional-remote` | Local/static operation is valid; a provider/command can add authoritative data or mutations. |
| `required-remote` | The classified product behavior cannot complete without a trusted remote service. |
| `phoenix-enhanced` | Phoenix offers richer integration, but the portable component and documented Plug path remain usable. |
| `unavailable-in-plug` | A named feature is intentionally Phoenix-only; it is never inherited silently by the family. |

Client state, visibility, disabled state, validation, cached data, and successful
Wasm execution are never authorization. A remote command authenticates,
enforces origin/CSRF policy, decodes under limits, allowlists and validates,
reloads trusted state, authorizes, applies replay/idempotency policy, executes,
audits, and returns a public bounded result.

No family in this initial catalog is intrinsically unavailable in Plug. Phoenix
enhancements are adapters, not product ownership. File upload retains local
selection semantics and can attach either an approved Phoenix or Plug remote
adapter.

## Fallback vocabulary and conditions

Every family chooses a primary fallback from static content, alternative
interaction, server round trip, in-app substitute, nonvisual representation,
explicit unavailable state, omission, or not-required. It then classifies all
nine conditions:

1. no JavaScript;
2. no network;
3. denied permission;
4. missing capability;
5. unsupported renderer;
6. failed resource;
7. reduced motion;
8. forced colors; and
9. assistive-technology access.

A fallback preserves security and accessibility, reports truthful support,
cleans resources, and cannot silently downgrade an authoritative operation.
Reduced motion disables automatic movement rather than removing information or
controls. Forced colors selects semantic high-contrast tokens and platform
affordances. Charts and other visual-only encodings require a nonvisual data
representation. A missing required capability cannot use `not-required`.

## Forbidden portable metadata

Catalog requirement tokens and renderer semantics may name BlazeX semantic
nodes, intents, focus, resources, capabilities, and lifecycle obligations. They
must not contain:

- DOM event/tag/node names or CSS selectors/classes;
- JavaScript objects, promises, handles, snippets, or unrestricted script;
- Phoenix/LiveView sockets, patch structures, hooks, or process references;
- native toolkit objects, callbacks, window handles, or widget classes;
- filesystem paths or platform file descriptors; or
- browser-global, document, storage, or network client objects.

Concrete adapters may implement a portable token, but that adapter detail is
never copied into the component classification.

## Evidence boundary

Capability, remote, and fallback assignments are accepted product contracts,
not implementation evidence. All family implementation states remain
`unknown`; provider support must be proved per runtime, host, renderer, remote
adapter, and deployment profile at later milestone gates.

## Connections

- [Portability, native, and visual-profile policy](blazex-component-portability-native-and-visual-profile-policy.md)
- [Disposition, tier, and package policy](blazex-component-disposition-tier-and-package-policy.md)
- [Browser trust, deployment, and fallback policy](blazex-browser-trust-deployment-and-fallback-policy.md)
- [Host-neutral architecture](host-neutral-blazex-architecture-and-native-control-backends.md)
- [BH-00 Phase 4 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-04-disposition-capability-fallback-and-portability-classification.md)

## Sources

- [Phoenix LiveView UI foundation surfaces](../30-sources/phoenix-framework-2026-liveview-ui-foundation-surfaces.md)
- [MudBlazor v9.9.0 source architecture](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
