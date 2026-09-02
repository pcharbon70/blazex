---
title: "Phase 1 - Terminology and Architecture Decision Baseline"
kind: note
created: "2026-09-02"
maturity: developing
tags:
  - bh-00
  - browser
  - implementation-planning
  - product-contract
aliases:
  - "BH-00 phase 1"
---

# Phase 1 - Terminology and Architecture Decision Baseline

Back to milestone: [README](README.md)

- [ ] 1 Phase - Terminology and Architecture Decision Baseline.

  Freeze one canonical vocabulary, preserve the independent architecture axes,
  assign current monorepo ownership, and establish durable decision governance
  before product claims or catalog rows depend on ambiguous words.

  - [x] 1.1 Section - Establish the canonical BlazeX vocabulary.

    Create a normative language boundary that distinguishes framework concepts
    from overloaded ecosystem terms and can be reused by every later phase.

    - [x] 1.1.1 Task - Define the independent architecture dimensions.

      The glossary must make each dimension testable without treating one
      implementation combination as the definition of BlazeX.

      - [x] 1.1.1.1 Subtask - Define runtime substrate, execution host, renderer backend, capability provider, server or remote adapter, packaging shell, executable profile, and portable component contract.
      - [x] 1.1.1.2 Subtask - Give at least one browser, headless, webview, native-process, and standalone-Wasm example showing how the dimensions compose independently.
      - [x] 1.1.1.3 Subtask - Define forbidden equivalences such as Phoenix equals host, Popcorn equals component model, DOM equals renderer contract, or WebAssembly Component Model equals UI component.

    - [x] 1.1.2 Task - Define overloaded product and rendering terms.

      Common words must carry one BlazeX meaning or be explicitly qualified in
      plans, APIs, catalogs, diagnostics, and support claims.

      - [x] 1.1.2.1 Subtask - Define component, component family, semantic node, event, effect, resource, capability, backend, adapter, integration, fallback, and visual profile.
      - [x] 1.1.2.2 Subtask - Define local, remote, server-rendered, static, prerendered, interactive, activated, headless, portable, renderer-specific, and host-specific.
      - [x] 1.1.2.3 Subtask - Publish usage examples and anti-examples that distinguish MudBlazor inspiration from .NET, Razor, API, package, binary, or renderer compatibility.

  - [x] 1.2 Section - Reconcile architecture axes with repository ownership.

    Turn the conceptual decomposition into explicit package, profile,
    integration, JavaScript, and experiment boundaries without activating them.

    - [x] 1.2.1 Task - Publish the current ownership and dependency map.

      Every architectural responsibility must have one primary repository home
      and an enforceable inward dependency direction.

      - [x] 1.2.1.1 Subtask - Map component lifecycle, effects, semantic UI, renderer contracts, concrete renderers, runtime adapters, host adapters, server integrations, build tooling, tests, and component families to current directories.
      - [x] 1.2.1.2 Subtask - Record allowed dependencies for each package class and forbid profiles, Phoenix, Plug, LiveView, DOM, JavaScript, Popcorn, or native toolkit types from flowing into host-neutral contracts.
      - [x] 1.2.1.3 Subtask - Distinguish supported package boundaries from illustrative future desktop, native-renderer, WebView, and non-browser runtime packages.

    - [x] 1.2.2 Task - Define profile composition and experiment boundaries.

      Executable products and bounded proofs must consume reusable contracts
      without becoming hidden framework roots.

      - [x] 1.2.2.1 Subtask - Define the browser/Phoenix, browser/Plug, and headless profile compositions and identify which shared packages each may consume.
      - [x] 1.2.2.2 Subtask - Require the Plug profile to exclude Phoenix, LiveView, LocalLiveView, and the LiveView DOM adapter directly and transitively.
      - [x] 1.2.2.3 Subtask - Define experiment promotion, retirement, and evidence-extraction rules using the BH-02 native renderer spike as the first bounded example.

  - [x] 1.3 Section - Establish durable architecture decision governance.

    Convert accepted research conclusions into identifiable decisions that can
    be reviewed, superseded, and traced without silently rewriting history.

    - [x] 1.3.1 Task - Inventory and identify the BH-00 decisions.

      The decision set must cover every boundary that later phases assume and
      show where its authoritative rationale and status are recorded.

      - [x] 1.3.1.1 Subtask - Assign stable decision IDs for host neutrality, semantic UI, effect and capability isolation, renderer separation, server-adapter separation, profile composition, native portability proof, and non-.NET compatibility.
      - [x] 1.3.1.2 Subtask - Record each decision's status, rationale, consequences, affected packages, alternatives, unresolved evidence, and supersession relationship.
      - [x] 1.3.1.3 Subtask - Resolve the durable decision-record location and format within the approved repository structure before creating normative records.

    - [x] 1.3.2 Task - Define decision change control and review ownership.

      Later evidence may revise a decision, but no implementation shortcut may
      mutate a public boundary without an explicit reviewed record.

      - [x] 1.3.2.1 Subtask - Define proposal, review, acceptance, rejection, supersession, and archival states with named architecture and product owners.
      - [x] 1.3.2.2 Subtask - Require compatibility, security, accessibility, packaging, and cross-backend impact analysis for changes to portable contracts.
      - [x] 1.3.2.3 Subtask - Define how roadmap, catalog, support matrix, package indexes, and acceptance records are updated atomically when a decision changes.

  - [ ] 1.4 Section - Phase 1 Integration Tests.

    Prove that terminology, ownership, dependency direction, and decision
    governance describe one architecture before support and catalog work starts.

    - [ ] 1.4.1 Task - Validate terminology and repository consistency.

      Automated and reviewed evidence must detect ambiguous terms, stale package
      names, missing ownership, and accidental adapter leakage.

      - [ ] 1.4.1.1 Subtask - Run corpus validation and a terminology audit across research, planning, root, package, profile, integration, JavaScript, and experiment documentation.
      - [ ] 1.4.1.2 Subtask - Verify every current package and profile is represented exactly once in the ownership map and every referenced repository path exists.
      - [ ] 1.4.1.3 Subtask - Review representative valid and invalid dependency graphs, including standalone DOM, LiveView DOM, Plug, Phoenix, headless, and future native cases.

    - [ ] 1.4.2 Task - Record completion evidence and deliver the phase.

      Phase completion requires accepted durable records and reproducible checks,
      not agreement expressed only in discussion or planning prose.

      - [ ] 1.4.2.1 Subtask - Record reviewed glossary and decision revisions, validation commands, outputs, reviewers, unresolved questions, and any accepted terminology exceptions.
      - [ ] 1.4.2.2 Subtask - Confirm no Mix project, JavaScript project, runtime proof, component implementation, or BH-01 dependency pin was introduced by this phase.
      - [ ] 1.4.2.3 Subtask - Complete one commit per coherent section and open the Phase 1 PR without beginning Phase 2 product-envelope work.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase; do not merge without a later request.
