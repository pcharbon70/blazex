---
title: "BH-04 Phase 1 implementation evidence"
kind: note
created: "2026-09-07"
maturity: developing
tags:
  - bh-04
  - renderer
  - implementation-evidence
aliases: []
---

# BH-04 Phase 1 implementation evidence

## Decision and scope

Phase 1 passed its active activation gate. Phase 2 is eligible but unauthorized;
BH-04 milestone acceptance is still outstanding and BH-05 remains ineligible.
No incremental renderer, interaction protocol, LiveView adapter behavior,
performance result, public API stability, or browser support was implemented.

The repository owner authorized this phase explicitly. Work began from
synchronized main `12158e343a4634e65d58a8743bc53903620dc834` on
`codex/bh04-phase1-activation`. Four section commits are delivered in one PR;
the requested workflow is merge, checkout main, synchronize origin, verify
equality, then delete the feature branch. Actual final commit identity resolves
from Git history for the completion record rather than a self-referential hash.

## Sections

1. **1.1:** Bound 14 authoritative inputs, all ten planned phases, the complete
   accepted BH-03 Phase 9 handoff and its 31 inherited obligations. Registered
   the five unchanged canonical BH-04 acceptance rows and future owner/suite/
   phase/closure expectations. The existing approved Phase 2–10 plans are
   imported unchanged and remain unauthorized.
2. **1.2:** Froze six ownership boundaries, direct and transitive inward
   dependency rules and 802 historical source/evidence files. The two central
   package/integration indexes are the only historical boundary documents
   updated. Activated a versioned, JSON-Schema-const-bound index with nine empty
   result classes. The existing BH-01 LiveView descriptor adapter has no
   dependencies; its future DOM/framework edges require Phase 8 authority.
3. **1.3:** Added a standard-library fail-closed gate with exact immutable record
   pins, independently reconstructed Git baseline inventory, source hashes,
   transitive dependency and portable-token checks. Twenty-six initial mutation
   tests passed. A clean Git archive of section 1.3 passed the candidate gate.
4. **1.4:** Completed inherited checks and package formats/tests. Added an
   integration regression for a separately introduced unauthorized authority
   file (27 BH-04 tests total), plus completion gate/commit provenance checks.

## Reproduction and results

See the [validation log](../../../assets/bh-04-baseline/blazex-bh-04-phase-01-validation-log-v0.1.0.txt)
for commands and captured outputs, and the
[completion record](../../../assets/bh-04-baseline/blazex-bh-04-phase-01-completion-v0.1.0.json)
for exact hashes.

- `python3 -m unittest discover -p 'test_*.py'` from `docs/research`:
  326 tests passed, including 27 BH-04 activation tests.
- All 25 `validate_*.py` gates and four `generate_*.py --check` gates passed.
  Pre-publication BH-04 used `--candidate`; completion validation uses the
  default command and requires the bound completion record.
- Pinned local Docker image `a2386c21edd5`, Elixir 1.17.3 / OTP 26:
  `mix format --check-formatted && mix test` passed for core (13), effects (9),
  UI tree (23), neutral renderer (8), standalone DOM (8), optional LiveView
  adapter (4), and headless renderer (6): 71 tests, zero failures.
- Runtime `npm run build && npm test`: 21 passing test files.
  Standalone DOM: seven passing tests. Node 24.3.0 / npm 11.4.2.
- JSON parsing, archive validation, dependency/source audit and
  `git diff --check` passed. Python 3.12.12; Git 2.49.0.
- Initial development errors (a list/dictionary assumption in the new gate
  and removing an already-absent test fixture) were corrected before their
  section commit. They were implementation defects, not waived gate failures.

## Handoff, limitations and historical evidence

BH-03 Phase 8 remains a valid historical **revise** decision. Its Phase 9
correction is the current accepted-with-bounded-conditions handoff. There is
no separate BH-03 release-index file: the Phase 9 acceptance record's complete
source bindings supply that role. No predecessor source or evidence is rewritten.

The inherited BH-02 baseline describes historical candidate contracts;
accepted BH-02 and corrected BH-03 gates establish the current internal
handoff. Existing full-root DOM fixtures are immutable reference evidence,
not proof of BH-04 incremental rendering. Future supersession needs new
versioned fixtures and explicit predecessor links.

The active development matrix remains Linux Chrome and Firefox. This
governance-only phase does not re-execute browser scenarios or invent new
browser rows; it revalidates the source-bound BH-03 accepted evidence.
Controlled runtime callback injection is not OS-crash proof; coarse memory
observations are not long-lived-page leak proof. Inherited obligations retain
their exact owners, states, overlays and reactivation milestones.

[DEFERRED] Other operating systems, Safari, mobile/physical devices, a second
host and manual assistive-technology pairings remain with their inherited
qualification owners, due by BH-22, with no pass credit. No active failure was
reclassified as a deferral. Review was performed by one implementation agent,
not an independent multi-agent review.

## Connections

- [Phase 1 checklist](phase-01-authorization-handoff-reconciliation-and-renderer-boundary-activation.md)
- [Milestone plan](README.md)
- [Activation assets](../../../assets/bh-04-baseline/README.md)
