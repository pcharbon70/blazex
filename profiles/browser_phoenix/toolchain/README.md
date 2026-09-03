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
