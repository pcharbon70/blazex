---
title: "BH-07 Authenticated Server Push Contract"
kind: note
created: "2026-09-13"
maturity: developing
tags: [bh-07, phoenix-channels, server-push, reconnect]
aliases: []
---

# BH-07 Authenticated Server Push Contract

Back to the [milestone](README.md) and
[Phase 7](phase-07-authenticated-server-push-and-resynchronization.md).

## Transport and authority

The sole socket path is `/bh07/socket` and the sole topic is `bh07:counter`.
The WebSocket handshake uses Phoenix canonical origin enforcement and encrypted
session connect info. Connect accepts exactly protocol
`blazex.bh07.push-connect/1` plus the current CSRF proof; join accepts exactly
protocol `blazex.bh07.push-join/1` plus a non-negative `after_sequence` cursor.
Session and CSRF authority are rechecked before subscription.

The channel accepts no client event and grants no command, resource, handler,
role, permission, or effect authority. The existing HTTPS command route remains
the only mutation path. Socket assigns and server state are private; no opaque
session identifier, proof, subject grant, command body, or raw idempotency key
enters a reply or push.

## Event and cursor

Each fresh successful Phase 6 mutation emits one
`blazex.bh07.counter-update/1` event with a monotonic sequence and the complete
public counter `{id, value, revision}`. Exact command replay and failed commands
emit no event. At most 64 events are retained.

Join returns `blazex.bh07.push-sync/1`. A cursor at or inside retained history
receives the ordered missing events (`mode: replay`). A cursor older than the
retained floor receives the current resource and sequence (`mode: snapshot`). A
cursor ahead of current server sequence is rejected. This is loss-detecting
resynchronization, not durable history or offline command queuing.

## Capacity and lifecycle

At most 64 live subscriptions are retained, with one subscription per owner
process. Exact resubscription replaces the owner's prior monitor without
growing state. Subscribers are monitored and removed on process exit. Expired
sessions are pruned before broadcast; logout/session replacement revokes their
subscription and private execution records. Reset removes all subscribers,
events, execution records, audit, and resource state.

## **[DEFERRED]** scope

Arbitrary topics/events, client socket commands, protected application data,
Phoenix PubSub cluster guarantees, durable event logs, offline queues, automatic
reconnect policy in the browser runtime, routing/deployment-version
coordination, browser effects, credentials, generalized roles/permissions,
production support, LiveView, LocalLiveView, and BH-08 remain deferred.
