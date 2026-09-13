---
title: "BH-07 Public Bootstrap Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, bootstrap, contract, security]
aliases: []
---

# BH-07 Public Bootstrap Contract

Back to the [milestone](README.md) and [Phase 2](phase-02-public-bootstrap-envelope.md).

The bootstrap document is public, untrusted after delivery, and incapable of
granting server authority. It identifies the accepted manifest and entrypoint,
the `/bh07/` asset base, the manifest URL, and the currently implemented public
capabilities. An optional `public_state` map contains only explicitly configured,
bounded JSON values.

Keys are strings from a conservative public vocabulary. Secret-, credential-,
cookie-, session-, CSRF-, role-, permission-, authorization-, command-, and
idempotency-like keys fail closed at every depth. Values are null, booleans,
bounded integers, bounded UTF-8 strings, bounded lists, or bounded maps. Depth,
map/list width, key length, string length, integer range, and final encoded size
all have fixed limits. Input normalization never creates atoms.

The exact canonical JSON bytes determine a strong SHA-256 ETag. GET and HEAD
return `application/json`, `no-store`, exact length, and `nosniff`; matching
conditional requests return 304. Other methods return 405. Missing or invalid
delivery/configuration returns 404 without a partial bootstrap.

The envelope deliberately contains no session identifier, authentication
projection, CSRF material, role, permission, allowed action, command endpoint,
push endpoint, reconnect data, or trusted mutable state. Browser visibility or
modification of the document never authorizes a server effect.

LiveView and LocalLiveView are **[DEFERRED]** and have no role in this contract.
