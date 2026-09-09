---
title: "Phase 9 - Scoped Context and Manifest-Bounded Dynamic Components"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-05
  - component-model
  - context
  - dynamic-components
  - implementation-planning
aliases:
  - "BH-05 phase 9"
---

# Phase 9 - Scoped Context and Manifest-Bounded Dynamic Components

Back to milestone: [README](README.md)

- [x] 9 Phase - Scoped Context and Manifest-Bounded Dynamic Components.

  Implement small root-scoped named context for genuinely cross-cutting public
  values and a deterministic stable-ID component registry for bounded dynamic
  selection. Prevent ambient global state, hidden server/local crossings,
  arbitrary module dispatch, and uninspectable reachability.

  - [x] 9.1 Section - Authorize and freeze context and registry semantics.

    Bind the public schemas, component roles, scheduler, and action contracts,
    then define scope, subscriptions, registration, lookup, and compatibility.

    - [x] 9.1.1 Task - Record bounded Phase 9 authority.

      Establish provenance and reserve bundle/lazy-loading implementation for
      BH-06.

      - [x] 9.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 8 completion identity, and explicit Phase 9 authorization.
      - [x] 9.1.1.2 Subtask - Bind prop/slot schemas, component/public IDs, root/nested identity, scheduler, effect/capability metadata, trust boundary, and dynamic reachability requirements by version and hash.
      - [x] 9.1.1.3 Subtask - Exclude BH-06 reachability/bundle generation, theme/form/auth product providers, Phoenix session propagation, arbitrary plugins, remote code loading, and support claims.

    - [x] 9.1.2 Task - Freeze root-scoped context policy.

      Define a narrow facility for theme, locale, form state, advisory public
      auth state, capability summary, and future outlet registries without
      silently making every assign ambient.

      - [x] 9.1.2.1 Subtask - Define stable context name, schema/version, owner/provider identity, root/generation scope, fixed or tracked mode, value boundary, default/absence behavior, and visibility.
      - [x] 9.1.2.2 Subtask - Define lexical nearest-provider resolution, subscription identity, update/change comparison, deterministic invalidation order, provider removal/replacement, and cycle/breadth bounds.
      - [x] 9.1.2.3 Subtask - Prohibit process dictionary/application environment/global registry as component context, cross-root subscription, silent server/local crossing, secrets, and authoritative client auth state.

  - [x] 9.2 Section - Implement scoped context declaration and propagation.

    Expose explicit provider/consumer declarations and schedule affected
    component updates through the existing root transition coordinator.

    - [x] 9.2.1 Task - Implement context schemas and provider state.

      Validate values at their declared local or host boundary and retain one
      immutable provider record per scoped identity.

      - [x] 9.2.1.1 Subtask - Implement context declarations with name, schema/version, boundary, fixed/tracked mode, default, documentation, and public/advisory markers.
      - [x] 9.2.1.2 Subtask - Validate provider values before descendant evaluation and reject duplicate same-scope providers, invalid schemas, nonportable host values, secret-marked fields, or unsupported versions.
      - [x] 9.2.1.3 Subtask - Track provider ancestry, accepted value digest, subscribers, revision, generation, and removal state without retaining component/renderer/host objects.

    - [x] 9.2.2 Task - Implement consumption and deterministic invalidation.

      Resolve named values explicitly and update only tracked consumers whose
      accepted dependency changed.

      - [x] 9.2.2.1 Subtask - Resolve nearest visible provider or declared default and record consumer/provider identity, schema, mode, and accepted digest during evaluation.
      - [x] 9.2.2.2 Subtask - Schedule tracked consumer updates in canonical tree order after provider commit while fixed context rejects later mutation by policy.
      - [x] 9.2.2.3 Subtask - Remove subscriptions on consumer/provider replacement/disposal and reject stale/cross-root update notifications before callbacks.

  - [x] 9.3 Section - Implement manifest-bounded dynamic component registration.

    Map stable public IDs to declared modules and contract metadata without
    deriving modules from browser/server strings or scanning arbitrary code.

    - [x] 9.3.1 Task - Define and implement component registry records.

      Make every dynamic target deterministic, versioned, inspectable, and
      usable as a later build reachability root.

      - [x] 9.3.1.1 Subtask - Define public component ID, module, role, contract/schema versions, supported runtime subset, declared capabilities/contexts/actions, package, visibility, and optional feature-bundle ID.
      - [x] 9.3.1.2 Subtask - Build deterministic compile/package/root registry composition with conflict, duplicate, unknown-version, incompatible-role, unavailable-capability, and missing-module diagnostics.
      - [x] 9.3.1.3 Subtask - Export stable registry metadata for BH-06 while prohibiting unrestricted reflection, `Module.concat` from input, dynamic atom creation, arbitrary `apply`, remote module names, and undeclared code loading.

    - [x] 9.3.2 Task - Implement dynamic lookup and invocation.

      Resolve only registered IDs and pass the resulting target through the
      same prop/slot, identity, lifecycle, and reconciliation contracts.

      - [x] 9.3.2.1 Subtask - Validate requested public ID, expected role, schema/version, props/slots, capability/context requirements, and current registry generation before lookup.
      - [x] 9.3.2.2 Subtask - Invoke registered pure or nested-stateful targets with stable identity and define compatible same-ID updates versus explicit replacement when ID/contract changes.
      - [x] 9.3.2.3 Subtask - Reject unknown/unavailable/stale/unauthorized IDs before callback invocation and render the caller-declared semantic fallback or diagnostic without revealing module names.

  - [x] 9.4 Section - Phase 9 Integration Tests and Completion Evidence.

    Exercise context propagation and dynamic selection through public fixtures,
    including adversarial host input, conflicts, updates, replacements, and
    disposal.

    - [x] 9.4.1 Task - Run context and registry integration tests.

      Cover nested providers/consumers, tracked/fixed updates, dynamic roles,
      scheduler interaction, and fail-closed lookup.

      - [x] 9.4.1.1 Subtask - Test default/nearest/nested/fixed/tracked context, contextual slots, provider update/removal/replacement, canonical consumer invalidation, and cleanup.
      - [x] 9.4.1.2 Subtask - Test registry composition, pure/stateful lookup, dynamic update/replacement, metadata export, capability/context requirements, unknown/conflicting IDs, stale registry, and declared fallback.
      - [x] 9.4.1.3 Subtask - Test forged host IDs, dynamic atom/module attempts, arbitrary apply/reflection, secret/advisory-auth misuse, cross-root context, subscription leaks, and deterministic replay.

    - [x] 9.4.2 Task - Publish Phase 9 completion evidence.

      Record the bounded public contracts and exact handoff metadata required
      by BH-06 without implementing bundles.

      - [x] 9.4.2.1 Subtask - Run Core/UI-tree/effects/test suites, context/registry fixtures, security and dependency audits, validators, archive/generated checks, JSON validation, and patch hygiene.
      - [x] 9.4.2.2 Subtask - Publish context/registry schemas, metadata and trace hashes, exact commands/counts, conflicts/rejections, subscription cleanup, failures, and limitations.
      - [x] 9.4.2.3 Subtask - Mark Phase 9 complete only if context is root-scoped and dynamic dispatch is manifest-bounded; make Phase 10 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 9.4 passes or records a stop decision. Ambient global context,
cross-root subscription, arbitrary module dispatch, dynamic atom creation, or
client authorization authority blocks completion.

## Connections

- [BH-05 plan](README.md)
- [Phase 8](phase-08-effects-resources-and-typed-command-intent.md)
- [Host-neutral component-kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [Server adapter and trust boundary](../../../20-notes/architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md)

## Sources

- [Blazor framework semantics beneath BlazeX](../../../20-notes/blazor-framework-semantics-beneath-blazex.md)
- [Foundational component-semantics inquiry](../../../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
