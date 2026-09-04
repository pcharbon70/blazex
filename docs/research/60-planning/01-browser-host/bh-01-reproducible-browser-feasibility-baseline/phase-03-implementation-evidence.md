---
title: "BH-01 Phase 3 Runtime Build and BEAM Packaging Evidence"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - atomvm
  - bh-01
  - implementation-evidence
  - webassembly
aliases:
  - "BH-01 phase 3 evidence"
---

# BH-01 Phase 3 Runtime Build and BEAM Packaging Evidence

## Decision

BH-01 Phase 3 is complete with a narrowly scoped `go` result for continuing to
the browser-host feasibility phase. The exact FissionVM runtime builds in
debug-web, release-web, and non-deployable release-node-probe modes; the
disposable Elixir fixture packages as debug/release AVM bundles; the release
bundle executes its process, mailbox, supervisor, timer, cancellation,
generation, protocol, failure, and teardown probes inside the actual Wasm VM;
and all 21 generated outputs reproduce byte-for-byte across clean equivalent
builds.

Phase 4 is eligible but not authorized. No browser has loaded these artifacts,
no DOM or Phoenix behavior has executed, and all browsers remain unsupported.
The observed sizes are not a passed payload budget.

Machine-readable completion metadata is retained in the [Phase 3 completion
record](../../../assets/bh-01-baseline/blazex-bh-01-phase-03-completion-v0.1.0.json),
with command outcomes in the [Phase 3 validation
log](../../../assets/bh-01-baseline/blazex-bh-01-phase-03-validation-log-v0.1.0.txt).

## Section 3.1 — Pinned runtime build

The runtime recipe accepts only checksum-qualified FissionVM, Mbed TLS, Ninja,
gperf, and zlib inputs. It runs the digest-pinned Emscripten 4.0.8 image with
networking disabled, fixed locale/time/source epoch, canonical prefix maps,
fixed four-job compilation, and deterministic gzip metadata. It creates two
web modes and a Node-only semantic-probe mode without substituting the opaque
LocalLiveView package runtime.

Binary inspection records every import/export, custom section, memory limit,
atomics observation, glue property, source exposure, and forbidden marker. The
runtime is Emscripten JavaScript ABI Wasm with one imported 256-page shared
memory; it is neither WASI nor the WebAssembly Component Model. Debug symbols
are embedded only in debug-web. No external map is emitted. The adapter remains
experimental and rejects browser DOM, Phoenix, LiveView, component, and
semantic-tree ownership. Section revision: `93fb260`.

## Section 3.2 — Deterministic disposable BEAM fixture

The non-public fixture uses exact Elixir 1.17.3/OTP 26.0.2, Popcorn 0.3.3, and
Jason 1.4.5 inputs. Its fixed boot module starts the AtomVM-compatible
application graph and enters a bounded smoke scenario. The bundle construction
uses a fixed entrypoint, unique sorted BEAM basenames, an explicit 584-module
inventory, no resources or startup arguments, debug line retention, release
line removal, and zero-time gzip headers. Host-only packaging code is excluded
from the AVM, and the temporary boot BEAM is deleted after embedding.

The final debug AVM is 6,987,416 bytes with SHA-256
`8fc4e73c4afc8945c745d23492b8ae4a355948f44e9092aad7f0d9d49178e72a`;
the final release AVM is 6,541,768 bytes with SHA-256
`4f4b7adf6b138df2c232cb03a390674b07f6b51d015722cc0654bd25c4a66a22`.
Section revision: `5371a15`.

## Section 3.3 — Runtime semantics outside the browser

The pinned Node 26.8.1 harness loaded the release-node-probe glue and runtime,
ran the release AVM, and observed 33 contiguous Wasm-emitted traces ending in
`cleanup=complete`, a zero-length guest mailbox, a successful runtime return,
and the fixed 256-page memory contract. The actual VM exercised supervisor
start/stop, process messaging, selective receive, ordering, monitor delivery,
controlled crash/restart, one-shot/repeated timers, cancellation non-delivery,
bounded timeout, stale/current generations, late-result rejection/drain, and a
second process-tree teardown.

The versioned protocol permits only bounded scalar/list/map payloads and
allowlisted operations. It rejects malformed/forbidden capability shapes,
unknown tags, duplicate or stale identities, cancelled replies, and
post-disposal traffic, while distinguishing host and runtime failure classes.
The [runtime findings](../../../../../integration/fixtures/runtime_smoke/runtime-semantics-findings.md)
retain three compatibility limits: AtomVM reports OTP 27 while the fixture is
built with OTP 26.0.2; `Process.cancel_timer/1` returns `false` despite observed
non-delivery; and direct asynchronous calls require the worker-separated
browser host that Phase 4 must prove. Section revision: `7893ac6`.

## Section 3.4 — Artifact manifest and clean-repeat proof

The [unified artifact manifest](../../../assets/bh-01-baseline/blazex-bh-01-phase-03-artifact-manifest-v0.1.0.json)
assigns stable identities to 15 runtime outputs, six fixture outputs, generated
metadata, patch/notice records, embedded symbols, and source-map omissions. It
ties each byte to exact input origins, command lineage, producer hashes, size,
MIME/content encoding, owner, reachability, build mode, source-map policy, and
known license/notice obligations.

The first repeat investigation found no binary runtime drift, but exposed
parallel Ninja transcript ordering and unsorted application-environment capture
inside the generated fixture boot literal. Build logs now receive a declared
lossless line-order normalization, and boot environments are sorted before
compilation. Two clean equivalent builds then matched 21/21 outputs by SHA-256
and size. The validator fails on orphaned, duplicate, unhashed, license-unknown,
unreachable, unexpectedly mapped, undeclared, or non-reproducible artifacts.
Section revision: `dd6b827`.

## Section 3.5 — Integration and completion gate

### Positive and negative execution

The integrated gate validated Phase 1/2 history and current ownership;
runtime source/input/build/binary contracts; the generated debug/release AVM
inventories; retained runtime semantics; artifact accounting; and all eight
negative-path records. Actual runtime negatives cover invalid Wasm, absent
imports, incompatible shared-memory shape, corrupt/unknown AVM input, and a
missing module. The canonical actual-Wasm control covers malformed capability
payload, timer race, crash/restart, late traffic, and clean shutdown. A mutated
cleanup evidence record is rejected by the retained-evidence validator.

### Risk and proof disposition

- `BX-BH01-RISK-RUNTIME-SEMANTICS` remains open but has a passing bounded
  pre-browser result. The timer return-value and direct-call differences are
  explicit Phase 4 gates, not hidden compatibility.
- `BX-BH01-RISK-WASM-ARTIFACT-ACCOUNTING` has a passing initial manifest and
  clean-repeat result. Browser loader/deployment artifacts and final payload
  economics remain open.
- `BX-BH01-RISK-TOOLCHAIN-REPRODUCIBILITY` advances from input-only evidence
  to reproducible runtime/bundle outputs, but final independent Phase 10
  reconstruction remains required.
- The runtime portion of `BX-BH01-PROOF-TIMER-MESSAGE` passes for this fixture.
  Browser scheduling, DOM effects, stress, and compatibility closure remain
  unexecuted.
- No stop condition is triggered. The constrained Node harness does not prove
  browser boot, direct worker calls, cross-origin deployment, CSP behavior,
  DOM rendering, server authority, accessibility, mobile viability, or a
  public component API.

### Delivery record

- Section 3.1 revision: `93fb260`.
- Section 3.2 revision: `5371a15`.
- Section 3.3 revision: `7893ac6`.
- Section 3.4 revision: `dd6b827`.
- Section 3.5 is the final coherent commit in the single Phase 3 PR.

## Limitations carried into Phase 4

- No browser has loaded these artifacts; all browsers remain unsupported.
- The direct JavaScript-to-guest call path is deferred to a worker-separated
  browser host because a same-event-loop Node call cannot progress while the
  VM owns that event loop.
- AtomVM's timer-cancellation return differs from OTP; correctness depends on
  generation checks and observed non-delivery.
- The debug and release AVM bundles intentionally include an unpruned
  584-module baseline and have not passed a payload budget.
- The release bundle removes line chunks but retains upstream BEAM compile
  metadata and paths that require later source-exposure review.
- Emscripten glue retains indirect evaluation, shared-memory/thread, and
  cross-origin-isolation assumptions that Phase 4 and Phase 8 must test.
- Runtime semantics were tested at small bounded scale only; scheduler
  fairness, stress, memory growth, and repeated browser lifecycle remain open.
- No DOM, component, Phoenix, Plug, LiveView, authenticated command, fallback,
  accessibility, mobile, or performance behavior can be inferred.

## Connections

- [Phase 3 plan](phase-03-runtime-build-and-beam-packaging.md)
- [BH-01 plan](README.md)
- [Phase 2 evidence](phase-02-implementation-evidence.md)
- [Artifact-accounting findings](../../../../../integration/fixtures/runtime_smoke/artifact-accounting-findings.md)
- [BH-01 entry manifest](../../../assets/bh-00-release/blazex-bh-01-entry-manifest-v0-1-0.md)
