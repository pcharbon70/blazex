---
title: "Phase 3 - AtomVM/Popcorn Runtime Build and BEAM Packaging"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - atomvm
  - bh-01
  - implementation-planning
  - webassembly
aliases:
  - "BH-01 phase 3"
---

# Phase 3 - AtomVM/Popcorn Runtime Build and BEAM Packaging

Back to milestone: [README](README.md)

- [ ] 3 Phase - AtomVM/Popcorn Runtime Build and BEAM Packaging.

  Compile the pinned runtime stack into WebAssembly, package a minimal BEAM
  fixture, directly probe required VM semantics, and establish deterministic
  artifact identities before introducing browser-host behavior.

  - [x] 3.1 Section - Build the pinned AtomVM WebAssembly runtime.

    Turn qualified sources and tools into an explainable Wasm artifact with
    explicit features, imports, exports, memory, patches, and build modes.

    - [x] 3.1.1 Task - Implement the canonical runtime build recipe.

      The recipe must expose every transformation and fail when an undeclared
      tool, flag, generated source, or native dependency influences output.

      - [x] 3.1.1.1 Subtask - Define clean configure/compile/link/package commands from the exact AtomVM source revision and qualified Wasm SDK/sysroot.
      - [x] 3.1.1.2 Subtask - Record target/features, optimization/debug flags, memory/table settings, exports/imports, filesystem/network/time/random assumptions, and generated inputs.
      - [x] 3.1.1.3 Subtask - Apply BlazeX-required patches as separate hashed files with rationale, upstream status, license impact, compatibility risk, and removal trigger.
      - [x] 3.1.1.4 Subtask - Produce debug and release runtime artifacts plus build metadata without accepting an opaque prebuilt runtime as proof.

    - [x] 3.1.2 Task - Inspect and validate the Wasm binary contract.

      Binary inspection must confirm that the emitted module matches the
      declared host/deployment assumptions.

      - [x] 3.1.2.1 Subtask - Validate Wasm format, imports/exports, target features, custom/name/source-map sections, memory/table limits, start behavior, and forbidden capabilities.
      - [x] 3.1.2.2 Subtask - Compare debug/release structure, sizes, symbols, and source exposure; fail on undeclared imports, absolute paths, embedded secrets, or unbounded memory settings.
      - [x] 3.1.2.3 Subtask - Generate a runtime binary manifest linking every section/import/export to source revision, build command, owning adapter, and later browser prerequisite.

    - [x] 3.1.3 Task - Integrate Popcorn behind the runtime adapter.

      Popcorn-specific construction and host shims must remain in
      `blazex_runtime_popcorn` rather than becoming product semantics.

      - [x] 3.1.3.1 Subtask - Build and package the exact Popcorn integration, classifying behavior as upstream AtomVM, upstream Popcorn, BlazeX adaptation, patch, or future browser host responsibility.
      - [x] 3.1.3.2 Subtask - Expose only fixture boot/message/lifecycle hooks needed by BH-01 and mark all adapter APIs experimental and replaceable.
      - [x] 3.1.3.3 Subtask - Add source/import guards preventing browser DOM, Phoenix, LiveView, component, or future semantic-tree concerns from entering the runtime adapter.

  - [x] 3.2 Section - Build and package the minimal BEAM fixture.

    A disposable program should prove bundle loading and runtime observability
    without prefiguring the public component framework.

    - [x] 3.2.1 Task - Implement the runtime smoke fixture.

      The fixture needs enough behavior to expose identity, process, message,
      timer, crash, and shutdown semantics before DOM integration.

      - [x] 3.2.1.1 Subtask - Implement deterministic startup, runtime/application identity, one supervisor/process tree, bounded message exchange, timer, readiness record, controlled crash, and graceful shutdown.
      - [x] 3.2.1.2 Subtask - Keep all names/protocols under integration fixtures, exclude inactive BH-02 packages, and label the code non-public and disposable.
      - [x] 3.2.1.3 Subtask - Emit structured traces through the narrow runtime adapter with generation, scenario, process, sequence, result, error, and cleanup fields.

    - [x] 3.2.2 Task - Define deterministic BEAM/AVM bundle construction.

      Module and resource reachability must be explicit so payload and
      provenance can be attributed correctly.

      - [x] 3.2.2.1 Subtask - Define module roots, transitive reachability, resource inclusion, startup arguments, bundle order, compression, and integrity metadata.
      - [x] 3.2.2.2 Subtask - Reject undeclared modules, dynamic code loading, environment-dependent resources, non-reproducible archives, and host-only modules unavailable in AtomVM.
      - [x] 3.2.2.3 Subtask - Produce debug/release bundles and compare module inventories, source paths, hashes, compressed/uncompressed sizes, and reviewed nondeterministic fields.

  - [x] 3.3 Section - Probe required runtime semantics outside the browser.

    Isolate VM limitations early by exercising representative behavior through
    the Wasm runtime in the simplest available harness before adding browser
    loader and DOM variables.

    - [x] 3.3.1 Task - Probe process, mailbox, and supervision behavior.

      BlazeX feasibility depends on bounded process/message semantics and
      observable failures, even though BH-01 does not define framework APIs.

      - [x] 3.3.1.1 Subtask - Exercise spawn, send/receive, ordering assumptions, selective receive if used, links/monitors, process exit, supervisor restart, and repeated teardown.
      - [x] 3.3.1.2 Subtask - Record unsupported OTP/BEAM operations, semantic deviations, scheduler assumptions, mailbox growth, crash propagation, diagnostics, and bounded replacement options.

    - [x] 3.3.2 Task - Probe timers, cancellation, generations, and cleanup.

      Asynchronous work must be cancellable and reject late results before UI
      scenarios depend on it.

      - [x] 3.3.2.1 Subtask - Exercise one-shot/repeated timers, cancellation races, stale generation, timeout, late message, crash/restart, monotonic-time assumptions, and shutdown.
      - [x] 3.3.2.2 Subtask - Instrument process, mailbox, timer, pending-message, memory-page, and cleanup convergence across repeated runs.
      - [x] 3.3.2.3 Subtask - Stop if required semantics are absent and a safe bounded adapter cannot preserve BH-00 component/resource/trust boundaries.

    - [x] 3.3.3 Task - Probe serialization and host-call boundaries.

      Runtime/host data exchange must be bounded and explicit before it carries
      browser events or server commands.

      - [x] 3.3.3.1 Subtask - Define and test allowed scalar/structured fixture payloads, encoding/version, size/depth limits, malformed values, unknown tags, and schema mismatch.
      - [x] 3.3.3.2 Subtask - Exercise request/response identity, timeout, cancellation, duplicate/stale reply, host error, runtime error, and post-disposal traffic.
      - [x] 3.3.3.3 Subtask - Reject arbitrary JavaScript object, DOM handle, code evaluation, filesystem path, secret, or unbounded binary transfer from the runtime contract.

  - [x] 3.4 Section - Establish the initial artifact manifest.

    Account for runtime and application artifacts before browser tooling adds
    more outputs and deployment paths.

    - [x] 3.4.1 Task - Inventory build inputs and outputs.

      Every runtime/bundle byte must have origin, owner, build lineage,
      integrity, size, and reachability information.

      - [x] 3.4.1.1 Subtask - Assign stable artifact IDs to runtime Wasm, debug symbols/maps, BEAM/AVM bundles, generated metadata, build logs, patches, licenses, and notices.
      - [x] 3.4.1.2 Subtask - Record input sources, command, hash, compressed/uncompressed size, MIME expectation, owner, reachability root, build mode, source-map policy, and provenance for each artifact.

    - [x] 3.4.2 Task - Test deterministic artifact production.

      Clean equivalent inputs should produce byte-identical or fully explained
      normalized outputs.

      - [x] 3.4.2.1 Subtask - Build runtime and bundles at least twice from cleaned state, compare bytes/manifests, and investigate timestamps, paths, ordering, random IDs, or tool variance.
      - [x] 3.4.2.2 Subtask - Fail on orphaned, duplicate, unhashed, license-unknown, unreachable, unexpectedly mapped, or undeclared artifacts.
      - [x] 3.4.2.3 Subtask - Preserve preliminary build/payload observations without marking proposed budgets passed.

  - [ ] 3.5 Section - Phase 3 Integration Tests and Completion Evidence.

    Validate the runtime build, BEAM packaging, semantic probes, and initial
    artifact accounting together before browser loading begins.

    - [ ] 3.5.1 Task - Execute runtime and bundle integration tests.

      Tests must use the actual generated Wasm and bundle artifacts rather than
      substituting host ERTS results.

      - [ ] 3.5.1.1 Subtask - Run configure/build/inspect/package/smoke/probe/shutdown from clean state in debug and release modes and correlate traces with artifact IDs.
      - [ ] 3.5.1.2 Subtask - Exercise invalid Wasm, missing import, incompatible feature, corrupt/unknown bundle, missing module, malformed payload, timer race, crash, and cleanup failure paths.
      - [ ] 3.5.1.3 Subtask - Evaluate runtime-semantics and artifact-accounting risks plus the timer/message proof’s runtime portion; record all limitations before browser work.

    - [ ] 3.5.2 Task - Verify determinism and publish phase evidence.

      The phase closes only with reproducible artifacts and a truthful decision
      about whether the browser host is worth attempting.

      - [ ] 3.5.2.1 Subtask - Regenerate artifacts twice, compare hashes/manifests, validate provenance/licenses/source maps/reachability, and run dependency/forbidden-token checks.
      - [ ] 3.5.2.2 Subtask - Publish Phase 3 evidence with exact tools/sources, commands, binary inspections, bundle inventories, semantic traces, failures, artifact hashes, findings, and stop/go decision.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase only after the final integration section passes or records a
truthful stop decision. Do not use host ERTS success to conceal an AtomVM/Wasm
failure.

## Connections

- [BH-01 plan](README.md)
- [Phase 2](phase-02-toolchain-and-dependency-qualification.md)

## Sources

- [BH-01 entry manifest](../../../assets/bh-00-release/blazex-bh-01-entry-manifest-v0-1-0.md)
- [Quality contract](../../../assets/quality-acceptance/blazex-quality-contract-v0.1.0.json)
