---
title: "BH-06 Delivery Integrity Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, cache, integrity, manifest, sri]
aliases: []
---

# BH-06 Delivery Integrity Contract

Back to the [milestone](README.md) and [Phase 10 plan](phase-10-delivery-integrity-metadata.md).

The application owns a versioned, closed role policy. The build package
validates it without converting external names to atoms. Every manifest
artifact role must occur in the policy and every policy role must occur exactly
once, except `feature-bundle`, which may occur once per declared feature.

For every artifact, the builder reads the final bytes and records both lowercase
SHA-256 and browser-standard SHA-384 SRI (`sha384-` plus canonical base64). It
also copies the role's exact Cache-Control string into the artifact record.
The manifest binds the canonical SHA-256 of the normalized policy.

Verification recomputes both digests and the cache value from disk and policy.
Unknown or unused roles, missing files, path escape, duplicate paths, unsupported
algorithms, invalid cache values, excessive artifacts/bytes, or any digest,
policy, and metadata drift rejects the candidate. Private evidence remains
private; integrity metadata does not authorize it for serving.

`index.html` and `build-manifest.json` remain `no-store`. Content-addressed
public assets use `public, max-age=31536000, immutable`. The manifest itself is
not self-hashed; its source-of-truth protection is transport security plus its
no-store policy, while it authenticates every referenced artifact before boot.

This is delivery metadata, not a production server or release claim. Phoenix,
LiveView, LocalLiveView, routing, prefetch, deployment coordination, support
promotion, BH-07, and BH-19 remain outside the contract.
