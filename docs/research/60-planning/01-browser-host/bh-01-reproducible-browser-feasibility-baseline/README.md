---
title: "BH-01 Reproducible Browser Feasibility Baseline"
kind: map
created: "2026-09-03"
tags:
  - archive-navigation
  - bh-01
  - browser
  - directory-index
  - implementation-planning
aliases:
  - "BH-01 implementation plan"
  - "BlazeX browser feasibility plan"
---

# BH-01 Reproducible Browser Feasibility Baseline

## Purpose

This plan decomposes BH-01 into ten ordered implementation phases that test
whether the selected Phoenix, LiveView, LocalLiveView, Popcorn, AtomVM,
Elixir, Erlang, JavaScript, and browser stack is reproducible and suitable as
the first BlazeX execution profile. It produces a stop/go feasibility baseline
before BlazeX stabilizes framework abstractions or expands product surface.

Every phase uses the established phase, section, task, and subtask hierarchy,
but the hierarchy is need-driven rather than numerically uniform. Phases have
different numbers of sections, tasks, and subtasks according to their actual
implementation, risk, and evidence boundaries. Every phase, section, and task
starts with a description, and the final section of every phase contains its
integration tests and completion-evidence gate.

## Authorization status

The repository owner approved the plan snapshot at revision `d70a965` and has
subsequently authorized Phases 1-10 one phase at a time. Each phase was delivered
section by section under the retained authorization record for that phase.
Phases 1-6 established repository governance, reproducible inputs, runtime and
browser boot, local DOM behavior, and the Phoenix authority/adapter boundary.
Phase 7 is complete with a narrow resilience, adversarial-security, diagnostics,
and resource-lifecycle `go` result in the one pinned browser environment. Phase
8 is complete with a historically blocked matrix result because four
browser/device rows and required manual accessibility pairings were unavailable.
The [development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
now carries those unavailable external-environment obligations as deferred
rather than allowing them to stop framework development. Phase 9 is complete
with a conditional active-Linux proceed decision: payload and Firefox timer
failures have bounded follow-up experiments, while representative reruns retain
timing drift. Phase 10 is complete with a proceed-with-bounded-conditions
decision: two independent clean execution contexts reproduced the baseline,
every ledger closed truthfully, and the final integration gate passed. BH-01 is
complete. BH-02 is eligible but not authorized; browser support and production
hardening remain outside the current authorization.

BH-00 remains the accepted product contract. BH-01 may produce feasibility
evidence and may reject the candidate stack; it cannot weaken BH-00
definitions, silently change package ownership, or turn a successful
experiment into browser support or a public component API.

## What belongs here

- Controlled activation of the minimal browser/Phoenix feasibility slice.
- Exact toolchain and dependency acquisition, pinning, provenance, and
  private-API records.
- AtomVM-in-Wasm/Popcorn build, browser loader, BEAM bundle, readiness,
  teardown, and artifact-accounting proofs.
- Disposable representative behavior for local state, nested identity, form
  events, timers/messages, DOM updates, fallback, cleanup, and one
  authenticated server command.
- Browser prerequisites, candidate desktop/mobile scenarios, repeatable
  measurements, clean-machine rebuilds, risk disposition, and the final
  feasibility decision.
- Explicit separation of active Linux Chrome/Firefox development evidence from
  deferred cross-platform, mobile, Safari, and manual accessibility
  qualification.
- Reproducible implementation evidence for every completed phase.

Reusable semantic-kernel APIs, a production component framework, MudBlazor-
inspired product families, the native-control portability spike, browser
support promotion, and release hardening belong to BH-02 or later milestones.

## Authoritative inputs

- [BH-00 product-contract baseline](../../../assets/bh-00-release/blazex-bh-00-release-index-v0-1-0.md) — fixes the source-bound architecture, product, quality, and evidence contract inherited by BH-01.
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md) — defines Linux Chrome/Firefox as the active development matrix and moves unavailable external-platform qualification to BH-22 without implying support.
- [BH-01 conditional entry manifest](../../../assets/bh-00-release/blazex-bh-01-entry-manifest-v0-1-0.md) — supplies the eight required inputs, ten proof obligations, five stop conditions, eight risks, and prohibited actions.
- [Browser host implementation milestones](../../../20-notes/browser-host-implementation-milestones.md) — defines the BH-01 goal, repository ownership, and completion signal.
- [Browser product envelope](../../../assets/browser-product-envelope-v0.1.json) — defines candidate browsers, toolchain inputs, rendering modes, profiles, prerequisites, fallback categories, and support nonclaims.
- [Quality contract](../../../assets/quality-acceptance/blazex-quality-contract-v0.1.0.json) — defines proposed measurement methods, environments, budgets, failures, blockers, and cross-cutting gates.
- [Acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json) — supplies stable observable conditions and evidence ownership for every BH-01 proof.
- [Repository ownership and dependency map](../../../10-maps/blazex-repository-ownership-and-dependency-map.md) — fixes package/profile responsibilities and forbidden dependency direction.
- [Can Elixir WebAssembly components integrate with Phoenix and Plug?](../../../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md) — records the central runtime and server-integration feasibility question.

## Planned activation boundary

Only the nine Phase 1 paths in this table are activated as dependency-free
experimental skeletons. No activation implies runtime or product evidence.

| Repository boundary | BH-01 responsibility | Must remain outside that boundary |
| --- | --- | --- |
| `profiles/browser_phoenix` | Compose the minimal feasibility application, deployment prerequisites, and observable scenarios. | Reusable component semantics, runtime internals, generic DOM lowering, or server authority rules. |
| `packages/blazex_runtime_popcorn` | Build and package the pinned AtomVM-in-Wasm/Popcorn runtime adapter. | Browser DOM behavior, Phoenix behavior, or portable component APIs. |
| `packages/blazex_host_browser` | Detect browser prerequisites and own browser lifecycle/capability adaptation. | Phoenix/LiveView coupling or renderer-neutral semantics. |
| `packages/blazex_renderer_dom` | Own the standalone feasibility DOM mutation and event-normalization boundary. | LiveView/LocalLiveView internals, Phoenix authentication, or public component contracts. |
| `packages/blazex_renderer_dom_liveview` | Isolate pinned LiveView/LocalLiveView renderer-data and private/version-sensitive integration. | Standalone DOM requirements or portable renderer contracts. |
| `packages/blazex_phoenix` | Own the authenticated command adapter and server-side trust boundary. | Client presentation authority or generic component state. |
| `js/blazex_runtime` | Load Wasm/BEAM artifacts, bridge explicit browser facilities, and expose readiness/failure. | Product component logic, server authorization, or unbounded script escape. |
| `integration/fixtures` | Hold disposable representative behavior and deterministic test scenarios. | Stable public APIs or production examples. |
| `integration/benchmarks` | Hold environment fingerprints, measurements, raw samples, and reports. | Unreviewed headline performance claims. |

`packages/blazex_core`, `packages/blazex_effects`, `packages/blazex_ui_tree`,
`packages/blazex_renderer`, `packages/blazex_renderer_headless`,
`profiles/headless`, and the native renderer experiment remain BH-02 work.
BH-01 may inspect their future boundaries but must not activate them to hide a
failure in the candidate browser stack.

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — Authorization, Evidence Governance, and Repository Activation](phase-01-authorization-evidence-and-repository-activation.md) | complete — gate passed | Record explicit approval, preserve BH-00 truth, establish evidence/stop governance, and activate only the named repository slice. | Merged BH-00 baseline and explicit approval of this plan |
| [2 — Toolchain and Dependency Qualification](phase-02-toolchain-and-dependency-qualification.md) | complete — gate passed | Resolve, pin, acquire, license, and verify every host, language, runtime, server, browser, and build input before runtime coding. | Phase 1 |
| [3 — AtomVM/Popcorn Runtime Build and BEAM Packaging](phase-03-runtime-build-and-beam-packaging.md) | complete — gate passed | Build the pinned Wasm runtime, package a minimal BEAM fixture, probe required runtime semantics, and establish the first artifact manifest. | Phase 2 |
| [4 — Browser Host Loader, Lifecycle, and Deployment](phase-04-browser-host-loader-lifecycle-and-deployment.md) | complete — gate passed | Implement manifest-driven loading, explicit browser bridges, prerequisite detection, lifecycle/failure behavior, and deployment contracts. | Phase 3 |
| [5 — Local Browser Behavior and DOM Vertical Slice](phase-05-local-browser-behavior-and-dom-vertical-slice.md) | complete — gate passed | Exercise disposable state, identity, forms, timers/messages, DOM updates, accessibility observations, and cleanup. | Phase 4 |
| [6 — Phoenix Trust Boundary and LiveView Adapter Isolation](phase-06-phoenix-trust-boundary-and-liveview-isolation.md) | complete — gate passed | Prove one authenticated command, isolate version-sensitive renderer integration, and preserve standalone DOM, Plug, and server authority boundaries. | Phase 5 |
| [7 — Resilience, Security, and Resource Lifecycle](phase-07-resilience-security-and-resource-lifecycle.md) | complete — gate passed | Stress failures, retries, adversarial inputs, diagnostics, cancellation, disposal, and bounded resource behavior across the vertical slice. | Phases 5–6 |
| [8 — Browser Compatibility and Accessible Fallback Matrix](phase-08-browser-compatibility-and-fallback-matrix.md) | complete — local evidence accepted; external qualification deferred | Retain the historical five-row result, use available Linux Chrome/Firefox evidence for development, and carry unavailable platform/device/manual qualification to BH-22. | Phase 7 |
| [9 — Measurement, Mobile Viability, and Artifact Economics](phase-09-measurement-mobile-viability-and-artifact-economics.md) | complete — conditional active-Linux proceed; external qualification deferred | Measure payload, build, startup, interaction, memory, and reliability in the active matrix; record unavailable mobile/cross-platform measurements as deferred. | Phase 8 local-development evidence and the deferred-qualification policy |
| [10 — Clean Rebuild, Review, and Feasibility Decision](phase-10-clean-rebuild-review-and-feasibility-decision.md) | complete — proceed with bounded conditions; BH-02 eligible but not authorized | Reproduce the complete baseline independently, reconcile every proof/risk/stop condition, and authorize, revise, or block BH-02 truthfully. | Phase 9 |

The current need-driven decomposition contains ten phases, 53 sections, 120
tasks, and 323 subtasks. These totals are consequences of the present
implementation and evidence analysis, not quotas or invariants. A reviewed plan
amendment may add, split, merge, or remove work when executable evidence shows
that the milestone requires a different shape.

## Input-manifest coverage

| BH-01 input | Primary phases | Closure expectation |
| --- | --- | --- |
| `BX-BH01-INPUT-TOOLCHAIN` | 2, 10 | Exact identities, acquisition sources, locks, environment fingerprints, and equivalent clean rebuilds. |
| `BX-BH01-INPUT-PROFILE-SLICE` | 1, 4, 6, 10 | Minimal browser/Phoenix composition with standalone DOM and Plug/headless boundaries still independently inspectable. |
| `BX-BH01-INPUT-ARTIFACTS` | 3, 4, 9, 10 | Complete Wasm, BEAM, JavaScript, loader, asset, map, manifest, integrity, size, reachability, and provenance accounting. |
| `BX-BH01-INPUT-BEHAVIORS` | 3–8 | Boot, local state, nesting, form events, timers/messages, DOM updates, failure, fallback, cleanup, and authenticated command evidence. |
| `BX-BH01-INPUT-PRIVATE-API` | 2, 6, 8, 10 | Public/private inventory, pin sensitivity, isolation owner, fallback, and upgrade trigger for every version-sensitive API. |
| `BX-BH01-INPUT-BROWSERS` | 4, 8–10; BH-22 qualification | Exact Linux Chrome/Firefox development outcomes plus explicit deferred records for unavailable desktop/mobile browser and operating-system scenarios. |
| `BX-BH01-INPUT-MEASUREMENTS` | 5, 7, 9, 10; BH-22 qualification | Fingerprinted Linux samples for cold/warm startup, readiness, interaction, memory, build, cleanup, and payload; unavailable cross-platform/mobile samples remain deferred. |
| `BX-BH01-INPUT-STOP-CONDITIONS` | Every phase | A recorded stop/go result at every integration gate and final decision. |

## Proof-obligation coverage

| Proof obligation | First executable phase | Final closure |
| --- | --- | --- |
| `BX-BH01-PROOF-RUNTIME-BOOT` | 3–4 | Repeated boot plus intentional unsupported failure in the active development matrix; cross-platform closure is deferred to BH-22. |
| `BX-BH01-PROOF-ARTIFACT-ACCOUNTING` | 3–4 | Payload/economics review in Phase 9 and clean-build manifest equivalence in Phase 10. |
| `BX-BH01-PROOF-NESTED-STATE` | 5 | Failure/resource stress in Phase 7 and active-browser identity/disposal evidence in Phase 8; broader qualification is deferred. |
| `BX-BH01-PROOF-FORM-EVENT` | 5 | Server-authority evidence in Phase 6 and active-browser input/validation evidence in Phase 8; broader qualification is deferred. |
| `BX-BH01-PROOF-TIMER-MESSAGE` | 3, 5 | Cancellation/resource stress in Phase 7 and active-browser evidence in Phase 8; broader qualification is deferred. |
| `BX-BH01-PROOF-DOM-UPDATE` | 5 | Active-browser behavior in Phase 8 and measured update behavior in Phase 9; broader qualification is deferred. |
| `BX-BH01-PROOF-AUTHENTICATED-COMMAND` | 6 | Adversarial security/lifecycle evidence in Phase 7 and active-browser evidence in Phase 8; broader qualification is deferred. |
| `BX-BH01-PROOF-BROWSER-FALLBACK` | 4 | Active-browser prerequisite, compatibility, and accessible fallback evidence in Phase 8; the unavailable product matrix is deferred to BH-22. |
| `BX-BH01-PROOF-MOBILE-MEASUREMENT` | BH-22 | `[DEFERRED]` Reviewed physical-device constrained-mobile samples; BH-01 records the unavailable obligation without blocking BH-02. |
| `BX-BH01-PROOF-BUILD-REPRODUCIBILITY` | 2 | Independent clean rebuilds and final equivalence review in Phase 10. |

## Risk coverage

| Open feasibility risk | Primary phases | Required disposition |
| --- | --- | --- |
| `BX-BH01-RISK-DEPENDENCY-ACCESS` | 2, 10 | Every required dependency is reproducibly and legally/operationally obtainable, or the baseline stops. |
| `BX-BH01-RISK-TOOLCHAIN-REPRODUCIBILITY` | 2, 10 | Immutable inputs and documented commands produce equivalent clean artifacts, or BH-02 is blocked. |
| `BX-BH01-RISK-RUNTIME-SEMANTICS` | 3, 5, 7–8, 10 | Required process/message/timer/resource behavior works within BH-00 boundaries, has a bounded replacement, or stops framework work. |
| `BX-BH01-RISK-WASM-ARTIFACT-ACCOUNTING` | 3–4, 9–10 | Every runtime/application/loader/asset artifact has explained origin, reachability, integrity, license, and payload. |
| `BX-BH01-RISK-AUTHENTICATED-COMMAND` | 6–8, 10 | Server authority remains independent of client presentation and private renderer state under positive and adversarial scenarios. |
| `BX-BH01-RISK-PRIVATE-API-COUPLING` | 2, 6, 8, 10 | Every private/version-sensitive API stays pinned and isolated with a tested fallback, or its adapter path stops. |
| `BX-BH01-RISK-BROWSER-PREREQUISITES` | 4, 8, 10; BH-22 qualification | Required facilities fail intentionally in the active matrix; unavailable browser products remain explicit deferred risk. |
| `BX-BH01-RISK-MOBILE-PERFORMANCE` | BH-22 | `[DEFERRED]` Representative physical-device performance becomes a release gate when the environment is available, not a blocker to framework abstraction work. |

## Stop/go policy

Every phase integration section evaluates all applicable stop conditions. Work
stops before the next phase when:

1. immutable toolchain inputs and documented commands cannot reproduce
   equivalent explainable artifacts on a clean machine;
2. required behavior cannot execute without redefining the host-neutral
   component, renderer, capability, resource, or trust contracts;
3. Phoenix or private LiveView/LocalLiveView coupling escapes its dedicated
   adapter or contaminates standalone DOM, Plug, core, or portable packages;
4. active Linux browser payload, startup, memory, interaction, or reliability
   is not feasibility-viable and has no bounded mitigation; or
5. artifact origin, reachability, integrity, licensing, security, or payload
   cannot be explained well enough to support later packaging claims.

A stop result is a valid BH-01 outcome. The responsible phase publishes the
failed evidence, affected risks, and decision; it does not change a threshold,
hide an artifact, broaden an adapter, or skip a scenario merely to continue.
Unavailable external operating systems, browsers, devices, services, and manual
assistive-technology pairings are not stop results during BH-01. They are
recorded as `[DEFERRED]` and reactivate as qualification gates at BH-22.

## Shared conventions and delivery rules

1. Obtain explicit approval of this complete plan before initializing any
   project or installing any candidate dependency.
2. Start Phase 1 from synchronized `main` on a dedicated `codex/` feature
   branch and record the approval plus exact BH-00 baseline revision.
3. Complete sections in order, verify each section, and commit once per
   completed section. Open one PR only after the phase integration gate passes
   or records a truthful stop decision.
4. Keep every active checkbox open until reproducible evidence satisfies the
   exact observable outcome. Mark unavailable external-environment work
   `[DEFERRED]`; compilation, a stub, or one happy-path browser run is still
   insufficient for active work.
5. Pin every operating-system image, tool, dependency, browser, build flag,
   private API, and acquisition source used by a result. Floating inputs cannot
   establish feasibility.
6. Keep fixture behavior disposable. BH-01 must not stabilize the semantic UI
   tree, component API, renderer contract, capability API, or effect/resource
   model reserved for BH-02.
7. Treat browser code and state as untrusted. Authority-bearing commands are
   authenticated, authorized against current server state, schema-validated,
   bounded, and audited server-side.
8. Preserve package and profile dependency direction with automated graph and
   forbidden-token checks. Phoenix, LiveView, DOM, JavaScript, Popcorn, and
   browser objects cannot migrate into future portable boundaries.
9. Store raw logs, manifests, environment fingerprints, samples, screenshots,
   generated reports, and deferred-environment records as immutable evidence
   with stable IDs and hashes.
10. Keep all browser configurations unsupported and all proposed budgets
    unpassed until the final reviewed evidence explicitly changes their state.
11. Record negative results, unavailable dependencies, private coupling,
    browser prerequisites, failed fallbacks, and deferred qualification with
    the same rigor as passing results. Deferral is neither pass nor support.
12. Do not begin BH-02, the native-control spike, production component work,
    or browser-support promotion inside BH-01.

## Milestone exit

BH-01 exits when every active input and proof obligation has a stable evidence
record, every active acceptance and quality condition has an outcome, and the
complete pinned baseline rebuilds equivalently in at least two clean Linux
environments. Chrome and Firefox development results must be recorded to the
extent supported by the available local browser/driver interfaces. Every
unavailable cross-platform, mobile, Safari, device, and manual accessibility
obligation must have an explicit `[DEFERRED]` record and BH-22 reactivation
owner. All eight risks and five stop conditions must receive an active or
deferred disposition.

The final decision is one of:

- **proceed:** the candidate baseline is narrow, reproducible, explainable,
  and suitable for BH-02 contract work;
- **proceed with bounded conditions:** named limitations have owners,
  mitigations, expiry/review triggers, and do not compromise BH-00 boundaries;
- **revise and repeat:** a replacement dependency/profile may be evaluated by
  a versioned BH-01 plan amendment and repeated affected phases; or
- **blocked:** one or more stop conditions prevent framework work.

No outcome by itself establishes supported browsers, production readiness,
native-host compatibility, .NET/MudBlazor compatibility, or a stable BlazeX
framework API.

## Index

### Subdirectories

- None yet.

### Documents

- [Phase 1 — Authorization, Evidence Governance, and Repository Activation](phase-01-authorization-evidence-and-repository-activation.md)
- [Phase 1 implementation evidence](phase-01-implementation-evidence.md)
- [Phase 2 — Toolchain and Dependency Qualification](phase-02-toolchain-and-dependency-qualification.md)
- [Phase 2 implementation evidence](phase-02-implementation-evidence.md)
- [Phase 3 — AtomVM/Popcorn Runtime Build and BEAM Packaging](phase-03-runtime-build-and-beam-packaging.md)
- [Phase 3 implementation evidence](phase-03-implementation-evidence.md)
- [Phase 4 — Browser Host Loader, Lifecycle, and Deployment](phase-04-browser-host-loader-lifecycle-and-deployment.md)
- [Phase 4 implementation evidence](phase-04-implementation-evidence.md)
- [Phase 5 — Local Browser Behavior and DOM Vertical Slice](phase-05-local-browser-behavior-and-dom-vertical-slice.md)
- [Phase 5 implementation evidence](phase-05-implementation-evidence.md)
- [Phase 6 — Phoenix Trust Boundary and LiveView Adapter Isolation](phase-06-phoenix-trust-boundary-and-liveview-isolation.md)
- [Phase 6 implementation evidence](phase-06-implementation-evidence.md)
- [Phase 7 — Resilience, Security, and Resource Lifecycle](phase-07-resilience-security-and-resource-lifecycle.md)
- [Phase 7 implementation evidence](phase-07-implementation-evidence.md)
- [Phase 8 — Browser Compatibility and Accessible Fallback Matrix](phase-08-browser-compatibility-and-fallback-matrix.md)
- [Phase 8 implementation evidence](phase-08-implementation-evidence.md)
- [Phase 9 — Measurement, Mobile Viability, and Artifact Economics](phase-09-measurement-mobile-viability-and-artifact-economics.md)
- [Phase 9 implementation evidence](phase-09-implementation-evidence.md)
- [Phase 10 — Clean Rebuild, Review, and Feasibility Decision](phase-10-clean-rebuild-review-and-feasibility-decision.md)
- [Phase 10 implementation evidence](phase-10-implementation-evidence.md)

## Maintaining this index

Keep phase order, dependencies, input/proof coverage, activation boundaries,
and stop conditions synchronized with the BH-00 baseline and browser roadmap.
Add one implementation-evidence document when each phase is delivered and
index it here. A plan amendment must identify the changed dependency or proof,
the affected phases, the reason, the review/approval record, and which evidence
must be invalidated and repeated. Apply the development-environment policy to
every phase: unavailable external-platform qualification is deferred rather
than silently omitted or made an early blocker. Never mark feasibility or
support from plan completion alone.
