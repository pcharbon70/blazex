---
title: "Cross-origin isolation and SharedArrayBuffer deployment requirements"
kind: source
created: "2026-09-02"
authors:
  - "Mozilla contributors"
published: 2026
citation_key: "mozilla-2026-cross-origin-isolation"
container: "MDN Web Docs"
edition: null
isbn: null
doi: null
url: "https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cross-Origin-Opener-Policy"
accessed: "2026-09-02"
tags:
  - browser-security
  - cross-origin-isolation
  - shared-memory
  - webassembly
aliases:
  - "COOP and COEP requirements"
---

# Cross-origin isolation and SharedArrayBuffer deployment requirements

## Reference

Mozilla contributors. [“Cross-Origin-Opener-Policy (COOP)
header”](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cross-Origin-Opener-Policy)
and linked MDN cross-origin-isolation documentation. Accessed 2026-09-02.

## Research question or contribution

The documentation explains the browser security headers needed for restricted
features such as `SharedArrayBuffer`, which current Popcorn setup requires.

## Findings

- Cross-origin isolation normally requires
  `Cross-Origin-Opener-Policy: same-origin` plus
  `Cross-Origin-Embedder-Policy: require-corp` or `credentialless`.
- A page can test `globalThis.crossOriginIsolated` before using restricted
  features.
- COEP restricts loading cross-origin resources unless those resources opt in
  through CORS/CORP or compatible policy.
- COOP changes browsing-context relationships, which can affect opener/popup
  workflows.

## Relevance

These are application-wide deployment semantics. BlazeX must expose them as an
explicit host option and test third-party resources, embeds, analytics,
payment flows, OAuth popups, fonts, and CDN policy before adoption.

## Limits

MDN is explanatory browser documentation rather than a BlazeX-specific test.
Exact browser behavior and future Popcorn requirements may change.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [BlazeX feasibility inquiry](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md)
