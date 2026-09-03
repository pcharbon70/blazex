---
title: "BlazeX Cross-Cutting Quality Gate Policy"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - accessibility
  - bh-00
  - compatibility
  - provenance
  - security
aliases:
  - "BlazeX accessibility security compatibility and provenance gates"
---

# BlazeX Cross-Cutting Quality Gate Policy

## Decision

BlazeX defines four release-quality gates that cannot be inferred from a
performance number: accessibility, security, compatibility, and provenance.
Each gate has stable requirement IDs, supported scope, evidence classes, test
contexts, severity rules, an exception policy, an accountable owner, and a
first responsible milestone.

The canonical records are the `BX-GATE-*` entries in the [quality contract
v0.1.0](../assets/quality-acceptance/blazex-quality-contract-v0.1.0.json).
All remain `reviewed-planned` with `planned-not-executed` evidence during
BH-00. A schema-valid gate is not a passing release.

## Shared evidence rules

Automated checks are necessary but not sufficient where browser rendering,
assistive technology, human interpretation, licensing, or security design
judgment determines the result. Each requirement therefore names one or more
evidence classes and whether manual review is required, conditional, or not
required.

Evidence must identify the exact requirement, candidate manifest, profile,
renderer, browser or tool version, fixture, environment, result, owner,
reviewer, date, and immutable artifact. Evidence for one renderer or profile
does not automatically cover another. Generated output must be reproducible;
manual results must include a bounded script and observed outcome.

Severity is assigned by user and system impact, not implementation effort:

- **Blocker** means authority, essential access, state integrity, compatible
  execution, or legal release cannot be preserved.
- **High** means a supported major task or protection is materially impaired
  but an intentional safe path remains.
- **Medium** means the task remains possible with degraded semantics,
  diagnostics, adaptation, or operational quality.
- **Low** means nonessential presentation/documentation quality is affected
  without changing access, authority, compatibility, integrity, or rights.

## Accessibility and interaction gate

The accessibility gate applies to every supported family, renderer, profile,
rendering mode, fallback, and interaction path. Renderer-normalized assertions
must make equivalent semantic claims even when the concrete browser or future
native accessibility APIs differ.

The gate covers:

- role, name, description, relationships, value, state, hierarchy, set
  position, error, required, and disabled semantics;
- complete keyboard behavior, logical order, visible focus, surface trapping,
  restoration, and explicit failure redirection;
- bounded announcements for status, validation, loading, progress, routes,
  surfaces, and asynchronous changes;
- logical directions, 200% zoom, reflow, text spacing, forced colors, reduced
  motion, and content preservation;
- equivalent pointer, touch, keyboard, direct-action, and nonvisual outcomes;
  and
- an accessible fallback or explicit unsupported state for visual,
  permission-dependent, pointer-heavy, timed, virtualized, custom-scene, and
  chart behavior.

Automated semantic-tree and browser checks are combined with exact keyboard,
touch, visual-adaptation, and assistive-technology scripts. The manual matrix
is bounded by the release support window; it does not promise every browser/AT
combination. Missing essential semantics, an inaccessible authority-bearing
action, no supported path, or unrecoverable focus loss is a blocker.

The accessibility gate evaluates BlazeX behavior and fallback, not MudBlazor
pixel parity. A future native renderer must provide its own backend evidence;
DOM evidence cannot establish native accessibility.

## Security gate

The browser is an untrusted execution environment. Component state, persisted
values, renderer traffic, capability results, and visual authorization are
inputs, never authority. Portable components receive semantic values and
opaque capability handles, not browser objects or server credentials.

The gate requires:

1. least-privilege, purpose-bound, owner-bound, cancellable capability grants
   with generation invalidation and classified denial fallback;
2. validation of every browser-originating value before trusted mutation;
3. authenticated and authorized server commands revalidated against current
   server state, with schema and idempotency classification;
4. CSRF, allowed-origin, content-type, replay, and request-size enforcement for
   state-changing Phoenix and Plug paths;
5. secret exclusion, content integrity, restrictive CSP, safe content
   handling, and authenticated deployment metadata; and
6. reachable-dependency risk disposition plus redaction of secrets, tokens,
   personal data, file contents, opaque handles, and sensitive responses.

Authentication, authorization, origin/CSRF, command validation, secret
exclusion, integrity, and critical dependency policy cannot be waived. A
failed boundary check must perform no authority-bearing action and must return
only bounded, non-sensitive diagnostics.

## Compatibility gate

Compatibility is multidimensional. Runtime, execution host, renderer, profile,
package, manifest, schema, protocol, asset, and deployment identities evolve
independently and must remain inspectable. A package-version range alone is
not a complete compatibility claim.

The release publishes exact tested browser windows, runtime/toolchain inputs,
profile compositions, package ranges, evidence dates, and known exclusions.
Unsupported or expired combinations remain candidate or unsupported; Phoenix
success does not imply Plug success, DOM success does not imply native support,
and browser support does not imply another host.

Mismatch is detected before incompatible mutation. The host refuses partial
activation, preserves intentional server/static/unsupported content, and emits
a bounded diagnostic. Upgrade and rollback scenarios include manifests,
protocols, persisted state, asset caches, packages, and interrupted deployment.
No exception may permit mixed incompatible execution.

## Provenance gate

Every distributed source, dependency, generated artifact, and asset must be
accountable. Conceptual inspiration remains distinct from copied, adapted,
translated, vendored, or generated material.

Required records include:

- immutable source revision, access date, license, notices, and approved use
  boundary for source inspiration or incorporated work;
- exact origin, range, transformation, author, review, and distribution status
  for adapted code;
- creator, source, version, license, modification, attribution, and
  redistribution terms for icons, fonts, styles, examples, and images;
- generator revision, complete inputs, deterministic command, environment,
  output hash, ownership, and byte-stability for generated artifacts; and
- resolved version, source, integrity, license, notices, risk disposition, and
  artifact reachability for every direct and transitive dependency.

Unknown or incompatible rights block release. An asset may be omitted or
replaced; missing provenance may not be papered over by a general repository
license. Stale generated output is rejected and never becomes the authored
source of truth.

## Exception model

An exception is a versioned record, never a checkbox override. It names one
requirement, artifact/family/profile scope, rationale, user or system impact,
safe fallback, mitigation, owner, approver, creation and expiry dates, and
removal condition. It expires within one release unless the governing contract
itself is deliberately revised.

Exceptions cannot:

- eliminate an essential accessible path or waive an accessibility blocker;
- bypass authentication, authorization, request boundary, secret, integrity,
  or critical dependency controls;
- permit incompatible mixed-version execution or state corruption;
- authorize unknown/incompatible licensing or untraceable distributed
  material; or
- convert absent, stale, or failed evidence into a pass.

Phase 5 defines no approved exceptions.

## Evidence boundary

These gates define future observable obligations. BH-00 does not run browser,
assistive-technology, penetration, deployment, upgrade, license, SBOM, or
release tests. Gate execution begins at the first named milestones and reaches
release-candidate authority only at BH-22/BH-23 after freshness and coverage
checks pass.

## Connections

- [Quality budget and measurement policy](blazex-quality-budget-and-measurement-policy.md)
- [Browser trust, deployment, and fallback policy](blazex-browser-trust-deployment-and-fallback-policy.md)
- [Component portability, native, and visual-profile policy](blazex-component-portability-native-and-visual-profile-policy.md)
- [Browser host implementation milestones](browser-host-implementation-milestones.md)
- [BH-00 Phase 5 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-05-quality-budgets-and-acceptance-traceability.md)

## Sources

- [Canonical quality contract](../assets/quality-acceptance/blazex-quality-contract-v0.1.0.json)
- [Browser product envelope](../assets/browser-product-envelope-v0.1.json)
- [Component classification](../assets/component-catalog/blazex-component-classification-v0.1.0.json)
