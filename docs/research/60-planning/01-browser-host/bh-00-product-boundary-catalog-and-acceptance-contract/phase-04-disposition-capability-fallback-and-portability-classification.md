---
title: "Phase 4 - Disposition, Capability, Fallback, and Portability Classification"
kind: note
created: "2026-09-02"
maturity: developing
tags:
  - bh-00
  - browser
  - component-catalog
  - implementation-planning
aliases:
  - "BH-00 phase 4"
---

# Phase 4 - Disposition, Capability, Fallback, and Portability Classification

Back to milestone: [README](README.md)

- [x] 4 Phase - Disposition, Capability, Fallback, and Portability Classification.

  Classify every locked catalog family by BlazeX product intent, delivery order,
  package ownership, capability requirements, fallback behavior, and renderer
  portability without implying implementation or MudBlazor compatibility.

  - [x] 4.1 Section - Assign BlazeX dispositions and delivery tiers.

    Turn the source inventory into a bounded product catalog where every family
    has an explicit outcome, rationale, dependency position, and release shape.

    - [x] 4.1.1 Task - Define and apply the disposition policy.

      Dispositions must distinguish native BlazeX design from adaptation,
      deferral, omission, and renderer-specific work without an ambiguous
      backlog state.

      - [x] 4.1.1.1 Subtask - Define accepted disposition values such as build natively, adapt concept, replace with platform pattern, renderer-specific extension, defer, omit, or unresolved, including required rationale for each.
      - [x] 4.1.1.2 Subtask - Assign one disposition to every included, excluded, service, infrastructure, obsolete, and experimental inventory row and prohibit silent default values.
      - [x] 4.1.1.3 Subtask - Review naming, behavior, composition, and visual differences so “inspired by MudBlazor” never implies API, Razor, package, binary, renderer, or visual compatibility.

    - [x] 4.1.2 Task - Assign delivery tier and package ownership.

      Delivery order must follow semantic dependencies and optional payload
      boundaries rather than the reference project's source layout.

      - [x] 4.1.2.1 Subtask - Define and apply F0–F4 or successor tier meanings for kernel proof, foundation, application core, advanced interaction, and optional data or visualization systems.
      - [x] 4.1.2.2 Subtask - Assign each planned family to `blazex_ui`, `blazex_forms`, `blazex_surfaces`, `blazex_data`, `blazex_charts`, another approved package, or no package, with prerequisites and extraction triggers.
      - [x] 4.1.2.3 Subtask - Validate package layering, optional feature boundaries, payload expectations, and shared foundation placement without moving component behavior into profiles or adapters.

  - [x] 4.2 Section - Classify capabilities, remote needs, and fallbacks.

    Express host-heavy and server-heavy behavior through portable contracts and
    explicit degradation rather than direct browser, JavaScript, or Phoenix use.

    - [x] 4.2.1 Task - Assign host and renderer capability requirements.

      Every operation outside pure semantic rendering must identify a named
      capability, its necessity, ownership, lifecycle, and unsupported behavior.

      - [x] 4.2.1.1 Subtask - Finalize catalog-facing capability groups for focus, measurement, pointer, keyboard, clipboard, files, window, surface, notifications, storage, system theme, accessibility, time, and network.
      - [x] 4.2.1.2 Subtask - Assign required and optional host capabilities, renderer semantics, effect ownership, opaque resources, cancellation, timeout, and cleanup needs to every relevant family.
      - [x] 4.2.1.3 Subtask - Reject catalog metadata containing DOM event names, JavaScript handles, CSS selectors, Phoenix sockets, native widget objects, filesystem paths, or unrestricted script escape hatches as portable requirements.

    - [x] 4.2.2 Task - Assign remote-authority and fallback behavior.

      Components must remain honest when server services, host capabilities,
      interaction modes, or accessible visual output are unavailable.

      - [x] 4.2.2.1 Subtask - Assign local-only, optional-remote, required-remote, Phoenix-enhanced, and unavailable-in-Plug service needs without treating presentation as authorization.
      - [x] 4.2.2.2 Subtask - Define and assign fallback values for static content, alternative interaction, server round trip, in-app substitute, nonvisual representation, explicit unavailable state, or omission.
      - [x] 4.2.2.3 Subtask - Require fallback semantics for no JavaScript, no network, denied permission, missing capability, unsupported renderer, failed resource, reduced motion, forced colors, and assistive-technology access where applicable.

  - [x] 4.3 Section - Classify renderer portability and native strategy.

    Preserve a semantic system that can target DOM and future native controls
    while naming families whose design necessarily depends on one backend.

    - [x] 4.3.1 Task - Assign portable and renderer-specific status.

      Portability must be a bounded claim tied to semantic requirements and
      evidence expectations rather than an assumption derived from abstraction.

      - [x] 4.3.1.1 Subtask - Define portable-semantic, portable-with-capabilities, renderer-extension, DOM-specific, native-specific, custom-scene, unsupported, and unproven statuses.
      - [x] 4.3.1.2 Subtask - Assign required semantic nodes, events, effects, accessibility, layout, focus, resource, and renderer-extension needs to every planned family.
      - [x] 4.3.1.3 Subtask - State that headless plus DOM evidence is insufficient for native-widget support and connect portable claims to the later BH-02 native-spike gate.

    - [x] 4.3.2 Task - Assign native-control and visual-profile strategy.

      Future native backends need an explicit intended mapping without selecting
      a production toolkit or promising exact Material fidelity.

      - [x] 4.3.2.1 Subtask - Assign native-preferred, native-composite, custom-drawn, DOM/WebView-only, not-applicable, or unproven strategy to every planned family.
      - [x] 4.3.2.2 Subtask - Record expected platform-native, BlazeX Material, or hybrid visual-profile implications and identify conflicts between OS-native behavior and MudBlazor-inspired appearance.
      - [x] 4.3.2.3 Subtask - Define renderer coverage, fallback, accessibility, and documentation requirements that a future backend must meet before claiming support for a family.

  - [x] 4.4 Section - Phase 4 Integration Tests.

    Prove that every catalog row has a coherent product, package, capability,
    fallback, and portability classification with no unsupported compatibility
    claim or hidden browser dependency.

    - [x] 4.4.1 Task - Validate classification completeness and coherence.

      Machine rules and independent category review must reject missing fields,
      invalid combinations, dependency cycles, and misleading support language.

      - [x] 4.4.1.1 Subtask - Validate every catalog row against disposition, tier, package, capability, remote, fallback, portability, native-strategy, visual-profile, rationale, and evidence-state requirements.
      - [x] 4.4.1.2 Subtask - Reject contradictions such as omitted-but-tiered, portable-with-DOM-types, Plug-with-LiveView, required-capability-without-fallback, or native-supported-without native evidence.
      - [x] 4.4.1.3 Subtask - Independently review every category and all high-risk forms, surfaces, navigation, file, upload, grid, chart, virtualization, and browser-capability families.

    - [x] 4.4.2 Task - Record completion evidence and deliver the phase.

      Phase completion requires every family to have an explicit reviewed
      classification while all implementation and support states remain honest.

      - [x] 4.4.2.1 Subtask - Record catalog revision, classification summaries, validation output, reviewer decisions, unresolved rows, accepted exceptions, and package or tier changes from prior research.
      - [x] 4.4.2.2 Subtask - Confirm no row is marked implemented, evidenced, supported, native-compatible, or API-compatible solely because its product classification is accepted.
      - [x] 4.4.2.3 Subtask - Complete one commit per coherent section and open the Phase 4 PR without beginning quality-budget or acceptance-threshold work.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase; do not merge without a later request.
