---
title: "BH-06 Payload-Accounting Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, brotli, build, contract, payload]
aliases: []
---

# BH-06 Payload-Accounting Contract

The Phase 8 policy is closed-world. It maps every manifest role to exactly one
owner and either `public` or `private-build-evidence`. Unknown, duplicate, or
unclassified roles reject. Public artifacts retain decoded size and SHA-256;
private reports remain auditable but are not deployable or servable.

Public bytes are Brotli-compressed three times with Node zlib, quality 11. The
three byte strings, not merely their lengths, must match. Each sidecar binds its
decoded source identity and records compressed identity and size. The report
orders artifacts and failures lexically and contains no filesystem paths.

The inherited proposed thresholds are enforced without waiver: loader/bootstrap
at most 35 KiB Brotli, runtime at most 1,600 KiB Brotli, application at most 250
KiB Brotli and 700 KiB decoded, and public source maps exactly zero bytes. A
measurement can complete while its decision is `reject`; such evidence closes
the phase as revision-required and cannot be relabelled as accepted.

The public server may select a verified `.br` representation when the request
advertises Brotli, but integrity continues to describe decoded content. This
local negotiation proof does not qualify Phoenix, Plug, proxies, CDNs, caches,
or production deployment. LiveView and LocalLiveView remain **[DEFERRED]**.

## Connections

- [Phase 8 plan](phase-08-payload-budgets-and-public-artifact-accounting.md)
- [Quality budget policy](../../../20-notes/blazex-quality-budget-and-measurement-policy.md)
