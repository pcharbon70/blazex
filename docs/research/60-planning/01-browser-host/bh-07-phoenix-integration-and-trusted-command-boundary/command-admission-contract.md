---
title: "BH-07 Typed Command Admission Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, command, authorization, contract]
aliases: []
---

# BH-07 Typed Command Admission Contract

Back to the [milestone](README.md) and [Phase 5](phase-05-typed-command-admission-and-authorization.md).

The exact public envelope contains `protocol`, `command`, `schema`,
`correlation_id`, `idempotency_key`, `expected_revision`, and `payload`.
Identifiers are bounded strings; revisions are non-negative safe integers; the
payload is a closed map validated against one server-registered declarative
schema. Declarations use only bounded data and primitive integer, string, or
boolean field constraints. No client value selects a module, function, process,
URL, transport, capability, subject, role, grant, or executor.

Admission re-authenticates the opaque session and CSRF proof, loads the trusted
subject identifier from server state, resolves one exact declaration, validates
its schema, and checks a server-owned subject-to-command grant. Unknown commands
and subjects deny by default. Generalized roles and permission policy remain
deferred; the bounded subject grant is private adapter configuration and is
never projected.

Idempotency is scoped to opaque session and key. An exact replay returns the
original receipt with `replayed: true`; a changed request under the same key is
rejected. The authority retains only a SHA-256 fingerprint and bounded receipt,
never the raw payload, session identifier in public snapshots, CSRF proof, or
grant map. It admits at most 32 unique commands per session and 256 globally;
capacity fails closed and reset is explicit. A receipt proves admission only.

Phoenix accepts only POST with one same-origin value, JSON content type, at most
2,048 body bytes, an encrypted session cookie, and the current `x-blazex-csrf`
proof. Responses are bounded, `no-store`, and `nosniff`. Authentication,
authorization, and idempotency are repeated inside the reusable authority; the
transport is not trusted to confer them.

Command execution, effects, and server resource mutation are not implemented.
LiveView and LocalLiveView remain **[DEFERRED]**.
