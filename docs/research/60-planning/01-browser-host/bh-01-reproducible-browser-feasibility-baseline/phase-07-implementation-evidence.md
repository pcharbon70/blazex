---
title: "BH-01 Phase 7 Resilience, Security, and Resource Lifecycle Evidence"
kind: note
created: "2026-09-04"
maturity: stable
tags:
  - bh-01
  - browser
  - implementation-evidence
  - resilience
  - security
aliases:
  - "BH-01 phase 7 evidence"
---

# BH-01 Phase 7 Resilience, Security, and Resource Lifecycle Evidence

## Decision

BH-01 Phase 7 is complete with a narrow `go` result. In the exact pinned
Chrome for Testing 152.0.7977.75/Linux profile, twenty browser generations ran
mount, local interaction, timer cancellation, authenticated command, selected
disconnect/recovery, and idempotent teardown paths. Four injected transport
interruptions recovered under one coordinator with the original idempotency
identity. Every generation applied exactly one authorized counter effect, and
all declared transient resources converged to their disposal values.

The integrated adversarial boundary also failed closed. A modified Wasm
response was rejected for integrity before runtime readiness; a direct forged
role-bearing command was rejected with `csrf-invalid`; an oversized bridge
string was rejected; hostile HTML remained inert text; and no unauthorized
effect occurred. Twenty-five bounded diagnostics were retained with scenario,
generation, and correlation identity. Redaction passed, while console-only
failures and uncaught browser exceptions remained zero.

This is feasibility evidence, not browser support, a production soak, a memory-
leak or security certification, or a stable BlazeX recovery/resource/diagnostic
API. One browser and operating-system environment was exercised. Phase 8 is
eligible but is not authorized by this decision.

## Section results

### Section 7.1 — Integrated failure and recovery model

The failure taxonomy assigns a single owner, severity, retry disposition,
terminal/fallback outcome, diagnostic class, correlation rule, cleanup owner,
requirements, and stop consequence to sixteen cross-layer failure classes.
The recovery policy places all retry authority in one browser coordinator,
limits each correlation to two attempts with fixed 100/250 ms backoff, forbids
lower-layer retries of authority-bearing commands, preserves idempotency, and
prevents stale-generation revival. Section revision: `8f980b2`.

### Section 7.2 — Cancellation, disposal, and bounded resources

Resource instrumentation covers runtime processes, mailboxes, timers, pending
messages and linear memory; browser listeners, observers, requests, roots and
references; renderer resources; bridge and server transport; server authority;
and optional-adapter generations. The retained report distinguishes baseline,
peak, stable, disposed, leaked, and unknown values. The parent-frame browser
worker count is explicitly unknown rather than silently represented as zero.
Stress limits, eight interruption points, zero-at-disposal fields, accepted
floors, and non-convergence dispositions are machine verified. Section
revision: `875af9d`.

### Section 7.3 — Adversarial security matrix

Deterministic mutation families exercise 27 payload, 15 artifact, and 13
authority vectors with 64 generated iterations per family where applicable.
Bridge and manifest boundaries reject oversized/numerically unsafe values,
prototype keys, path escape, unexpected compression, MIME mismatch, hash
mismatch, redirects and cross-origin artifacts. The Elixir authority rejects
hostile command shapes without dynamic atom creation and applies one effect
under twenty concurrent exact replays. The specialist disposition is limited
to Phase 7 feasibility; production identity, persistence, distributed rate
limiting, monitoring, key rotation, and security certification remain outside
the result. Section revision: `afb75fc`.

### Section 7.4 — Diagnostics and operational evidence

The closed diagnostic contract covers fourteen categories and assigns each a
severity, owner, safe user message, correlation identity, retention rule, and
cleanup/audit expectation. `DiagnosticCollector` retains at most 256 sanitized
records, drops identical duplicates with a count, and produces bounded user and
developer summaries. Key and value redaction covers credentials, cookies,
tokens, private state, bodies/queries, local paths, source snippets, and stack
frames. The browser host records code-bearing runtime, rendering, transport,
and activation failures through this boundary. Section revision: `0c26d65`.

### Section 7.5 — Actual-browser integration and gate

The actual browser run completed twenty generations and four two-attempt
disconnect recoveries. Its 40 resource samples comprise active and disposed
states for each generation. Every disposed runtime reported zero process,
mailbox, pending-message, and timer counts; every disposed renderer reported
zero roots, listeners, and nodes; bridge/server pending work and optional-
adapter generations converged to zero. AtomVM's fixed 256-page linear-memory
floor and one supervised server process are explained non-transient floors.

The run also exposed a teardown defect: calling the stop operation a second
time replaced the first complete resource snapshot with an empty activation.
The host now preserves the first terminal `final_resources` snapshot, making
cleanup idempotent and auditable. After rebuilding the governed profile, the
same Phase 7 browser harness passed. The retained evidence is self-hashed and
the mutation gate rejects changed stress counts, duplicate effects, resource
leaks, early artifact readiness, diagnostic leakage, recovery residue, open
plan work, and evidence-hash drift.

## Gate and limitations

No BH-01 stop condition was triggered. Recovery has one bounded owner,
authority-bearing retries preserve idempotency, hostile inputs and artifact
tampering fail closed, diagnostics are correlated and redacted, and all
declared transient resources converge over the governed run.

- Only one exact headless Chrome/Linux environment was exercised; all browsers
  remain unsupported pending Phase 8.
- Twenty iterations are a bounded feasibility sample, not a production soak or
  memory-leak certification.
- The process inventory is fixture-scoped, and parent-frame worker count is an
  explained unknown.
- The recovery, resource, diagnostic, authority, and adversarial protocols are
  disposable fixtures rather than public framework contracts.
- Production identity, persistence, TLS/proxy behavior, distributed limits,
  audit sinks, monitoring, accessibility, mobile behavior, and security review
  remain unverified.
- Popcorn's CSP `unsafe-eval` requirement remains an open candidate-stack risk.

## Delivery record

- Section 7.1 revision: `8f980b2`.
- Section 7.2 revision: `875af9d`.
- Section 7.3 revision: `afb75fc`.
- Section 7.4 revision: `0c26d65`.
- Section 7.5 is the final coherent commit in the single Phase 7 PR.

## Connections

- [Phase 7 plan](phase-07-resilience-security-and-resource-lifecycle.md)
- [BH-01 plan](README.md)
- [Phase 6 evidence](phase-06-implementation-evidence.md)
- [Phase 7 raw browser evidence](../../../../../integration/fixtures/raw-evidence/bh01-phase7-resilience-security-resource.json)
- [Phase 7 governed scenario](../../../../../integration/fixtures/scenarios/bh01-phase7-resilience-security-resource.json)
- [Phase 7 authorization](../../../assets/bh-01-baseline/blazex-bh-01-phase-07-authorization-v0.1.0.json)
- [Phase 7 validation log](../../../assets/bh-01-baseline/blazex-bh-01-phase-07-validation-log-v0.1.0.txt)
- [Phase 7 completion decision](../../../assets/bh-01-baseline/blazex-bh-01-phase-07-completion-v0.1.0.json)
