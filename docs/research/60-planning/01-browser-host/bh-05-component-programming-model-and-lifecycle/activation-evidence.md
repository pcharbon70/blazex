---
title: "BH-05 Phase 1 implementation evidence"
kind: note
created: "2026-09-08"
maturity: developing
tags: [bh-05, authorization, implementation-evidence]
aliases: []
---

# BH-05 Phase 1 implementation evidence

Back to the [Phase 1 plan](phase-01-authorization-bh-04-handoff-reconciliation-and-boundary-activation.md)
and [milestone index](README.md).

This evidence note uses an activation-specific filename so it is not counted
as a thirteenth phase plan. A post-gate naming check caught that collision;
renaming this new note corrected it without altering a plan or executable.

Decision: **Phase 1 complete — governance only**. Phase 2 is eligible but
unauthorized; BH-06 remains ineligible. No BH-05 callback, macro, component
process, schema behavior, runtime parity, measurement, stable API or support
claim is implemented by this phase.

## Authority and inherited handoff

The owner requested the next phase with one commit per section, a single PR,
merge, synchronized-main return and branch deletion. Prerequisite BH-04 PR #51
merged at `506c254ddd4a14dd8d1d4cbdba8fcf9556bd15cb`. Main was synchronized and
the BH-04 feature branch deleted before `codex/bh05-phase1-activation` began.

The owner's restored twelve-phase planning revisions are retained. Unrelated
demo/root README changes are excluded and preserved in stash
`703e7ab7e71b9900cd2e31a3df7c417f6775a8fa`; older backups are retained too.

The [authorization](../../../assets/bh-05-baseline/authorization-v0.1.0.json)
binds the accepted corrective decision, historical completion/release/entry
records, BH-02 baseline, roadmap, ADRs, canonical acceptance registry, quality
contract and deferral policies. The original Phase 10 revise decision remains
historical; the corrective record is its accepted successor, not a rewrite.

## Section results

| Section | Commit | Outcome |
| --- | --- | --- |
| 1.1 | `68f74fc` | Exact authority, accepted handoff and nine-condition ledger; inherited restrictions retained |
| 1.2 | `0fd6f29` | Package/unit graph, nine inherited Core module inventories and fourteen empty evidence classes |
| 1.3 | `1fde159` | Fail-closed validation and ten mutation-test groups |
| 1.4 | this delivery commit | Source-frozen gates and governance-only completion |

The [ownership inventory](../../../assets/bh-05-baseline/ownership-v0.1.0.json)
distinguishes pure, nested-stateful and process-root units. Existing experimental
callbacks remain unchanged, with preservation/supersession/migration phases
recorded. Generic emissions and arbitrary module selection are inherited
experimental surfaces to migrate in Phases 8 and 9, not new public contracts.
The abstract renderer dependency of the test harness is retained; concrete
renderer/runtime/framework dependencies remain forbidden in portable code.

## Reproduced verification

The [source-frozen log](../../../assets/bh-05-baseline/phase-01-gates-v0.1.0.json)
contains exact commands, versions, outputs, source maps and the historical
sub-log. All eleven gates passed with identical before/after/current source
hashes:

- 236 package/conformance tests, with package-local format checks;
- 31 JavaScript test files plus DOM driver checks;
- accepted BH-04 validation and deterministic generation in its exact checkout;
- the historical sweep at `d61e103b14595acca182611524eb4c7245906f20`, including
  438 tests and every validator/generator check;
- ten activation test groups covering authority, missing files, altered inputs,
  owners/deferrals, dependency leakage, callbacks/processes, dynamic dispatch,
  emissions, fake parity, all fourteen evidence classes and source drift;
- current activation validation and both deterministic generators; and
- archive, JSON and patch-hygiene checks.

The [completion record](../../../assets/bh-05-baseline/phase-01-completion-v0.1.0.json)
binds authority, entry, ownership, schema, empty index and execution evidence.
No passing runtime result is placed in the empty component evidence index.

## Current commands and historical separation

From the repository root:

```bash
python3 docs/research/70-tools/validate_bh05_activation.py --final
python3 -m unittest discover -s docs/research/70-tools -p test_validate_bh05_activation.py
python3 docs/research/70-tools/generate_bh05_activation.py --check
python3 docs/research/70-tools/generate_bh05_boundary.py --check
```

To repeat the full gate, prepare clean detached checkouts at the two revisions
above, provision the historical checkout's pinned ignored runtime artifacts
using the existing profile tooling, and use a fresh temporary output directory:

```bash
python3 docs/research/70-tools/record_bh05_phase1.py --predecessor <bh04-checkout> --historical <historical-checkout> --output <temporary-directory>
```

Do not rerun the sealed historical sweep against changed current files or
rehash its old records. Current activation proves that inherited implementation
and tooling bytes remain unchanged outside the explicitly activated manifests,
documentation and new governance tools. The exact predecessor validates its
own source closure separately.

## Limits and delivery

LiveView/LocalLiveView are [DEFERRED] by explicit scope decision. Physical
devices, unavailable platforms and manual assistive-technology qualification
remain owned BH-22 obligations, with no pass credit. BH-04 native-presentation
variance and its owned repeat obligation are copied unchanged. Phase 1 does
not imply a production Wasm component carrier or ERTS/AtomVM component parity.

The single PR and external merge/main-sync/branch-deletion actions follow this
pre-publication record. They are reported through the PR and final delivery
message rather than fabricated here before execution.
