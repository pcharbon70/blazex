---
title: "Phase 2 - Toolchain and Dependency Qualification"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - bh-01
  - dependencies
  - implementation-planning
  - toolchain
aliases:
  - "BH-01 phase 2"
---

# Phase 2 - Toolchain and Dependency Qualification

Back to milestone: [README](README.md)

- [x] 2 Phase - Toolchain and Dependency Qualification.

  Resolve, pin, acquire, license, and verify every host, language, runtime,
  server, JavaScript, browser, and build input before writing the runtime build
  pipeline, treating dependency unavailability as a valid stop outcome.

  - [x] 2.1 Section - Qualify host and language tools.

    Reproduction requires immutable environment identities and documented
    acquisition paths rather than broad ranges or workstation defaults.

    - [x] 2.1.1 Task - Pin the operating and language environment.

      The baseline must define all tools that can affect dependency resolution,
      compilation, packaging, serving, or test behavior.

      - [x] 2.1.1.1 Subtask - Pin operating-system image/revision, architecture, shell, system packages, CA roots, locale/timezone, environment variables, and resource limits.
      - [x] 2.1.1.2 Subtask - Pin OTP, Elixir, Mix, Hex, Rebar, compiler/linker, Wasm inspection, archive/compression, hashing, and certificate tools with immutable sources and checksums.
      - [x] 2.1.1.3 Subtask - Implement machine-readable environment verification that rejects missing, drifting, shadowed, or implicitly downloaded tools.

    - [x] 2.1.2 Task - Pin JavaScript, browser automation, and reporting tools.

      Client build and measurement tooling must be as reproducible as the BEAM
      and Wasm toolchain.

      - [x] 2.1.2.1 Subtask - Pin Node.js/runtime, package manager, bundler, test runner, browser driver, protocol client, source-map, license, vulnerability, and report-generation tools.
      - [x] 2.1.2.2 Subtask - Define lockfile policy, install flags, lifecycle-script policy, registry/mirror identities, cache behavior, and offline/clean acquisition expectations.
      - [x] 2.1.2.3 Subtask - Record which desktop/mobile browser binaries can be pinned locally and which managed-device versions require per-run fingerprints and drift gates.

  - [x] 2.2 Section - Qualify AtomVM and Popcorn inputs.

    The selected runtime path must be obtainable, buildable in principle, and
    legally/provenance-accountable before implementation depends on it.

    - [x] 2.2.1 Task - Resolve exact runtime sources and build prerequisites.

      Every runtime source, patch, submodule, binary tool, and generated input
      needs an immutable identity.

      - [x] 2.2.1.1 Subtask - Resolve exact AtomVM and Popcorn releases/revisions, repositories, submodules, forks, patches, licenses, checksums, release assets, and documented build prerequisites.
      - [x] 2.2.1.2 Subtask - Inventory Emscripten/WASI/LLVM or other actual Wasm toolchain inputs, target features, SDK/sysroot, build generator, native utilities, and platform-specific requirements.
      - [x] 2.2.1.3 Subtask - Verify sources and build tools can be acquired from clean environments without private credentials, mutable branches, missing artifacts, incompatible licenses, or undocumented manual steps.

    - [x] 2.2.2 Task - Establish runtime provenance and vulnerability inputs.

      Future artifact accounting starts with source and dependency provenance,
      not with the produced `.wasm` file.

      - [x] 2.2.2.1 Subtask - Generate source/dependency inventories with origin, version, hash, license, notice obligation, build/runtime reachability, and owner.
      - [x] 2.2.2.2 Subtask - Record known vulnerability/advisory sources, unsupported upstream combinations, fork divergence, patch maintenance, and update-review triggers.

  - [x] 2.3 Section - Qualify Phoenix, LiveView, and LocalLiveView inputs.

    Select exact server and renderer-integration revisions and expose private or
    fork-specific coupling before building the authenticated path.

    - [x] 2.3.1 Task - Resolve the server dependency graph.

      Direct and transitive dependencies must produce one explainable lock and
      remain owned by the profile/server adapter rather than portable code.

      - [x] 2.3.1.1 Subtask - Resolve exact Phoenix, Plug, LiveView, LocalLiveView, telemetry, serialization, transport, asset, and test dependency revisions with sources, hashes, licenses, and compatibility constraints.
      - [x] 2.3.1.2 Subtask - Generate Mix/Hex dependency graph and locks under deterministic resolver inputs; record optional/environment-specific edges and rejected alternatives.
      - [x] 2.3.1.3 Subtask - Verify the Plug boundary can remain transitively free of Phoenix/LiveView/LocalLiveView and that standalone DOM does not acquire the renderer adapter.

    - [x] 2.3.2 Task - Build the private and version-sensitive API inventory.

      The candidate is acceptable only if unstable coupling is identified,
      pinned, owned, testable, and replaceable or safely disableable.

      - [x] 2.3.2.1 Subtask - Inspect all anticipated LocalLiveView, LiveView renderer-data/diff/patch, socket/channel, lifecycle, generated, and fork-specific APIs against exact source revisions.
      - [x] 2.3.2.2 Subtask - Record public/private status, signature/data shape, owner package, expected call site, pin sensitivity, fallback, compatibility fixture, upgrade trigger, and risk for each API.
      - [x] 2.3.2.3 Subtask - Stop the adapter candidate before coding if required coupling cannot be confined to `blazex_renderer_dom_liveview` or requires portable/runtime code to understand LiveView data.

    - [x] 2.3.3 Task - Qualify browser-facing server prerequisites.

      Server delivery assumptions affect Wasm boot, workers, security, and
      fallback and therefore belong in the selected dependency baseline.

      - [x] 2.3.3.1 Subtask - Record exact Phoenix/Plug support for MIME, compression, cache validation, integrity, CSP, CORS, origin, CSRF, HTTPS, workers, streaming, and cross-origin isolation headers.
      - [x] 2.3.3.2 Subtask - Identify any reverse-proxy/CDN/service-worker requirements and define which are profile prerequisites versus later production deployment work.

  - [x] 2.4 Section - Prove deterministic dependency acquisition.

    Build the immutable lock/provenance baseline and test clean acquisition
    before runtime compilation obscures dependency failures.

    - [x] 2.4.1 Task - Generate and review canonical lock/provenance records.

      All direct/transitive source and binary inputs must reconcile across
      package managers and native build systems.

      - [x] 2.4.1.1 Subtask - Commit deterministic lockfiles/manifests for Hex, JavaScript, runtime source/submodules, native/Wasm SDKs, system-image inputs, and test tools.
      - [x] 2.4.1.2 Subtask - Generate unified dependency, license, notice, origin, checksum, reachability, vulnerability-input, and private-API reports with stable identities.
      - [x] 2.4.1.3 Subtask - Reject orphaned, floating, mutable, unavailable, hashless, license-unknown, implicitly downloaded, or ownerless inputs.

    - [x] 2.4.2 Task - Exercise clean, cached, and failure acquisition paths.

      Reproduction must not rely on a warm developer cache or silently replace
      a missing source with a different artifact.

      - [x] 2.4.2.1 Subtask - Acquire every dependency in a clean environment, capture network/source logs and durations, and compare locks, graphs, checksums, and reports with the canonical baseline.
      - [x] 2.4.2.2 Subtask - Repeat with controlled caches/offline inputs where supported and test missing registry, moved tag, hash mismatch, revoked certificate, unavailable binary, private credential, and lifecycle-script failures.
      - [x] 2.4.2.3 Subtask - Record any platform/device dependencies that cannot be vendored or fully automated and define their run-time fingerprint and stop policy.

  - [x] 2.5 Section - Phase 2 Integration Tests and Completion Evidence.

    Validate exact inputs, acquisition, provenance, compatibility ownership, and
    failure behavior before the runtime build phase begins.

    - [x] 2.5.1 Task - Run cross-toolchain consistency and policy tests.

      Independent managers and reports must describe one coherent candidate
      graph without hidden transitive or private inputs.

      - [x] 2.5.1.1 Subtask - Validate versions/hashes, locks, source origins, dependency graphs, licenses/notices, vulnerability inputs, browser/tool fingerprints, and private-API inventory completeness.
      - [x] 2.5.1.2 Subtask - Run forbidden-edge, Plug/standalone isolation, mutable-input, implicit-download, missing-license, stale-lock, and unavailable-dependency negative tests.

    - [x] 2.5.2 Task - Prove acquisition reproducibility and publish phase evidence.

      Phase 2 closes only when another clean environment can obtain exactly the
      same governed input graph or a stop record rejects the candidate.

      - [x] 2.5.2.1 Subtask - Repeat noninteractive acquisition from a second clean environment and compare locks, sources, dependency/provenance reports, and explainable platform variance.
      - [x] 2.5.2.2 Subtask - Evaluate `BX-BH01-INPUT-TOOLCHAIN`, dependency-access and private-coupling risks, and the preliminary build-reproducibility proof without claiming build success.
      - [x] 2.5.2.3 Subtask - Publish Phase 2 evidence with exact inputs, commands, environments, hashes, acquisition results, findings, stop/go decision, and approved runtime-build inputs.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase only after the final integration section passes or records a
truthful stop decision. Do not begin runtime source changes with unresolved
dependency access, provenance, or private-coupling blockers.

## Connections

- [BH-01 plan](README.md)
- [Phase 1](phase-01-authorization-evidence-and-repository-activation.md)
- [Browser support policy](../../../20-notes/blazex-browser-and-toolchain-support-policy.md)

## Sources

- [BH-01 entry manifest](../../../assets/bh-00-release/blazex-bh-01-entry-manifest-v0-1-0.md)
- [Phase 2 implementation evidence](phase-02-implementation-evidence.md)
- [Phase 2 completion record](../../../assets/bh-01-baseline/blazex-bh-01-phase-02-completion-v0.1.0.json)
