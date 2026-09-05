# BH-01 browser profile toolchain

This directory is the machine-readable qualification boundary for BH-01. It
pins the build images, BEAM and JavaScript tools, one reproducible browser
binary, managed-device fingerprint requirements, and dependency acquisition
policy. A pin is an input identity, not evidence that BlazeX builds or boots.

The selected BEAM image exactly supplies OTP 26.0.2 and Elixir/Mix 1.17.3,
which Popcorn 0.3.3 enforces. The selected Emscripten image matches Popcorn's
release Dockerfile at 4.0.8. Chrome for Testing is the local Phase 2 probe;
Firefox, Edge, Android Chrome, and Apple WebKit configurations remain governed
fingerprint profiles for later matrix execution.

Run the static contract and negative tests with:

```console
python3 profiles/browser_phoenix/toolchain/verify_environment.py
python3 -m unittest discover -s profiles/browser_phoenix/toolchain/tests -p 'test_*.py'
```

Dependency acquisition must use isolated homes/caches, exact locks,
noninteractive commands, TLS verification, and the lifecycle allowlist. The
Emscripten and browser archives must never be fetched implicitly by a package
post-install hook.

`runtime.lock.json` additionally replaces Popcorn's mutable FissionVM branch
and FissionVM's HTTP Mbed TLS `FetchContent` default with checksum-verified
local sources. The build contract disables network access during CMake and
build execution. Packaged LocalLiveView runtime assets are inspection oracles,
not accepted rebuild provenance.

`server-dependencies.json` and the committed Mix lock select the exact Phoenix
1.8.13, LiveView 1.2.11, LocalLiveView 0.1.0, Bandit 1.12.5, and supporting
graph. Igniter is fixed at 0.7.9 because its newer `ex_ast` edge requires
Elixir 1.18 and conflicts with Popcorn's exact Elixir 1.17.3 requirement.
`private-api-inventory.json` treats LocalLiveView's direct use of LiveView
renderer, diff, lifecycle, session, socket, and utility internals as a confined
high-risk adapter dependency. It must never enter portable BlazeX packages.

Validate the server graph and coupling contract with:

```console
python3 profiles/browser_phoenix/toolchain/verify_server.py
python3 -m unittest profiles/browser_phoenix/toolchain/tests/test_server.py
```

Phase 6 adds explicit standalone DOM, qualified Plug, and inactive headless
dependency manifests. Their verifier scans the actual local fixture and adapter
sources for forbidden imports and rejects graph drift without claiming that the
scaffold-only profiles are executable:

```console
python3 profiles/browser_phoenix/toolchain/verify_phase6_boundaries.py
python3 -m unittest profiles/browser_phoenix/toolchain/tests/test_phase6_boundaries.py
```

After the actual-browser command matrix has been captured, the complete Phase
6 gate composes the retained Phase 5 gate with server, fixture, dependency,
secret-leakage, adapter-fallback, evidence-hash, and completion-schema checks:

```console
python3 profiles/browser_phoenix/toolchain/verify_phase6.py
python3 -m unittest profiles/browser_phoenix/toolchain/tests/test_phase6.py
```

Phase 7 adds a twenty-generation browser stress run, coordinated recovery,
artifact and authority attacks, correlated diagnostic redaction, and explicit
resource convergence. Its gate composes all earlier gates with the five
resilience contracts and retained actual-browser evidence:

```console
python3 profiles/browser_phoenix/toolchain/verify_phase7.py
python3 -m unittest profiles/browser_phoenix/toolchain/tests/test_phase7.py
```

Phase 8 retains every required browser/device row, separates environment and
manual-evidence blockers from product failures, and prevents the two locally
available engine probes from substituting for stable Firefox or Safari. Its
final verifier composes the retained Phase 7 gate, five browser-matrix
verifiers, one immutable profile identity, raw-record hashes, completion
schemas, and downstream authorization boundaries:

```console
python3 profiles/browser_phoenix/toolchain/verify_phase8.py
python3 -m unittest profiles/browser_phoenix/toolchain/tests/test_phase8.py
```

A successful verifier invocation confirms that the historical evidence is
internally valid. The governed Phase 8 matrix decision remains blocked and all
browsers remain unsupported. The current planning policy carries unavailable
external-platform qualification to BH-22, so Phase 9 is eligible for separate
authorization without rewriting the Phase 8 result.

Phase 9 measures the available Linux Chrome and Firefox environments, retains
manifest-derived artifact and build evidence, applies unchanged quality
budgets, and records external/mobile qualification as deferred. Its final gate
validates all schemas and evidence hashes, composes the Phase 8 and profile
verifiers, regenerates every derived report twice byte-for-byte, retains both
representative-rerun drift reports, and rejects support or Phase 10
authorization overclaims:

```console
python3 profiles/browser_phoenix/toolchain/verify_phase9.py
python3 -m unittest profiles/browser_phoenix/toolchain/tests/test_phase9.py
```

Success means the conditional Phase 9 decision is internally reproducible and
truthfully bounded. It does not turn failed budgets into passes, resolve
representative timing drift, establish mobile viability, or support any
browser.

`unified-dependency-inventory.json` binds the canonical locks and reports by
digest. `acquisition-evidence.json` records true clean and network-disabled
cache replays for Hex and npm, immutable runtime-source replay timings, binary
input checks, and expected failure dispositions. Clean profile copies exclude
ignored `deps`, `_build`, and `node_modules` directories so a warm checkout
cannot masquerade as acquisition evidence.

Validate acquisition evidence and its negative cases with:

```console
python3 profiles/browser_phoenix/toolchain/verify_acquisition.py
python3 -m unittest profiles/browser_phoenix/toolchain/tests/test_acquisition.py
```

After generated runtime and fixture outputs are present, the complete Phase 3
gate composes the frozen Phase 2 checks with runtime-binary, AVM, actual-Wasm
semantics, artifact-accounting, negative-path, activation, completion-schema,
and evidence-hash validation:

```console
python3 profiles/browser_phoenix/toolchain/verify_phase3.py
```
