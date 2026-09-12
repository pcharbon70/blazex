---
title: "BH-07 Attested Static Delivery Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, contract, phoenix, static-delivery]
aliases: []
---

# BH-07 Attested Static Delivery Contract

Back to the [milestone](README.md) and [Phase 1](phase-01-attested-static-delivery-boundary.md).

The adapter consumes one accepted BH-06 manifest and matching entrypoint
attestation. It validates their entrypoint, manifest, artifact inventory,
decision, path, hash, size, exposure, cache, and SRI bindings before serving.
Only `public` artifacts and `build-manifest.json` are resolvable. Private build
evidence, undeclared files, traversal, unsupported methods, stale identities,
duplicates, and over-limit inputs fail closed.

The reusable validation belongs to `blazex_phoenix`; the profile owns only
route composition and its configured static root. Exact manifest Cache-Control,
media type, strong SHA-256 ETag, content length, GET/HEAD parity, and conditional
requests are preserved. This is development delivery evidence, not production
deployment or support qualification.

LiveView and LocalLiveView are **[DEFERRED]**. Neither is an active dependency,
capability, route, renderer, or test target in this contract.
