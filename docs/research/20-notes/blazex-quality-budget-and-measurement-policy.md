---
title: "BlazeX Quality Budget and Measurement Policy"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - bh-00
  - browser
  - performance
  - quality-budgets
  - reliability
aliases:
  - "BlazeX browser quality budgets"
---

# BlazeX Quality Budget and Measurement Policy

## Decision

BlazeX quality claims use stable budget IDs, governed environments, explicit
statistics, reproducible methods, named owners, and first-responsible
milestones. The Phase 5 values are proposed release boundaries. They are not
measurements, baselines, feasibility evidence, or support claims.

The canonical machine contract is [quality contract
v0.1.0](../assets/quality-acceptance/blazex-quality-contract-v0.1.0.json).
Its schema and validator reject evidence IDs and passing states during BH-00.
BH-01 and later milestones may measure, challenge, and version thresholds, but
may not silently relax them or reinterpret missing evidence as success.

## Measurement model

Every budget records:

1. a permanent `BX-BUD-*` identity and one quality dimension;
2. a precise subject, unit, statistic, direction, and proposed threshold;
3. one or more governed environment identities and a minimum sample count;
4. a reproducible method that identifies the fixture and retained records;
5. severity, exception policy, owner, and first measurement milestone; and
6. `proposed-unmeasured` state with no evidence IDs during BH-00.

Measurements must retain raw samples, source revision, content-addressed
manifest, runtime and browser versions, machine fingerprint, network model,
cache and power state, commands, fixture identity, and clock source. Reports
include median, p95, range, and coefficient of variation where meaningful.
The first run is setup-only and discarded. A coefficient of variation above
ten percent requires investigation rather than more favorable averaging.

Like-for-like candidate artifacts are compared by immutable manifest identity.
A five-percent regression triggers review even when the absolute budget still
passes. An absolute breach blocks the owning release gate unless its budget
explicitly permits a scoped, expiring waiver.

## Payload boundaries

Payload accounting separates ownership so a small application cannot hide a
large runtime and one feature cannot charge its assets to a shared bucket.

| Boundary | Included | Excluded |
| --- | --- | --- |
| Loader | Browser bootstrap, manifest loader, runtime activation bridge | Runtime Wasm, application bytecode, feature assets |
| Runtime | AtomVM Wasm, required standard-library bytecode, runtime support | Application and component packages |
| Application | Governed minimal application's own reachable code | Runtime and BlazeX shared packages |
| Shared UI | Semantic tree, renderer contract, tokens, theme, F0 foundation | Optional forms, surfaces, data, and charts |
| Family bundle | Incremental chunks/assets reachable only from one family fixture | Already-accounted shared/runtime bytes |
| Data package | Runtime-heavy table/tree/virtualization code | Chart drawing and chart assets |
| Chart package | Chart code and default chart assets | User datasets and optional third-party themes |
| Fonts/icons | First-view default font subsets and icon assets | Application-supplied media |
| Source maps | Publicly deployable production maps | Private, access-controlled symbol storage |

Compressed transfer budgets use production Brotli settings. Uncompressed
application accounting captures parse/memory pressure separately. Production
source maps have an exact public payload budget of zero; private diagnostics
remain permitted outside the deployment set.

## Startup and interaction boundaries

Cold startup begins at navigation with HTTP and compilation caches cold and
ends only when the first governed root is visibly interactive. Warm startup
uses warm caches but a new page lifecycle. Parse/compile/instantiate and
runtime-ready-to-root-ready are measured separately so one phase cannot mask
another.

Local event-to-paint begins with normalized event dispatch and includes
component evaluation, renderer commit, and the next painted frame. DOM update
begins at renderer receipt. Server command round trip requires an authenticated
command and an acknowledged, reconciled result; client presentation alone is
never success.

The contract defines desktop and constrained mobile cold/warm environments,
plus deterministic CI and production-asset environments. BH-01 must replace
class descriptions with reproducible machine/browser fingerprints before
recording measurements. Thermal throttling, background tabs, debugger
attachment, extensions, and unrelated workload invalidate a run unless the
scenario explicitly studies them.

## Resource and build boundaries

Resource budgets cover retained memory, live-process growth, and terminal
cleanup. The lifecycle fixture performs one hundred mount/use/dispose cycles,
waits for documented stabilization, and excludes only explicitly recorded
persistent services. A browser heap snapshot without BEAM process/resource
inventory is insufficient.

Build timing starts from a clean project output with dependency downloads
already cached and ends when a validated production manifest and all declared
artifacts exist. Dependency acquisition is reported separately because network
variance must not rewrite build performance.

## Resilience budgets

Renderer queues, event backlogs, pending effects, retries, roots, reconnect,
and stale-generation handling have explicit limits. When demand exceeds a
limit, the owning contract must choose documented coalescing, backpressure,
rejection, degradation, or failure. Dropping work invisibly is prohibited.

Eight required failure scenarios cover component failure, renderer failure,
runtime loss, network loss, deployment mismatch, denied capability, corrupted
persisted state, and cleanup. Each defines a bounded observable result and the
first milestone responsible for execution. They do not claim that recovery is
implemented.

The following conditions are unconditional release blockers and cannot be
waived:

- abandoned owned resources;
- unrecoverable focus loss;
- repeatable lifecycle leaks;
- runaway component, renderer, effect, retry, or supervision loops;
- silent loss of accepted user or authoritative state;
- unauthorized automatic retries; and
- unbounded event, renderer, command, effect, diagnostic, or resource queues.

## Threshold governance

A threshold change requires a versioned contract change that includes prior
and proposed values, reason, user impact, measurement method, owner, reviewer,
affected profiles, and roadmap consequences. A benchmark result alone cannot
rewrite the budget. Tightening may occur after reproducible evidence. Relaxing
requires explicit product and quality approval and cannot conceal a regression.

Waivers are scoped to one metric and profile, identify mitigation and an owner,
expire within one release, and remain visible in coverage reports. No waiver
may authorize a security bypass, inaccessible supported path, silent data loss,
unbounded resource behavior, or fabricated evidence.

## Evidence boundary

Phase 5 establishes what later work must measure and how a result is judged.
It does not activate a Mix/JavaScript project, select exact browser versions,
run Popcorn/AtomVM, measure payload or timing, prove Phoenix/Plug behavior, or
grant browser/native support. The quality contract therefore carries:

```text
implementation: not-executed
measurements: not-executed
release-gates: not-executed
evidence-ids: []
```

Any later evidence must be immutable, reproducible, fresh for the candidate
manifest, and linked through the acceptance registry rather than pasted into
the proposed budget record.

## Connections

- [Browser product and toolchain support policy](blazex-browser-and-toolchain-support-policy.md)
- [Browser trust, deployment, and fallback policy](blazex-browser-trust-deployment-and-fallback-policy.md)
- [Component capability, remote, and fallback policy](blazex-component-capability-remote-and-fallback-policy.md)
- [Browser host implementation milestones](browser-host-implementation-milestones.md)
- [BH-00 Phase 5 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-05-quality-budgets-and-acceptance-traceability.md)

## Sources

- [Canonical quality contract](../assets/quality-acceptance/blazex-quality-contract-v0.1.0.json)
- [Browser product envelope](../assets/browser-product-envelope-v0.1.json)
- [Component classification](../assets/component-catalog/blazex-component-classification-v0.1.0.json)
