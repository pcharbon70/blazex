---
title: "BH-07 Phase 7 - Authenticated Server Push and Resynchronization"
kind: note
created: "2026-09-13"
maturity: developing
tags: [bh-07, phoenix-channels, server-push, reconnect]
aliases: ["BH-07 phase 7"]
---

# BH-07 Phase 7 - Authenticated Server Push and Resynchronization

Back to the [milestone](README.md).

- [x] 7 Phase - Authenticated Server Push and Resynchronization.
  - Need: Phase 6 returns an authoritative command result to its caller but
    cannot notify another authenticated browser or reconcile a reconnecting
    observer with server-owned counter state.
  - Outcome: an authenticated Phoenix Channel publishes bounded redacted
    counter updates and reconnects through a deterministic replay-or-snapshot
    cursor without accepting commands over the socket.
  - Boundary: one fixed counter topic only. No client mutation through the
    channel, arbitrary topic subscription, protected-data projection, general
    PubSub/cluster guarantee, offline queue, persistence, routing/deployment
    coordination, browser effect emission, LiveView, LocalLiveView, or BH-08.

  - [x] 7.1 Section - Authorize and freeze authenticated push.
    - [x] Bind Phase 6 completion/evidence, exact base and sources, delivery
      workflow, server-adapter decision, and deferrals.
    - [x] Freeze socket/topic/event schemas, authentication, cursor semantics,
      replay/snapshot choice, capacity, expiry, monitoring, and cleanup.
    - [x] Activate Phase 7 planning and baseline indexes.

  - [x] 7.2 Section - Implement reusable bounded event streaming.
    - [x] Add authenticated subscription and unsubscription to the serialized
      command authority without introducing Phoenix into the package.
    - [x] Publish one redacted event per successful fresh mutation; retain a
      bounded event history and choose replay or current snapshot by cursor.
    - [x] Bound subscribers, monitor owner processes, prune expired authority,
      and remove session-owned subscriptions and records on revocation/reset.

  - [x] 7.3 Section - Integrate the Phoenix socket and channel.
    - [x] Mount `/bh07/socket` with encrypted-session connect info and canonical
      Phoenix origin checks; require the current CSRF proof at connect/join.
    - [x] Join only `bh07:counter`, return bounded sync state, forward only the
      fixed counter event, and reject every client channel event.
    - [x] Prove cross-session push, reconnect replay/snapshot, forged/expired
      denial, capacity/backpressure behavior, and deterministic teardown.

  - [x] 7.4 Section - Reproduce, review, and publish completion.
    - [x] Run package/profile tests, mutation validator, archive, dependency,
      JSON, formatting, and patch-hygiene gates.
    - [x] Publish source-bound evidence, limitations, inherited unsupported
      status, and the acceptance decision.
    - [x] Accept only with bounded authenticated push, loss-detecting cursor
      resynchronization, no socket command authority, and unchanged deferrals.

## Exit gate

Two authenticated test sessions can observe one server-owned counter mutation.
An exact current cursor receives no duplicate history, a retained cursor replays
the missing events, and an evicted cursor receives a current snapshot. Forged,
expired, over-capacity, malformed, or client-event inputs fail closed without
mutation or unauthorized data, and all subscription processes are cleaned up.
