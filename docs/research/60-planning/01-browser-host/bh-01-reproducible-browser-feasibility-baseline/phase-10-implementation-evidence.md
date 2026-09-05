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

## Remaining Phase 10 work

Sections 10.3–10.6 remain open. Ledger closure does not itself complete
multidisciplinary review, version the baseline, authorize BH-02, or complete
BH-01.

## Connections

- [Phase 10 plan](phase-10-clean-rebuild-review-and-feasibility-decision.md)
- [BH-01 plan](README.md)
- [Phase 10 authorization](../../../assets/bh-01-baseline/blazex-bh-01-phase-10-authorization-v0.1.0.json)
