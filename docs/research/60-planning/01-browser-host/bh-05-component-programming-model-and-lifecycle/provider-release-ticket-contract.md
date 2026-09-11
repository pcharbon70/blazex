---
title: "BH-05 Provider Release-Ticket Contract"
kind: note
created: "2026-09-11"
maturity: developing
tags: [bh-05, cleanup, contract, effects, reliability]
aliases: []
---

# BH-05 Provider Release-Ticket Contract

Back to the [Phase 17 plan](phase-17-provider-issued-release-tickets-and-owner-free-disposal.md).

## Authority boundary

Core validates the full lease owner, generation, capability selection, and
acquisition correlation before asking the selected action port to prepare a
release ticket. An Effects bridge passes the existing full resource release
packet to the selected provider at that point. The provider returns an opaque,
portable token scoped to that provider and resource. Preparation does not
release the resource and cannot be initiated by component data.

## Ticket bounds and lifecycle

The runtime envelope contains exactly a version, provider route, lease ID, and
opaque token. The envelope is at most 4096 encoded bytes; contains no owner,
path, capability, selection, acquisition payload, callback state, process,
function, or reference; and is stored only in the runtime-owned inventory.
Registration and transfer replacement are atomic. Explicit terminal release
drops the ticket only after the existing full-descriptor callback completes.

Normal disposal sends ordered ticket envelopes in pages of at most 64. The
selected action port must correlate each result to its page position and may
batch provider ticket releases. A missing or invalid preparation, route
mismatch, malformed result, timeout, or dead owner fails closed into exact
forced cleanup using the authoritative root-ledger descriptor.

Phase 18 permits the internal `release_prepared_ticket_page/2` callback to
return the scalar `:released` only when every ticket in that validated ordered
page completed successfully. Any mixed, failed, partial, or malformed result
must remain an exact positional vector and cannot be collapsed. Public
`release_ticket_page/2` callbacks continue to receive validated envelope maps;
the compact tuple form remains runtime-private.

## Compatibility

The existing immediate `release/2` action-port callback and Effects `Resource`
identity do not change. Ticket callbacks are an internal runtime extension;
providers that do not implement preparation remain usable for immediate work
but cannot claim the bounded normal-disposal qualification. Tickets never
enter component results, semantic trees, snapshots, diagnostics, conformance
traces, or public manifests. LiveView and LocalLiveView remain **[DEFERRED]**.

## Provider migration

An action port implements `prepare_release/2` and either `release_ticket/2` or
`release_ticket_page/2`. The Effects bridge translates those calls to provider
`prepare_release/2` and `release_prepared/2` callbacks. Preparation receives
the same neutral `Resource`, acquisition correlation, and kind used by the
existing immediate release callback; its returned token must be portable and
must not repeat authority-bearing fields. A missing callback, provider-route
mismatch, or invalid token returns `invalid_release_ticket`, so runtime
inventory cannot claim ownership that it cannot later release.
