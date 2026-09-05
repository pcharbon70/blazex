---
title: "BH-01 Phase 10 Clean Rebuild, Review, and Feasibility Decision Evidence"
kind: note
created: "2026-09-05"
maturity: developing
tags:
  - bh-01
  - implementation-evidence
  - reproducibility
aliases:
  - "BH-01 phase 10 evidence"
---

# BH-01 Phase 10 Clean Rebuild, Review, and Feasibility Decision Evidence

## Section 10.1 — Independent clean rebuilds

Two authoritative executions rebuilt revision
`4e6301b55dc9f2e44b848818d14c60606c0476a6` from separate Git-archive
extractions with separate empty Hex, Mix, npm, dependency, build, and generated
state. Both used the same immutable BEAM and Emscripten container identities,
five checksum-bound runtime archives, Node 26.8.1, Chrome for Testing
152.0.7977.75, and the available Playwright Firefox 153 development build.
Each execution completed 38 recorded commands and ten browser scenarios with
no operator repair or undeclared tool.

The comparison passes with three exact artifact identities, ten equivalent
semantic browser outcomes, and seven byte-identical regenerated Phase 9
reports. Each run also rejected an intentionally altered profile artifact and
restored it from canonical inputs. Timestamps, durations, raw timing samples,
ports, and ephemeral paths are declared variance. Both executions share one
physical Linux host and therefore do not establish cross-machine or
cross-platform reproducibility.

Three failed A attempts are retained. Attempt 1 localized all AVM drift to one
Jason macro module whose embedded dependency path changed when the repository,
rather than the fixture, was mounted at `/workspace`. The build contract now
mounts the fixture at that canonical root. Attempts 2 and 3 exposed independent
server-log filename and command-hash assignment bugs after all browser scenarios
had completed. Both harness failures were corrected and then re-executed from
fresh state; no failed record was promoted or manually repaired into the
authoritative result.

Unavailable operating systems, Safari, physical mobile devices, second-machine
comparison, and manual assistive-technology pairings remain `[DEFERRED]` to
BH-22. Chrome and Firefox evidence remains development-only and unsupported.

### Canonical evidence

- [Reproducibility harness](../../../../../integration/reproducibility/README.md)
- [Authoritative clean A record](../../../../../integration/reproducibility/raw-evidence/bh01-phase10-clean-a-authoritative.json)
- [Authoritative clean B record](../../../../../integration/reproducibility/raw-evidence/bh01-phase10-clean-b.json)
- [Clean rebuild comparison](../../../../../integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json)
- [Attempt 1 finding](../../../../../integration/reproducibility/raw-evidence/bh01-phase10-clean-a-attempt-1.json)
- [Attempt 2 finding](../../../../../integration/reproducibility/raw-evidence/bh01-phase10-clean-a-attempt-2.json)
- [Attempt 3 finding](../../../../../integration/reproducibility/raw-evidence/bh01-phase10-clean-a-attempt-3.json)

## Section 10.2 — Ledger closure

The canonical closure record reciprocally reconciles the original BH-01
milestone ledger without deleting an unfavorable state. All eight input IDs,
ten proof IDs with original budget and acceptance links, eight risk IDs, and
five binding stop IDs retain their original owners. Thirty formal findings from
Phases 4–10 are preserved with source, disposition, owner, and decision effect;
the exception ledger is empty.

Seven inputs close as active passes, exact-pin-only evidence, or explicit
conditions; browser and measurement inputs preserve BH-22 deferrals. Nine
proofs have active Linux outcomes and the mobile-measurement proof closes for
BH-01 only as deferred—not executed and not passed. Artifact accounting and
timer/message proofs retain the application-payload and Firefox-timer
conditions. Reproducibility, runtime semantics, and adapter isolation do not
trigger their stop conditions. Product viability and artifact accounting are
conditionally not triggered because the failures have bounded mitigations but
continue to block support and release claims.

All eight risks retain likelihood, impact, evidence, mitigation, residual
risk, review trigger, and downstream decision effect. Mobile performance is
still an unknown deferred risk. Private-API coupling and Wasm artifact
economics remain high residual risks. The canonical validator rejects changed
identity sets or owners, altered proof traces, missing evidence, deferred proof
promotion, triggered active stops, stale generated output, and any unreviewed
exception.

### Canonical evidence

- [Closure ledger](../../../../../integration/reproducibility/bh01-phase10-ledger-closure.json)
- [Closure schema](../../../../../integration/reproducibility/ledger-closure.schema.json)
- [Closure generator and validator](../../../../../integration/reproducibility/close_phase10_ledgers.py)

## Section 10.3 — Multidisciplinary feasibility review

Eleven discipline-separated lenses independently challenge product value,
host-neutral architecture, runtime viability, implementation complexity,
candidate alternatives, security, accessibility/input, browser/private-API
compatibility, quality/statistics, build/release provenance, and evidence
reproducibility. The record makes no claim that eleven independent humans
performed these reviews; repository-owner acceptance remains necessary for the
later decision record.

The review selects **proceed with bounded conditions** because required active
semantics, server authority, package isolation, failure behavior, cleanup, and
clean reconstruction are feasible. It retains nine conditions covering AVM
reachability, real Brotli serving, Firefox timer attribution, exact private API
pins, runtime-proof repetition, production security, BH-22 qualification,
fixture disposability, and release controls. Replacement or a dependency fork
remains reserved for a triggered failure; removing the optional LiveView
adapter is a viable fallback; profile optimization is a required later
experiment; blocking the candidate is not selected because no active stop
condition currently requires it.

BH-02 becomes eligible for an explicit entry record and separate owner
authorization only. It is not authorized by this review. Browser support,
mobile viability, accessibility conformance, production security, performance
budget pass, native compatibility, and release readiness remain prohibited
claims.

### Canonical evidence

- [Feasibility review](../../../../../integration/reproducibility/bh01-phase10-feasibility-review.json)
- [Review schema](../../../../../integration/reproducibility/feasibility-review.schema.json)
- [Review generator and validator](../../../../../integration/reproducibility/conduct_phase10_reviews.py)

## Section 10.4 — Versioned feasibility baseline

`BX-BH01-FEASIBILITY-BASELINE-0.1.0` freezes the candidate result against 29
source/evidence bindings, seven exact dependency inputs, the pinned tool list,
three artifact-manifest identities, ten active browser scenarios, the complete
closure inventory, eleven review lenses, nine conditions, six deferred
environment obligations, limitations, and prohibited claims. The baseline is
`candidate-reproducible-proceed-with-bounded-conditions`; it is not a product
release and keeps BH-02 authorization false.

Eight generated indexes expose release, compatibility/limitations, artifacts,
benchmarks, proofs, risks, findings, and environments. Every index names the
baseline ID and canonical JSON hash and is regenerated solely from the
baseline. Validators reject stale source hashes, missing active or deferred
evidence, changed scenario identities, changed generated-view inventory,
incomplete invalidation triggers, support promotion, and implicit BH-02
authorization.

The supersession contract treats this identity and all favorable and
unfavorable evidence as immutable. Source, tool/build-path, dependency/private
API, runtime/OTP, browser, platform/device, scenario/normalization,
mitigation/profile, or quality-threshold changes invalidate affected evidence.
A new version must name this baseline, explain changed bindings, repeat affected
proofs, and reactivate deferred work when the environment appears or BH-22
starts. Rollback selects an immutable prior baseline; it never rewrites one.

### Canonical evidence

- [BH-01 release asset index](../../../assets/bh-01-release/README.md)
- [Feasibility baseline](../../../assets/bh-01-release/blazex-bh-01-feasibility-baseline-v0.1.0.json)
- [Generated release index](../../../assets/bh-01-release/blazex-bh-01-release-index-v0-1-0.md)
- [Baseline generator and validator](../../../../../integration/reproducibility/version_phase10_baseline.py)

## Section 10.5 — BH-02 entry decision

The repository-owner Phase 10 authorization covers making and merging the
feasibility decision. The authorized outcome is **proceed with bounded
conditions**. Its record binds the exact baseline, review, and authorization;
retains proof/risk/stop summaries, nine owned conditions and expiries, zero
blocking findings, zero invalidated evidence, and all prohibited claims. The
Section 10.5 snapshot held BH-01 at final-integration-pending; Section 10.6
promotes that same governed decision to milestone completion after its gate.

The BH-02 entry manifest carries proven runtime/host facts separately from
neutral contract constraints and disposable BH-01 lessons. It names the
planned repository boundaries, nine active proof obligations to repeat, six
BH-22 deferrals, nine conditions, seven leakage prohibitions, and nine required
outputs. Portable constraints reject HTML/DOM, browser/JavaScript,
Phoenix/Plug/LiveView, Popcorn/AtomVM, fixture-wire, and native-toolkit types.

BH-02 is **eligible but not authorized**. Both `authorized` and `may_start` are
false. The repository owner must explicitly authorize BH-02 before any of its
packages, profiles, conformance work, or native portability spike begins.
Replacement, revision, and blocked paths were not selected; their reactivation
triggers remain in the reviewed alternatives and conditions.

### Canonical evidence

- [BH-01 decision](../../../assets/bh-01-release/blazex-bh-01-feasibility-decision-v0.1.0.json)
- [BH-01 decision view](../../../assets/bh-01-release/blazex-bh-01-feasibility-decision-v0-1-0.md)
- [BH-02 entry manifest](../../../assets/bh-01-release/blazex-bh-02-entry-manifest-v0.1.0.json)
- [BH-02 entry view](../../../assets/bh-01-release/blazex-bh-02-entry-manifest-v0-1-0.md)
- [Decision generator and validator](../../../../../integration/reproducibility/decide_phase10_entry.py)

## Section 10.6 — Milestone integration and final acceptance

The final integration gate revalidated the complete Phase 9 suite and the
Phase 10 clean-rebuild, closure, review, baseline, and entry-decision layers.
It verifies both clean records, all 76 retained command-log hashes, the three
failed and resolved A attempts, ten semantic browser scenarios, seven canonical
reports per rebuild, eight inputs, ten proofs, eight risks, five stop
conditions, thirty findings, zero exceptions, eleven review lenses, nine
conditions, six BH-22 deferrals, and every generated release view.

Closure, review, baseline, decision, and handoff records are each regenerated
twice and compared byte-for-byte in memory before their committed forms and
human views are checked. The package, JavaScript, Phoenix profile, benchmark,
archive, source-binding, dependency, private-API, forbidden-direction, and
completion-record gates pass together. The exact commands and outcomes are
retained in the Phase 10 validation log.

BH-01 is therefore complete with an accepted **proceed with bounded
conditions** decision. This permits a later, separately authorized BH-02
framework experiment; it does not start BH-02. Chrome and Firefox remain
unsupported development environments. Browser support, mobile viability,
accessibility conformance, production security, performance-budget pass,
native compatibility, public API stability, and release readiness remain
unclaimed.

### Section delivery record

- Section 10.1 — `7071e0f358903aea4a86c50db982c3fb1086584d`
- Section 10.2 — `e40476cd6f531bfa8a5405c8363508b48be03ac9`
- Section 10.3 — `d4335a128f6883a8c4685b5c073a15375ac40999`
- Section 10.4 — `04c115e317d7edc483c34cd697ac304310a14369`
- Section 10.5 — `82ffbf872c85d306ef0e6c51c253452676cf9c9b`
- Section 10.6 — the final coherent Phase 10 integration and acceptance commit

### Canonical evidence

- [Phase 10 completion record](../../../assets/bh-01-baseline/blazex-bh-01-phase-10-completion-v0.1.0.json)
- [Phase 10 validation log](../../../assets/bh-01-baseline/blazex-bh-01-phase-10-validation-log-v0.1.0.txt)
- [BH-01 final acceptance](../../../assets/bh-01-release/blazex-bh-01-final-acceptance-v0-1-0.md)
- [Milestone integration verifier](../../../../../integration/reproducibility/verify_phase10.py)

## Connections

- [Phase 10 plan](phase-10-clean-rebuild-review-and-feasibility-decision.md)
- [BH-01 plan](README.md)
- [Phase 10 authorization](../../../assets/bh-01-baseline/blazex-bh-01-phase-10-authorization-v0.1.0.json)
