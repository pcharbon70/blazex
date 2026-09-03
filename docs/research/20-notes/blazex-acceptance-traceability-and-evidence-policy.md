---
title: "BlazeX Acceptance Traceability and Evidence Policy"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - acceptance-criteria
  - bh-00
  - evidence
  - traceability
aliases:
  - "BlazeX acceptance registry policy"
---

# BlazeX Acceptance Traceability and Evidence Policy

## Decision

Every governed BlazeX browser-product claim has a permanent requirement ID and
at least one observable acceptance-condition ID. The registry connects source
claims to owners, first responsible milestones, integration suites, evidence
classes, release gates, budgets, profiles, and explicit current states.

The canonical registry is generated deterministically from four authored
sources:

1. the browser roadmap;
2. the browser product envelope;
3. the component classification; and
4. the quality contract.

Each source is bound by path and SHA-256. The generator is the mapping logic;
the sources remain the normative product records. Editing the generated JSON
or Markdown cannot change a claim and makes freshness validation fail.

## Requirement coverage

The initial registry covers:

- BH-00 through BH-23 roadmap outcomes;
- all seven roadmap cross-cutting obligations;
- all eight explicit browser 1.0 non-goals;
- every governed browser-envelope browser, toolchain, record, mode, profile,
  adapter, capability, trust, security, deployment, fallback, paper-scenario,
  and forbidden-claim record;
- all 83 classified component families;
- all six classified component package boundaries;
- every proposed quality budget, bounded failure scenario, and non-waivable
  release blocker; and
- every accessibility, security, compatibility, and provenance gate
  requirement.

One source claim currently maps to one acceptance condition to keep ownership
and failure attribution unambiguous. Future versions may map one requirement to
multiple conditions or combine requirements in one integration condition, but
all links must remain reciprocal and complete.

## Acceptance-condition contract

Every condition defines:

- stable condition and requirement IDs;
- subject and normative statement;
- mode and exact profile scope;
- preconditions and action;
- observable and prohibited results;
- required evidence classes and accountable evidence owner;
- owning package/profile/governance scope;
- first responsible milestone, integration suite, and release gate;
- applicable quality-budget IDs;
- product status, support status, implementation state, and verification state;
  and
- immutable evidence IDs, waiver record, and supersession link when allowed.

Observable results describe externally inspectable behavior or generated
artifacts. Prohibited results prevent a superficially successful path from
passing—for example, DOM evidence implying native support, Phoenix success
implying Plug support, missing measurements becoming passes, or a browser demo
implying MudBlazor/.NET compatibility.

## State model

The condition status vocabulary is:

| Status | Meaning | Required combination |
| --- | --- | --- |
| `planned` | Contract exists; work/evidence has not run | Not started or intentionally non-applicable implementation; verification not executed; no evidence, waiver, or supersession |
| `blocked` | A named unmet dependency prevents progress | Not passed or implemented; no waiver-as-pass |
| `implemented` | Behavior exists but acceptance has not executed | Implementation is implemented; verification not executed; no passing evidence |
| `passed` | Required condition executed successfully | Implemented, verification passed, fresh immutable evidence present |
| `failed` | Required condition executed unsuccessfully | Implemented, verification failed, immutable failure evidence present |
| `waived` | A waivable failed/unexecuted condition has temporary authorization | Failure evidence, complete expiring waiver, no passed verification |
| `superseded` | A later permanent condition replaces this one | Replacement condition ID present; no waiver |
| `unsupported` | Product explicitly does not support the condition | Support unsupported; implementation/verification not applicable |
| `not-applicable` | Condition cannot apply to this scope | Support, implementation, and verification all not applicable |

These are mutually exclusive condition statuses. Implementation and
verification fields cannot be combined arbitrarily with them. In particular,
`implemented` is not `passed`, `waived` is not `passed`, and generated/planned
records are not implementation evidence.

Phase 5 emits only `planned`. Browser candidates remain unsupported where the
browser envelope says so, but the condition itself is still planned: later
qualification must execute before support may change.

## Evidence classes

Ten evidence classes have independent freshness and reproducibility rules:

- `automated` — deterministic command, revision, fixture, seed, environment,
  output, and machine-readable result;
- `generated` — immutable inputs, generator revision, command, and byte-stable
  output;
- `benchmark` — every raw sample, environment, manifest, statistical method,
  tool, and comparison baseline;
- `browser` — browser/OS/device/profile/manifest/scenario identity plus traces;
- `accessibility` — semantics, backend/browser, assistive technology, exact
  script, reviewer, and observed result;
- `security` — threat/control, exact build/deployment, sanitized method,
  severity, disposition, and retest;
- `manual` — bounded script, environment, reviewer, expected/observed results,
  and attachments;
- `review` — scope, revisions, reviewer independence, findings, dispositions,
  unresolved risks, and decision;
- `deployment` — topology, manifests, protocols, caches, commands, logs,
  rollback, and outcome; and
- `provenance` — immutable source, license/notices, transformation or
  reachability, reviewer, and distribution scope.

Most release evidence expires after 30 or 90 days and always expires after a
relevant candidate input changes. Generated evidence is source-fresh rather
than calendar-fresh: it must match the current immutable inputs exactly.

Evidence is external to the condition. The registry, schema, validator, and
coverage report cannot cite themselves as proof that runtime or product
behavior passes. A later evidence record must have an immutable `BX-EVIDENCE-*`
identity and be reviewable independently.

## Ownership and first responsibility

The first responsible milestone is when the condition must first execute, not
the only milestone that will ever execute it. Every subsequent milestone that
changes the subject must refresh affected evidence. BH-22 performs product-wide
candidate gates and BH-23 publishes only claims backed by current evidence.

Component families are assigned from classified tier and package ownership.
Budgets use their declared first-measurement milestone. Gate requirements use
their first-execution milestone. Envelope records retain the milestone that
implements or qualifies the corresponding product boundary.

Profiles remain explicit. Phoenix, Plug, and headless coverage are individually
queryable. A condition may target all three but each profile still requires its
own evidence where behavior differs.

## Deterministic coverage findings

Generation and validation compute seven finding sets:

1. source claims without acceptance;
2. catalog families without acceptance;
3. conditions without owners;
4. unsupported status/state transitions;
5. stale evidence;
6. missing budget links; and
7. declared profiles without coverage.

All must be empty for Phase 5 completion. Empty findings mean only that the
planned graph is structurally complete. They do not mean an implementation,
browser, benchmark, accessibility, security, deployment, or release gate has
passed.

## Waivers and supersession

A waiver records its own ID, rationale, owner, approver, creation and expiry
dates, and mitigation. It attaches only to `waived`, never to `planned` or
`passed`. Non-waivable release blockers and the prohibitions in the four
cross-cutting gates remain ineligible.

Supersession preserves the historical record and points to the replacement
condition. IDs are never reused. A source change regenerates normative planned
coverage; a delivered condition requires a governed migration that preserves
prior evidence and status history rather than silently overwriting it.

## Evidence boundary

The registry contains 290 planned conditions and zero executed evidence
records. It does not activate project code, prove a runtime, support a browser,
implement a family, pass a budget, certify accessibility/security, or authorize
a release. Its purpose is to make later truth computable and false completion
machine-rejectable.

## Connections

- [Quality budget and measurement policy](blazex-quality-budget-and-measurement-policy.md)
- [Cross-cutting quality gate policy](blazex-cross-cutting-quality-gate-policy.md)
- [Browser host implementation milestones](browser-host-implementation-milestones.md)
- [BH-00 Phase 5 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-05-quality-budgets-and-acceptance-traceability.md)

## Sources

- [Acceptance registry schema](../assets/quality-acceptance/blazex-acceptance-registry.schema.json)
- [Acceptance registry v0.1.0](../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
- [Generated coverage report](../assets/quality-acceptance/blazex-acceptance-registry-v0-1-0-generated.md)
