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
