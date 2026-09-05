---
title: "Phase 9 - Measurement, Mobile Viability, and Artifact Economics"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - benchmarks
  - bh-01
  - implementation-planning
  - mobile
aliases:
  - "BH-01 phase 9"
---

# Phase 9 - Measurement, Mobile Viability, and Artifact Economics

Back to milestone: [README](README.md)

## Active and deferred scope

Phase 9 is eligible for explicit authorization. Its active execution scope is
the available Linux development environment with Chrome and Firefox. Build,
artifact, startup, interaction, server, memory, cleanup, and reliability work
proceeds in that matrix. Firefox automation limitations must be recorded and
may use a bounded manual smoke run; lack of a particular automation protocol is
not an external-environment blocker.

Android, iOS/iPadOS, macOS/Safari, Windows, physical-device measurements,
cross-platform comparisons, and unavailable manual assistive-technology
pairings are `[DEFERRED]` to BH-22 under the
[development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md).
They remain visible obligations and cannot be represented as passes, support,
or mobile viability.

- [ ] 9 Phase - Measurement, Mobile Viability, and Artifact Economics.

  Measure build, payload, startup, interaction, memory, and reliability from
  canonical artifacts and stable Linux Chrome/Firefox scenarios, then determine
  whether the candidate has a bounded framework-development path. Preserve
  constrained-mobile and unavailable browser measurements as deferred
  production-qualification work.

  - [x] 9.1 Section - Finalize metric definitions and measurement harnesses.

    Each metric requires explicit boundaries, clocks, environment/cache state,
    sample policy, aggregation, variance handling, and artifact correlation.

    - [x] 9.1.1 Task - Implement build and payload measurements.

      Build and payload economics should derive from canonical manifests rather
      than manually selected files.

      - [x] 9.1.1.1 Subtask - Measure clean/incremental release build duration with declared phases, caches, parallelism, machine resources, and success criteria.
      - [x] 9.1.1.2 Subtask - Measure compressed/uncompressed runtime, BEAM/application, JavaScript, loader/worker, maps, manifests, licenses/assets, request count, and total first-load payload.
      - [x] 9.1.1.3 Subtask - Attribute every byte/request to artifact ID, package owner, reachability root, cache class, profile/mode, debug/release inclusion, and integrity metadata.

    - [x] 9.1.2 Task - Implement startup and readiness measurements.

      Startup needs separate network, instantiate, runtime, application, and
      first-observable-root intervals.

      - [x] 9.1.2.1 Subtask - Instrument navigation, manifest/artifact fetch, Wasm instantiate, bundle load, runtime ready, application ready, root ready, and fallback ready with one clock model.
      - [x] 9.1.2.2 Subtask - Define cold/warm cache and process states, network conditions, service-worker behavior, warmups, samples, failures, timeout, and percentile/variance reporting.

    - [x] 9.1.3 Task - Implement interaction, server, resource, and reliability measurements.

      Local and remote paths need comparable boundaries while retaining their
      different authority and network costs.

      - [x] 9.1.3.1 Subtask - Instrument local event receipt, runtime transition, bridge, DOM update, next paint, validation, timer/message, and nested update intervals.
      - [x] 9.1.3.2 Subtask - Instrument authenticated command dispatch, transport, server queue/validation/authorization/effect, response, DOM result, reconnect, retry, and cleanup intervals.
      - [x] 9.1.3.3 Subtask - Instrument initial/peak/stable/disposed memory, Wasm pages, processes/mailboxes/timers/pending work, repeated-growth slope, errors/crashes, long tasks, and cleanup convergence.
      - [x] 9.1.3.4 Subtask - Calibrate harness overhead and clock resolution and record metrics unavailable or unreliable on a browser/device.

  - [ ] 9.2 Section - Execute controlled desktop measurements.

    Produce reproducible raw distributions under fingerprinted Linux Chrome
    and Firefox environments without waiting for other operating systems.

    - [ ] 9.2.1 Task - Run startup and payload experiments.

      Cold and warm results must preserve failed samples and exact cache/network
      conditions.

      - [ ] 9.2.1.1 Subtask - Execute governed sample/warmup counts for clean build, cold/warm navigation, fetch, instantiate, readiness, and fallback under selected desktop environments.
      - [ ] 9.2.1.2 Subtask - Preserve raw samples, failed/time-out runs, medians/percentiles, variance/confidence, outlier flags/rationale, artifact hashes, and environment drift.
      - [ ] 9.2.1.3 Subtask - Repeat a subset in a second clean controlled Linux execution context when available; otherwise record cross-machine comparison as `[DEFERRED]` without blocking the phase.

    - [ ] 9.2.2 Task - Run interaction, command, memory, and reliability experiments.

      Representative local and remote scenarios should be measured over enough
      repetitions to expose growth and tail behavior.

      - [ ] 9.2.2.1 Subtask - Measure local/nested/form/timer/DOM scenarios and authenticated command success/denial/reconnect under stable fixture data.
      - [ ] 9.2.2.2 Subtask - Run repeated lifecycle/resource scenarios, capture growth/convergence/crashes/errors, and correlate anomalies with Phase 7 evidence.

  - **[DEFERRED] 9.3 Section - Execute constrained-mobile measurements.**

    This entire section is deferred until representative Android and iOS/iPadOS
    device infrastructure is available and becomes mandatory no later than
    BH-22. Desktop emulation may inform harness development but cannot close
    these obligations.

    - **[DEFERRED] 9.3.1 Task - Fingerprint and stabilize mobile runs.**

      Mobile evidence must record device conditions that materially affect
      startup, memory, scheduling, networking, and thermal behavior.

      - **[DEFERRED] 9.3.1.1 Subtask** - Record physical device/model/architecture, OS/browser, memory/storage, battery/power, thermal state, display/input, background activity, network shaping, automation, and metric availability.
      - **[DEFERRED] 9.3.1.2 Subtask** - Define cooldown, charging, foreground, cache reset, network, retry, failure retention, and drift checks without substituting desktop emulation for required evidence.

    - **[DEFERRED] 9.3.2 Task - Run mobile startup, interaction, and resource experiments.**

      The subset must directly cover the mobile proof obligation and dominant
      product risks.

      - **[DEFERRED] 9.3.2.1 Subtask** - Measure cold/warm startup, Wasm instantiate, runtime/root readiness, payload/network, fallback, local interaction/paint, and authenticated command.
      - **[DEFERRED] 9.3.2.2 Subtask** - Measure memory/pages, repeated interaction, cleanup, background/foreground or navigation where governed, errors/crashes, long tasks, and thermal/power caveats.
      - **[DEFERRED] 9.3.2.3 Subtask** - Repeat enough samples across Android and iOS/iPadOS candidate scenarios to classify insufficient, failed, conditional, or observed results honestly.

  - [ ] 9.4 Section - Analyze artifact economics and optimization options.

    Identify dominant payload, startup, memory, build, and interaction costs
    before proposing bounded mitigations or threshold changes.

    - [ ] 9.4.1 Task - Attribute costs to artifacts and runtime phases.

      Optimization decisions should connect to owned inputs rather than
      undifferentiated totals.

      - [ ] 9.4.1.1 Subtask - Produce size/reachability and startup critical-path reports by runtime, application modules, JavaScript/loader, maps/assets, requests, compression, and cache behavior.
      - [ ] 9.4.1.2 Subtask - Attribute CPU/time/memory/long-task observations to fetch, instantiate, runtime boot, bundle load, fixture start, bridge, DOM, transport/server, or harness overhead where evidence permits.

    - [ ] 9.4.2 Task - Evaluate bounded mitigations.

      Feasibility optimization may tune build/profile choices but cannot weaken
      proofs or redefine host-neutral contracts.

      - [ ] 9.4.2.1 Subtask - Evaluate stripping, compression, module reachability, split/deferred artifacts, caching, build flags, worker strategy, message batching, or fixture simplification with separate before/after evidence.
      - [ ] 9.4.2.2 Subtask - Reject mitigations that hide required artifacts, remove difficult scenarios, move behavior into JavaScript/server presentation, broaden private coupling, or make builds non-reproducible.
      - [ ] 9.4.2.3 Subtask - Record mitigation owner, expected effect, tradeoff, affected proofs/artifacts, browser constraints, repeat requirements, and expiry/review trigger.

  - [ ] 9.5 Section - Compare observations with budgets and stop conditions.

    Treat BH-00 thresholds as proposed gates to calibrate with evidence rather
    than targets to retroactively lower until the candidate passes.

    - [ ] 9.5.1 Task - Produce statistical budget evaluations.

      Every evaluation must be reproducible from raw samples and preserve
      environment and variance context.

      - [ ] 9.5.1.1 Subtask - Generate per-environment and aggregate observed/pass/fail/insufficient records for active Linux build, payload, startup, interaction, server, resource, cleanup, and reliability budgets; list deferred environments separately.
      - [ ] 9.5.1.2 Subtask - Review active sample adequacy, harness overhead, environment variance, outliers, failures, tail percentiles, automation gaps, and the limits imposed by deferred mobile evidence with quality owners.
      - [ ] 9.5.1.3 Subtask - Require a versioned quality-contract review before changing any threshold, environment, metric boundary, statistic, sample count, or severity.

    - [ ] 9.5.2 Task - Decide active-environment feasibility and preserve deferred viability obligations.

      The candidate proceeds toward framework work only with acceptable local
      results or bounded reviewed mitigations that preserve architecture and
      reproducibility. Product-wide and mobile viability remain undecided.

      - [ ] 9.5.2.1 Subtask - Evaluate active Linux payload/artifact and performance risk; record `BX-BH01-PROOF-MOBILE-MEASUREMENT` and mobile-performance risk as `[DEFERRED]` to BH-22.
      - [ ] 9.5.2.2 Subtask - Record proceed/conditional/repeat/stop recommendation for active development, required mitigations, owner, expiry, repeated phases, deferred qualification, and prohibited support claims.

  - [ ] 9.6 Section - Phase 9 Integration Tests and Completion Evidence.

    Reproduce reports from raw evidence, validate artifact/metric integrity, and
    apply performance stop rules before final clean-build review.

    - [ ] 9.6.1 Task - Run deterministic measurement and report gates.

      Headline values must be derivable byte-for-byte from governed samples and
      canonical artifact/environment identities.

      - [ ] 9.6.1.1 Subtask - Validate raw sample schemas, environment/artifact fingerprints, metric boundaries, clock sources, sample/failure counts, statistics, and reciprocal budget/acceptance links.
      - [ ] 9.6.1.2 Subtask - Regenerate all benchmark/artifact/budget reports twice, compare bytes/hashes, and reject manual spreadsheet values or undocumented data filtering.
      - [ ] 9.6.1.3 Subtask - Rerun representative Linux Chrome/Firefox measurements and compare within governed variance/reproducibility rules; validate that deferred rows remain explicit and excluded from pass rates.

    - [ ] 9.6.2 Task - Review viability and publish phase evidence.

      Phase evidence must retain negative results and clearly separate observed
      feasibility from support or release claims.

      - [ ] 9.6.2.1 Subtask - Review payload, build, Linux browser startup, interaction, command, memory, reliability, cleanup, mitigation, budget outcomes, and deferred external-environment obligations with product/quality/runtime/build owners.
      - [ ] 9.6.2.2 Subtask - Publish Phase 9 evidence with exact tools/environments, raw/report/artifact hashes, statistics, failures, active budget outcomes, deferred mobile proof and risks, stop/go decision, and limitations.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase only after the final integration section passes or records a
truthful stop decision. Do not discard failed active samples or lower a
threshold merely to proceed. Do not substitute emulation for deferred physical-
device evidence or count deferred rows in active-environment pass rates.

## Connections

- [BH-01 plan](README.md)
- [Phase 8](phase-08-browser-compatibility-and-fallback-matrix.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
- [Quality measurement policy](../../../20-notes/blazex-quality-budget-and-measurement-policy.md)

## Sources

- [Quality contract](../../../assets/quality-acceptance/blazex-quality-contract-v0.1.0.json)
