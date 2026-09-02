---
title: "BlazeX browser and toolchain support policy"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - bh-00
  - browser
  - compatibility
  - product-contract
  - toolchain
aliases:
  - "BlazeX browser support policy"
  - "BH-00 browser candidate envelope"
---

# BlazeX browser and toolchain support policy

## Status and scope

This is the BH-00 policy for deciding which browser configurations and
toolchain combinations may eventually be called supported. It defines a
candidate envelope for BH-01 to prove or reject. It does not select exact
versions, report a successful build, or grant support to any configuration.

The machine-readable source for the tables and status vocabulary is the
[browser product envelope](../assets/browser-product-envelope-v0.1.json).
Until BH-01 supplies the required records, every candidate browser
configuration remains **unsupported (unproven)** and every toolchain input
remains **candidate**.

## Governing rules

1. Support belongs to a complete, versioned profile and mode, not to a browser
   engine or dependency in isolation.
2. Channel-relative policies identify what BH-01 must resolve to exact versions
   at a dated qualification cut; they are not floating release dependencies.
3. A passing demonstration is not support. Support requires the complete
   evidence class, provenance, security, accessibility, and repeatability set.
4. Browser, operating-system, device, assistive-technology, runtime, and server
   inputs are recorded together because any one can change the result.
5. Evidence expires according to the review cadence. An old passing result does
   not remain current merely because the version range still parses.
6. Removal or demotion is an ordinary policy outcome when a configuration can
   no longer satisfy the evidence or security requirements.

## Browser support statuses

| ID | Status | Product meaning | Entry evidence | Release consequence |
| --- | --- | --- | --- | --- |
| `BS-UNSUPPORTED` | unsupported | Outside the current contract, explicitly blocked, or not yet proven. | None; a reason and safe/factual user message are still required when detected. | Failures do not block release unless they violate a promised fallback or security property. |
| `BS-BEST-EFFORT` | best-effort | Expected to work through standards overlap but not included in the release gate. | One recent smoke result, known limitations, and an owner for issue triage. | Regressions are triaged but do not automatically block release. |
| `BS-PREVIEW` | preview | Included in the versioned profile for evaluation with bounded guarantees. | Clean reproducible build, required functional/security/accessibility smoke scenarios, exact environment record, and evidence no older than 31 days at release. | A failure blocks a preview release claim or causes explicit demotion. |
| `BS-SUPPORTED` | supported | Covered by the compatibility policy and full current release evidence. | All required evidence classes, upgrade and fallback tests, security review, exact artifacts/provenance, and evidence no older than 31 days at release. | A matrix regression blocks release or requires a reviewed deprecation/demotion record. |

Promotion is monotonic only with evidence: unsupported → best-effort → preview →
supported. A configuration may skip best-effort when all preview evidence
exists. Demotion can move directly to unsupported for a security, integrity, or
data-loss risk.

## Candidate browser configurations

`N` means the stable major available on the dated BH-01 qualification cut. The
resolved product, engine, operating system, build, and date must be recorded;
the symbols below never appear in a release support matrix.

| ID | Candidate family/products | Stable-channel and minimum rule | Device/OS evidence | Current → earliest target |
| --- | --- | --- | --- | --- |
| `BR-CHROMIUM-DESKTOP` | Chromium through Chrome and Edge desktop | Stable `N` and `N-1`; no beta/dev/canary claim | Current vendor-supported Windows, macOS, and Linux reference images selected by BH-01 | unsupported (unproven) → preview |
| `BR-CHROMIUM-ANDROID` | Chrome for Android | Current stable `N`; prior major is best-effort candidate only | Current and previous vendor-supported Android major on representative touch devices | unsupported (unproven) → preview |
| `BR-FIREFOX-DESKTOP` | Firefox desktop | Stable `N` and `N-1`; ESR is a separately qualified best-effort candidate until tested | Current vendor-supported Windows, macOS, and Linux reference images | unsupported (unproven) → preview |
| `BR-WEBKIT-DESKTOP` | Safari on macOS | Safari stable on the current and previous vendor-supported macOS major; Technology Preview excluded | Representative Intel/Apple-silicon choice recorded by BH-01 where relevant | unsupported (unproven) → preview |
| `BR-WEBKIT-MOBILE` | Safari on iOS/iPadOS | Current and previous vendor-supported OS major; all third-party iOS browsers remain this WebKit configuration unless separately evidenced | Representative phone and tablet, touch, rotation, viewport, and virtual-keyboard cases | unsupported (unproven) → preview |

This is intentionally a family policy rather than a numerical version claim.
BH-01 may narrow or block a row if Popcorn, AtomVM, required Web APIs, memory,
worker, isolation, accessibility, or packaging evidence cannot satisfy it.

## Review cadence and freshness

- **Per change:** run the smallest available smoke set for affected browser,
  runtime, renderer, bridge, or server-adapter code once BH-01 creates it.
- **Monthly:** resolve stable-channel drift, rerun boot/smoke/fallback checks,
  and record newly released browser/OS versions and removals.
- **Per BlazeX release:** resolve every symbolic window to exact versions,
  execute the status-required matrix, and publish dated results and artifacts.
- **Event-driven:** requalify after a browser security change, WebAssembly/Web
  API behavior change, runtime/toolchain update, private-API break, OS support
  removal, or high-impact compatibility report.
- **Stale evidence:** preview and supported evidence older than 31 days at the
  release cut cannot satisfy release qualification without rerun or reviewed
  demotion.

## Required evidence classes

Every evidence result records browser product/build, engine build when exposed,
OS/build, device or VM, CPU architecture, memory class, input, display/zoom,
network profile, assistive technology, profile/mode, BlazeX build identity,
toolchain lock identity, timestamp, outcome, diagnostics, and artifact links.

| ID | Evidence class | Minimum coverage before support |
| --- | --- | --- |
| `EC-DESKTOP` | Desktop operating systems and architectures | Every claimed desktop browser row on each claimed OS family; hardware/VM and architecture recorded. |
| `EC-MOBILE` | Phone and tablet | Claimed Android/iOS/iPadOS rows with rotation, virtual keyboard, viewport, background/resume, and touch. |
| `EC-MEMORY` | Normal and constrained memory | Reference and constrained-memory runs with startup, steady state, pressure/failure, cleanup, and no unbounded retry. |
| `EC-CPU` | Reference and constrained CPU | Native-speed and documented throttled/low-power runs with startup and local-event behavior. |
| `EC-NETWORK` | Delivery and connection quality | Warm/cold cache, high latency, low bandwidth, loss, offline start where applicable, interruption, reconnection, and server loss. |
| `EC-INPUT` | Input modalities | Keyboard-only, pointer, touch where available, focus traversal, modality switches, and input-method composition. |
| `EC-ZOOM` | Magnification and reflow | Browser zoom through 200%, text zoom where available, 400% reflow for applicable content, and viewport resizing. |
| `EC-CONTRAST` | Color and motion preferences | Light/dark, high or forced contrast where available, reduced motion, non-color state cues, and visible focus. |
| `EC-DIRECTION` | Language direction and content stress | LTR and RTL layout/interaction plus long, short, mixed-direction, and localized content. |
| `EC-ASSISTIVE-TECH` | Platform accessibility integration | Representative NVDA, VoiceOver, and TalkBack pairings selected per claimed platform; role/state/name, focus, announcement, and interaction traces. |

Phase 5 will attach quantitative budgets. This phase only makes the classes and
promotion obligation explicit.

## Toolchain status vocabulary

Toolchain status applies to a complete combination record, not merely to an
individual package version.

| ID | Status | Meaning |
| --- | --- | --- |
| `TS-CANDIDATE` | candidate | Inside the investigation envelope; unresolved and not a support statement. |
| `TS-PINNED` | pinned | Exact source/package/browser/OS identities and checksums are locked, but execution has not necessarily passed. |
| `TS-TESTED` | tested | The pinned combination passed named scenarios in a recorded environment; it is still not automatically supported. |
| `TS-SUPPORTED` | supported | The tested combination satisfies the current profile support matrix, provenance, security, rebuild, and release evidence. |
| `TS-DEPRECATED` | deprecated | Still accepted for a bounded transition with an owner, removal condition/date policy, and migration path. |
| `TS-BLOCKED` | blocked | Known incompatible, insecure, irreproducible, or dependent on an unacceptable private contract. |

Private API use can be candidate or pinned for feasibility, but cannot become
supported unless it has a version guard, compatibility tests, failure
diagnostics, an accountable owner, and an accepted maintenance/replacement
policy. Unbounded private coupling is blocked.

## Candidate toolchain inventory

All rows start as `candidate`; exact versions and compatibility edges are BH-01
outputs.

| ID | Layer | Why it affects the profile | BH-01 resolution |
| --- | --- | --- | --- |
| `TC-PHOENIX` | Phoenix | Endpoint, assets, sessions, routing, security hooks, telemetry, and optional prerender coordination. | Exact package/source revision and configuration. |
| `TC-LIVEVIEW` | Phoenix LiveView | Optional DOM lowering/transport contracts and compatibility risk. | Exact public/private surfaces, revision, and adapter tests. |
| `TC-LOCAL-LIVEVIEW` | LocalLiveView | Browser-local process/render proof and likely private-version coupling. | Exact revision, patch set, dependency graph, and maintenance disposition. |
| `TC-POPCORN` | Popcorn | Browser build, AtomVM packaging, loader, iframe/worker behavior, and patched libraries. | Exact source revision, patches, build command, and output hashes. |
| `TC-ATOMVM` | AtomVM | BEAM subset, runtime behavior, Wasm build, memory, and host imports. | Exact revision/configuration, supported BEAM surface, and runtime artifact. |
| `TC-ELIXIR` | Elixir | Compiler output, standard library reachability, macros, and generated BEAM compatibility. | Exact version/source and supported language/library subset. |
| `TC-OTP` | Erlang/OTP | BEAM format, compiler/runtime libraries, BIF/NIF assumptions, and tooling. | Exact release/source plus allowed modules/BIFs and excluded native dependencies. |
| `TC-MIX` | Mix | Dependency resolution, compile environments, archives/tasks, and repeatable build orchestration. | Exact version, environment, commands, and dependency graph. |
| `TC-JS-TOOLING` | JavaScript runtime, package manager, and bundler | Loader/bridge build, asset graph, minification, source maps, and lock resolution. | Exact tools/versions, lockfile, commands, and emitted asset hashes. |
| `TC-BROWSER` | Browser product and engine | Wasm/Web APIs, workers, isolation, storage, networking, accessibility, and rendering behavior. | Exact browser/engine build resolved from the candidate row. |
| `TC-OPERATING-SYSTEM` | Build and test operating systems | Toolchain availability, filesystem/process behavior, browser packaging, fonts, and accessibility APIs. | Exact image/build, architecture, package inventory, and clean-machine recipe. |

## BH-01 records required before support

| ID | Required record | Minimum contents |
| --- | --- | --- |
| `REC-LOCKS` | Lock and identity set | Mix and JavaScript locks; git revisions/submodules/patches; browser and OS builds; checksums. |
| `REC-ARTIFACTS` | Artifact manifest | Every runtime, AVM/BEAM, Wasm, JavaScript, source-map, HTML, CSS, font, and other emitted asset with size, hash, and producer. |
| `REC-PROVENANCE` | Provenance and dependency record | Source origins, licenses, SBOM/dependency graph, build environment, patches, and private API inventory. |
| `REC-REBUILD` | Clean rebuild record | Automated clean-machine commands, environment, timestamps, outputs, hash comparison, and explained nondeterminism. |
| `REC-SECURITY` | Security update record | Advisory inputs, response/triage owner, rebuild triggers, patch/demotion policy, and last review. |
| `REC-SUPPORT-MATRIX` | Tested support matrix | Exact toolchain combination joined to browser/profile/mode/evidence classes, outcomes, known limits, and dated logs. |

A candidate becomes pinned only when `REC-LOCKS` exists. It becomes tested only
when the named scenario results and `REC-ARTIFACTS` exist. It becomes supported
only when all six records are current and the browser/profile evidence gate
passes.

## Explicit non-claims

This policy does not claim:

- that any browser or toolchain combination currently boots BlazeX;
- full OTP, Elixir standard-library, NIF, port, or arbitrary dependency support;
- support for beta/nightly browser channels or every Chromium/WebKit product;
- native-host, WebView, or native-control support;
- native Wasm AOT or WebAssembly Component Model delivery; or
- .NET, Razor, Blazor, MudBlazor API, package, binary, or renderer compatibility.

## Change control

Browser support changes require product, browser-host, accessibility, security,
build, and release owners. Toolchain changes additionally require runtime and
server-integration owners. The machine-readable envelope, this policy, profile
support matrix, release evidence, fallbacks, roadmap status, and relevant ADRs
change together. A support row is never edited retroactively without preserving
the released matrix and reason for promotion, demotion, or removal.

## Connections

- [Canonical vocabulary](blazex-canonical-vocabulary.md)
- [Browser host implementation milestones](browser-host-implementation-milestones.md)
- [Repository ownership and dependency map](../10-maps/blazex-repository-ownership-and-dependency-map.md)
- [ADR-0005 — Server adapter and trust boundary](architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md)
- [ADR-0006 — Profile composition](architecture-decisions/adr-0006-profile-composition.md)
- [BH-00 Phase 2 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-02-browser-product-and-support-envelope.md)

## Sources

- [Popcorn documentation and source notes](../30-sources/software-mansion-2026-popcorn-documentation-and-source.md)
- [AtomVM WebAssembly runtime notes](../30-sources/atomvm-project-2026-webassembly-runtime.md)
- [LocalLiveView release and source notes](../30-sources/software-mansion-2026-local-live-view-first-release.md)
- [LiveView documentation and source notes](../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md)
- [Phoenix documentation notes](../30-sources/phoenix-framework-2026-phoenix-1-8-documentation.md)
