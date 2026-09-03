---
title: "Desktop packaging, signing, notarization, and sandbox capabilities"
kind: source
created: "2026-09-03"
authors:
  - "Apple"
  - "Microsoft"
  - "Flatpak contributors"
  - "Erlang/OTP team"
published: null
citation_key: "desktop-vendors-2026-packaging-trust"
container: "Platform distribution and runtime documentation"
edition: null
isbn: null
doi: null
url: "https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution"
accessed: "2026-09-03"
tags:
  - desktop
  - distribution
  - linux
  - macos
  - packaging
  - security
  - windows
aliases:
  - "Native host distribution evidence"
---

# Desktop packaging, signing, notarization, and sandbox capabilities

## Reference

Apple. [Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
and [Hardened Runtime](https://developer.apple.com/documentation/security/hardened-runtime).
Microsoft. [MSIX package signing](https://learn.microsoft.com/en-us/windows/msix/package/signing-package-overview).
Flatpak contributors. [Sandbox permissions](https://docs.flatpak.org/en/latest/sandbox-permissions.html)
and [desktop portals](https://docs.flatpak.org/en/latest/portals.html).
Erlang/OTP team. [BEAM JIT internals](https://github.com/erlang/otp/blob/master/erts/emulator/internal_doc/BeamAsm.md)
and [building OTP](https://www.erlang.org/doc/system/install.html). Accessed
2026-09-03.

## Research question or contribution

Which distribution constraints must shape a multi-process BlazeX native host
before it becomes a release problem?

## Findings

- Developer-ID macOS distribution requires signed nested code, Hardened
  Runtime, secure timestamps, notarization, and delivery validation.
  Executable-memory/JIT use needs an explicit entitlement and threat review;
  BEAM can include a JIT depending on its build.
- MSIX packages require a trusted signature, while Windows deployment must
  also account for runtime dependencies, manifests, capabilities, identity,
  and installer/uninstaller behavior.
- Flatpak starts from a restrictive sandbox and expects portals for file
  selection, printing, URI opening, notifications, and similar desktop
  services rather than broad host access.
- These systems grant capabilities differently, so BlazeX effects should name
  intent and opaque resources rather than expose unrestricted paths or native
  objects.

## Relevance

Packaging is an architectural input. A small launcher, renderer, ERTS release,
and native libraries must be built and signed as one target-specific product.
The capability protocol should align with entitlements, package capabilities,
and portals from its first version.

## Limits

No package was produced. Exact entitlements, MSIX identity/capability choices,
Linux format, update channel, and minimum OS/distribution baselines remain
product decisions. This note is not legal or platform-certification advice.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Native renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md)

