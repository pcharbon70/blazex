---
title: "BH-01 Phase 2 Toolchain and Dependency Qualification Evidence"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - bh-01
  - dependency-governance
  - implementation-evidence
  - toolchain
aliases:
  - "BH-01 phase 2 evidence"
---

# BH-01 Phase 2 Toolchain and Dependency Qualification Evidence

## Decision

BH-01 Phase 2 is complete with a narrowly scoped `go` result for the selected
toolchain and dependency inputs. Exact environment, browser, runtime, Phoenix,
LiveView, LocalLiveView, JavaScript, build, provenance, licensing, private-API,
delivery-prerequisite, and acquisition records validate. Two independently
cached clean environments and controlled offline replays produced equivalent
dependency inputs without changing either package-manager lock.

This decision qualifies inputs for Phase 3. It does not establish that
FissionVM/AtomVM builds, that BEAM packaging works, that the runtime boots in a
browser, that LiveView behavior is compatible, or that any browser is
supported. Phase 3 is eligible but not authorized by this completion record.

## Section 2.1 — Host, language, JavaScript, and browser tools

The machine-readable environment fixes Linux/amd64 resource and locale inputs;
digest-addressed BEAM and Emscripten images; OTP 26.0.2; Elixir/Mix 1.17.3; Hex
2.5.1; Rebar 3.24.0; Emscripten 4.0.8; LLVM/Binaryen; CMake/Ninja; Node 26.8.1;
npm 11.19.0; Python 3.12.12; esbuild 0.28.2; and Playwright Core 1.62.1.

Chrome for Testing 152.0.7977.75 is the exact local automation browser.
Firefox, Edge, Android Chrome, and Apple WebKit remain managed fingerprint
profiles with run-time drift gates; they are not presented as reproducibly
vendored binaries or supported configurations. Section revision: `6c1cc4f`.

## Section 2.2 — Popcorn and AtomVM/FissionVM inputs

Popcorn 0.3.3 is tied to exact package and source hashes. Its mutable `swm`
FissionVM branch was replaced by commit `6c3208c7b3dbc7dacc35a19f8de1fa80b358ac73`.
FissionVM's HTTP, tag-only Mbed TLS FetchContent default was replaced by the
verified v3.6.3.1 source and fully disconnected CMake input. Emscripten 4.0.8,
Ninja 1.12.1, build flags, licenses, notices, advisory sources, owners, and
upgrade triggers are fixed.

The packaged LocalLiveView runtime was inspected only as an oracle. It imports
fixed shared memory and atomics, requires threads and cross-origin isolation,
and uses an Emscripten JavaScript ABI—not WASI or the WebAssembly Component
Model. Its package does not embed enough source identity to count as a
reproducible rebuild. Section revision: `d1ec81c`.

## Section 2.3 — Phoenix, LiveView, and LocalLiveView inputs

The profile locks 34 Hex packages, including Phoenix 1.8.13, LiveView 1.2.11,
LocalLiveView 0.1.0, Bandit 1.12.5, Plug 1.20.3, and Popcorn 0.3.3. Igniter is
held at 0.7.9 because the initially selected Igniter 0.8.3 introduced `ex_ast`
0.13.1, which requires Elixir 1.18 and conflicts with Popcorn's exact 1.17.3
constraint. The stale rejected edge was removed from the canonical lock.

LocalLiveView directly uses private or version-sensitive LiveView renderer,
diff, lifecycle, utility, session, socket, wire-diff, and bridge surfaces. The
candidate remains acceptable only because that coupling is pinned and assigned
to `packages/blazex_renderer_dom_liveview`, with fixtures, upgrade triggers,
high-risk status, and a fallback that disables the adapter. Portable packages
must not parse LiveView data. The qualified Plug closure remains free of
Phoenix, LiveView, and LocalLiveView, and standalone DOM remains independent.

Server prerequisites include exact Wasm MIME delivery, HTTPS outside loopback,
origin and CSRF checks, immutable asset validation, worker policy, and COOP,
COEP, and CORP headers. Popcorn's `indirectEval` behavior is an unresolved CSP
compatibility risk for later browser testing. Section revision: `679acf8`.

## Section 2.4 — Deterministic acquisition

The unified inventory binds seven canonical records by SHA-256 and reconciles
system packages, tools, runtime sources, 34 Hex packages, three npm packages,
runtime oracle assets, private APIs, licenses/notices, owners, reachability,
advisory inputs, forbidden input classes, and claim limits.

An empty pinned BEAM container acquired all Hex dependencies without lock
mutation. A fresh network-disabled container replayed them from the controlled
cache and produced a byte-identical dependency tree. Exact Node/npm performed
the equivalent clean and `--offline` npm replays with lifecycle scripts denied
by default; only esbuild's pinned validation script was explicitly invoked.
Immutable Popcorn, FissionVM, Mbed TLS, and emsdk archives were downloaded
again and matched their locks. Section revision: `448fb0b`.

## Section 2.5 — Integration and completion evidence

### Reproducible verification

| Check | Result |
| --- | --- |
| Environment contract | Passed exact image, architecture, tool, registry, browser, hash, lock, cache, lifecycle, and managed-device policy checks. |
| Runtime contract | Passed source, commit, license, provenance, disconnected-build, Wasm-feature, advisory, and forbidden-default checks. |
| Server contract | Passed exact graph, license, optional-edge, rejected-alternative, Plug/DOM boundary, private-API, fixture, and delivery-prerequisite checks. |
| Acquisition contract | Passed canonical-hash, unified-inventory, clean, offline, source, binary, platform-fingerprint, and failure-policy checks. |
| Negative tests | 36 tests passed with no failure; all validators fail closed for their governed drift classes. |
| Independent clean replay | A second empty Hex environment produced the same lock and byte-identical graph; a second empty npm cache produced the same lock and three identities. |
| JavaScript boundary | Exact Node 26.8.1/npm 11.19.0 passed one boundary test and syntax build. |
| Repository hygiene | `git diff --check` passed. No Phase 3 runtime source or generated build artifact was added. |

The [validation log](../../../assets/bh-01-baseline/blazex-bh-01-phase-02-validation-log-v0.1.0.txt)
retains normalized command outcomes, versions, counts, timings, identities,
negative coverage, and claim boundaries. The [completion record](../../../assets/bh-01-baseline/blazex-bh-01-phase-02-completion-v0.1.0.json)
binds the gate decision to its inputs and evidence.

### Risk and stop-condition disposition

- `BX-BH01-RISK-DEPENDENCY-ACCESS` is closed for the selected Phase 2 input
  set: all required inputs were obtained without private credentials.
- `BX-BH01-RISK-TOOLCHAIN-REPRODUCIBILITY` has a passing preliminary input
  result. Artifact reproducibility remains open until runtime builds execute.
- `BX-BH01-RISK-PRIVATE-API-COUPLING` remains open/high but bounded to the
  LiveView adapter with exact pins, fixtures, update gates, and disablement.
- `BX-BH01-RISK-BROWSER-PREREQUISITES` remains open; prerequisites are now
  explicit inputs for later loader and browser tests.
- No BH-01 stop condition is triggered by dependency qualification. Runtime,
  behavior, browser, mobile, security, and artifact-economic conditions remain
  untested and cannot be inferred from this gate.

### Delivery record

- Section 2.1 revision: `6c1cc4f`.
- Section 2.2 revision: `d1ec81c`.
- Section 2.3 revision: `679acf8`.
- Section 2.4 revision: `448fb0b`.
- Section 2.5 is the final coherent commit in the single Phase 2 PR.

## Limitations carried into Phase 3

- The qualified runtime source has not been configured, compiled, linked, or
  compared with LocalLiveView's packaged oracle.
- No `.avm` application bundle, runtime manifest, browser loader, readiness
  protocol, teardown path, DOM behavior, or authenticated server command has
  executed.
- Private LiveView compatibility is an inventory and ownership result, not a
  successful behavior result.
- Cross-origin isolation and CSP requirements have not been exercised through
  Phoenix, a proxy, or a browser.
- All browsers remain unsupported and all quality budgets remain unmeasured.

## Connections

- [Phase 2 plan](phase-02-toolchain-and-dependency-qualification.md)
- [BH-01 plan](README.md)
- [Phase 1 evidence](phase-01-implementation-evidence.md)
- [BH-01 entry manifest](../../../assets/bh-00-release/blazex-bh-01-entry-manifest-v0-1-0.md)
