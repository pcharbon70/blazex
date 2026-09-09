---
title: "Research Tooling"
kind: map
created: "2026-09-08"
tags:
  - archive-navigation
  - directory-index
  - research-tooling
  - validation
aliases:
  - "Research Python tools"
---

# Research Tooling (`70-tools`)

## Purpose

Keep the research corpus readable by collecting its Python validators,
generators, shared helpers, and tests in one dedicated directory. The 82
original programs were moved here from the research root; this directory also
contains the root-path helper, explicit migration bridge, regression tests,
migration validator, and all-checks runner added for that move.

This is maintenance tooling, not an Elixir runtime dependency or a new product
milestone. Document schemas and immutable evidence remain in their existing
locations. See the [research index](../README.md) and [maintenance instructions](../AGENTS.md).

## What belongs here

- Corpus validation, deterministic generators, source-binding readers, and tests.
- Shared path discovery and narrowly scoped historical replay helpers.
- Tooling migration records and current execution instructions.

Keep runtime/profile build programs with their owning packages or integration
suites. Do not move evidence into this directory or duplicate historical scripts
at the research root as forwarding stubs.

## Running the tools

The BH-04 corrective successor uses `validate_bh04_correction.py` for current
acceptance. The sealed `check_all.py`/Phase 10 sweep must run at its frozen
`d61e103b14595acca182611524eb4c7245906f20` baseline with the pinned ignored runtime
artifacts present. It intentionally cannot treat corrected runtime bytes as
the old accepted snapshot. Current executable integration is reproduced with
`node integration/bh-04/corrective-gates.mjs <temporary-directory>`; native
captures and source closure are checked separately by the successor validator.

From the repository root:

```bash
python3 -m pip install -r docs/research/requirements-validation.txt
python3 docs/research/70-tools/check_all.py --report /tmp/blazex-research-checks.json
python3 docs/research/70-tools/validate_archive.py
python3 -m unittest discover -s docs/research/70-tools -p 'test_*.py'
python3 docs/research/70-tools/generate_component_catalog.py --check
```

From the research root, use `python3 70-tools/<script>.py`; from this directory,
use `python3 <script>.py` or `python3 -m unittest test_validate_archive.py`.
Absolute script paths also work from an unrelated working directory. Imports
stay local to this directory, while `research_paths.py` locates corpus data
independently of the caller's working directory.

`check_all.py` parses every Python file, discovers every `test_*.py`, runs every
`validate_*.py`, and checks every `generate_*.py` with `--check`. It retains
failures/timeouts and returns nonzero if any command fails. It does not run
unbounded benchmark recorders or overwrite accepted milestone evidence.

Prerequisites are the pinned Python packages, Node and Git for inherited
conformance/replay checks, complete local Git history for the pinned snapshots,
and the existing ignored BH-01 runtime artifacts. A fresh worktree must restore
or rebuild the manifest-matching `AtomVM.mjs`, `AtomVM.wasm`, and `bundle.avm`
under the browser Phoenix profile before BH-03 compatibility/startup checks can
pass. Missing artifacts are errors, not fabricated validation credit.

## Migration and historical evidence

The user authorized the move to `70-tools` on 2026-09-08. The migration starts
from Git revision `f6f338265675e14628bc221e581df51aef4d477b` and changes tooling
layout, root discovery, invocation, and navigation only. It neither resolves
BH-04's outstanding findings nor authorizes BH-05 implementation.

`migration-v1.json` inventories every original Python source with its old path
and digest, relocated path and digest, plus the four updated external callers
and additional tooling. `tooling_migration.py` seals that record. A legacy source
binding is satisfied only by verifying both the original Git blob and the exact
relocated source. Unlisted source changes, missing tools, modified callers,
legacy shadow files, traversal, and altered migration records fail closed.
Current validators still inspect current non-tool implementation and evidence;
the bridge is not a wholesale switch to validating an old checkout.

Historical replay commands inside `bh03_history.py`, `bh04_*history.py`, and
superseded validators deliberately retain `docs/research/<script>.py`, because
they run against Git snapshots that predate this migration. Historical gate-log
inventories also retain their original names. The current `check_all.py` sweep
includes the new migration checks separately. Historical narrative command
blocks remain a record of what ran; use this guide for current invocations.

Keep accepted source indexes, gate logs, asset hashes, and completion records
unchanged. Later edits to sealed tools need a reviewed successor migration or
superseding evidence; do not silently update historical hashes, weaken the
binding checks, or count expected `--require-accepted` rejection as a pass for
milestone acceptance.

## Index

- [BH-05 activation record generator](generate_bh05_activation.py)
- [BH-05 boundary record generator](generate_bh05_boundary.py)
- [BH-05 activation validator](validate_bh05_activation.py)
- [BH-05 negative activation tests](test_validate_bh05_activation.py)
- [BH-05 source-frozen Phase 1 gate recorder](record_bh05_phase1.py)

- [BH-04 corrective acceptance validator](validate_bh04_correction.py)
- [BH-04 corrective decision generator](generate_bh04_correction.py)
- [BH-04 corrective gate tests](test_validate_bh04_correction.py)

### Migration verification — 2026-09-08

The complete `check_all.py` sweep passed after relocation: 438 unittest cases,
34 validators, and all four generator `--check` commands. All 87 Python files
parsed, the four updated caller references/syntax were checked, and archive
validation passed for 252 documents, 28 directories, and 2011 local links.
Patch hygiene passed; historical assets and planning records were unchanged.

The isolated worktree initially lacked the ignored BH-01 runtime binaries;
the existing manifest-matching artifacts were restored before final checks.
Read-only Node-to-Git subprocess checks required permission outside the sandbox.
Neither issue was suppressed or counted as a passing run. The separate BH-04
`--require-accepted` probe still exited 1 for its existing paint-evidence and
independent-review blockers, as intended.

### Subdirectories

- None.

### Documents

- [Sealed migration inventory](migration-v1.json) — original/new source bindings and updated callers.

### Validators

- [`validate_archive.py`](validate_archive.py) — Validate the BlazeX Research archive's structural invariants.
- [`validate_bh00_governance.py`](validate_bh00_governance.py) — Validate the source-bound BlazeX BH-00 governance and release contract.
- [`validate_bh01_activation.py`](validate_bh01_activation.py) — Validate BH-01 authorization, inherited truth, governance, and activation.
- [`validate_bh02_acceptance.py`](validate_bh02_acceptance.py) — Fail-closed validation for the BH-02 Phase 8 acceptance candidate.
- [`validate_bh02_activation.py`](validate_bh02_activation.py) — Validate BH-02 Phase 1 authorization, handoff, activation, and leakage.
- [`validate_bh02_dom.py`](validate_bh02_dom.py) — Validate BH-02 Phase 6 standalone DOM and browser evidence.
- [`validate_bh02_effects.py`](validate_bh02_effects.py) — Validate BH-02 Phase 3 semantic-event, effect, and resource contracts.
- [`validate_bh02_intent.py`](validate_bh02_intent.py) — Validate BH-02 Phase 4 portable presentation-intent contracts.
- [`validate_bh02_native.py`](validate_bh02_native.py) — Fail-closed validation for the BH-02 Phase 7 direct native-control spike.
- [`validate_bh02_renderer.py`](validate_bh02_renderer.py) — Validate BH-02 Phase 5 renderer lifecycle and headless-oracle evidence.
- [`validate_bh02_semantics.py`](validate_bh02_semantics.py) — Validate BH-02 Phase 2 semantic nodes, identity, and component evaluation.
- [`validate_bh03_acceptance.py`](validate_bh03_acceptance.py) — Validate the BH-03 review record; valid records need not accept the milestone.
- [`validate_bh03_activation.py`](validate_bh03_activation.py) — Validate BH-03 Phase 1 authorization, handoff, contracts, and activation.
- [`validate_bh03_compatibility.py`](validate_bh03_compatibility.py) — Validate BH-03 Phase 2 compatibility and pre-acquisition behavior.
- [`validate_bh03_correction.py`](validate_bh03_correction.py) — Validate current BH-03 Phase 9 correction and superseding acceptance.
- [`validate_bh03_measurements.py`](validate_bh03_measurements.py) — Validate BH-03 Phase 7 resource, reliability, and startup measurements.
- [`validate_bh03_profile.py`](validate_bh03_profile.py) — Validate BH-03 Phase 6 browser-profile and active-matrix conformance.
- [`validate_bh03_resilience.py`](validate_bh03_resilience.py) — Validate BH-03 Phase 5 shutdown, recovery, and fallback behavior.
- [`validate_bh03_roots.py`](validate_bh03_roots.py) — Validate BH-03 Phase 4 shared-runtime and independent-root behavior.
- [`validate_bh03_startup.py`](validate_bh03_startup.py) — Validate BH-03 Phase 3 artifact acquisition and isolated startup behavior.
- [`validate_bh04_acceptance.py`](validate_bh04_acceptance.py) — Validate the Phase 10 evidence candidate; --require-accepted gates downstream work.
- [`validate_bh04_activation.py`](validate_bh04_activation.py) — Fail-closed BH-04 Phase 1 activation gate; stdlib only.
- [`validate_bh04_conformance.py`](validate_bh04_conformance.py) — Phase 9 exact-source, raw-evidence and active/deferred conformance gate.
- [`validate_bh04_continuity.py`](validate_bh04_continuity.py) — Phase 6 current-source, immutable-history and active browser evidence gate.
- [`validate_bh04_dom_application.py`](validate_bh04_dom_application.py) — Phase 4 current-source, immutable-history and active browser evidence gate.
- [`validate_bh04_interactions.py`](validate_bh04_interactions.py) — Phase 5 current-source, immutable-history and active browser evidence gate.
- [`validate_bh04_lifecycle.py`](validate_bh04_lifecycle.py) — Current Phase 7 source binding, active evidence and independent replay gate.
- [`validate_bh04_protocol.py`](validate_bh04_protocol.py) — Validate current BH-04 Phase 2 scope, provenance and protocol evidence.
- [`validate_bh04_reconciliation.py`](validate_bh04_reconciliation.py) — Current Phase 3 gate; predecessor gates reproduce immutable Git snapshots.
- [`validate_browser_product_envelope.py`](validate_browser_product_envelope.py) — Validate the machine-readable BH-00 browser product envelope.
- [`validate_component_catalog.py`](validate_component_catalog.py) — Validate the pinned component-catalog reference and generated artifacts.
- [`validate_component_classification.py`](validate_component_classification.py) — Validate the versioned BlazeX component product classification.
- [`validate_quality_acceptance.py`](validate_quality_acceptance.py) — Validate BlazeX BH-00 quality budgets and acceptance traceability.
- [`validate_tooling_migration.py`](validate_tooling_migration.py) — Check relocation provenance without promoting historical acceptance.

### Generators

- [`generate_acceptance_registry.py`](generate_acceptance_registry.py) — Generate the deterministic BlazeX BH-00 acceptance registry and report.
- [`generate_bh00_release.py`](generate_bh00_release.py) — Generate the navigable BlazeX BH-00 baseline and BH-01 entry manifest.
- [`generate_component_catalog.py`](generate_component_catalog.py) — Generate the deterministic human view of the canonical component catalog.
- [`generate_component_classification.py`](generate_component_classification.py) — Generate the deterministic joined view of the BlazeX component classification.

### Shared helpers and runners

- [`bh03_history.py`](bh03_history.py) — Narrow Phase 9 historical-source binding; never validates current implementation.
- [`bh04_history.py`](bh04_history.py) — Explicit Phase 2 supersession: reproduce immutable Phase 1 on accepted Git.
- [`bh04_phase10_history.py`](bh04_phase10_history.py) — Phase 10 reproduces the immutable Phase 9 gate on its accepted merge.
- [`bh04_phase3_history.py`](bh04_phase3_history.py) — Explicit Phase 3 supersession: reproduce immutable Phase 2 on accepted Git.
- [`bh04_phase4_history.py`](bh04_phase4_history.py) — Explicit Phase 4 supersession: reproduce immutable Phase 3 on accepted Git.
- [`bh04_phase5_history.py`](bh04_phase5_history.py) — Explicit Phase 5 supersession: reproduce immutable Phase 4 on accepted Git.
- [`bh04_phase6_history.py`](bh04_phase6_history.py) — Explicit Phase 6 supersession: reproduce immutable Phase 5 on accepted Git.
- [`bh04_phase7_history.py`](bh04_phase7_history.py) — Explicit Phase 7 supersession: reproduce immutable Phase 6 on accepted Git.
- [`bh04_phase9_history.py`](bh04_phase9_history.py) — Explicit Phase 9 supersession: reproduce immutable Phase 7 on accepted Git.
- [`check_all.py`](check_all.py) — Run every research test, validator, and generator check without recording acceptance.
- [`planning_policy.py`](planning_policy.py) — Shared validation helpers for bounded research-planning amendments.
- [`research_paths.py`](research_paths.py) — Stable repository paths for research tools, independent of the caller's cwd.
- [`tooling_migration.py`](tooling_migration.py) — Explicit relocation bridge for immutable, pre-70-tools source bindings.

### Tests

- [`test_bh03_history.py`](test_bh03_history.py) — Regression tests.
- [`test_planning_policy.py`](test_planning_policy.py) — Regression checks for exact, prospective planning amendments.
- [`test_tooling_migration.py`](test_tooling_migration.py) — Regression and negative tests for the explicit tooling relocation.
- [`test_validate_archive.py`](test_validate_archive.py) — Focused tests for BlazeX Research archive validation.
- [`test_validate_bh00_governance.py`](test_validate_bh00_governance.py) — Tests for the BlazeX BH-00 governance validator.
- [`test_validate_bh01_activation.py`](test_validate_bh01_activation.py) — Focused fail-closed tests for BH-01 Phase 1 activation governance.
- [`test_validate_bh02_acceptance.py`](test_validate_bh02_acceptance.py) — Regression tests.
- [`test_validate_bh02_activation.py`](test_validate_bh02_activation.py) — Regression tests.
- [`test_validate_bh02_dom.py`](test_validate_bh02_dom.py) — Regression tests.
- [`test_validate_bh02_effects.py`](test_validate_bh02_effects.py) — Regression tests.
- [`test_validate_bh02_intent.py`](test_validate_bh02_intent.py) — Regression tests.
- [`test_validate_bh02_native.py`](test_validate_bh02_native.py) — Focused fail-closed tests for BH-02 Phase 7 native evidence.
- [`test_validate_bh02_renderer.py`](test_validate_bh02_renderer.py) — Regression tests.
- [`test_validate_bh02_semantics.py`](test_validate_bh02_semantics.py) — Regression tests.
- [`test_validate_bh03_acceptance.py`](test_validate_bh03_acceptance.py) — Regression tests.
- [`test_validate_bh03_activation.py`](test_validate_bh03_activation.py) — Regression tests.
- [`test_validate_bh03_compatibility.py`](test_validate_bh03_compatibility.py) — Regression tests.
- [`test_validate_bh03_correction.py`](test_validate_bh03_correction.py) — Regression tests.
- [`test_validate_bh03_measurements.py`](test_validate_bh03_measurements.py) — Regression tests.
- [`test_validate_bh03_profile.py`](test_validate_bh03_profile.py) — Regression tests.
- [`test_validate_bh03_resilience.py`](test_validate_bh03_resilience.py) — Regression tests.
- [`test_validate_bh03_roots.py`](test_validate_bh03_roots.py) — Regression tests.
- [`test_validate_bh03_startup.py`](test_validate_bh03_startup.py) — Regression tests.
- [`test_validate_bh04_acceptance.py`](test_validate_bh04_acceptance.py) — Regression tests.
- [`test_validate_bh04_activation.py`](test_validate_bh04_activation.py) — Mutation tests for the immutable BH-04 Phase 1 activation candidate.
- [`test_validate_bh04_conformance.py`](test_validate_bh04_conformance.py) — Regression tests.
- [`test_validate_bh04_continuity.py`](test_validate_bh04_continuity.py) — Negative Phase 6 governance tests; never modify the user's source tree.
- [`test_validate_bh04_dom_application.py`](test_validate_bh04_dom_application.py) — Negative Phase 4 governance tests; never modify the user's source tree.
- [`test_validate_bh04_interactions.py`](test_validate_bh04_interactions.py) — Negative Phase 5 governance tests; never modify the user's source tree.
- [`test_validate_bh04_lifecycle.py`](test_validate_bh04_lifecycle.py) — Negative evidence checks for the current effect and lifecycle gate.
- [`test_validate_bh04_protocol.py`](test_validate_bh04_protocol.py) — Negative governance checks, isolated from user source.
- [`test_validate_bh04_reconciliation.py`](test_validate_bh04_reconciliation.py) — Negative governance checks, isolated from user source.
- [`test_validate_browser_product_envelope.py`](test_validate_browser_product_envelope.py) — Focused tests for the BH-00 browser product envelope validator.
- [`test_validate_component_catalog.py`](test_validate_component_catalog.py) — Focused tests for the component-catalog validator.
- [`test_validate_component_classification.py`](test_validate_component_classification.py) — Focused tests for the Phase 4 component-classification validator.
- [`test_validate_quality_acceptance.py`](test_validate_quality_acceptance.py) — Tests for the BlazeX quality and acceptance validator.

## Maintaining this index

- [`generate_bh05_nested.py`](generate_bh05_nested.py) — Phase 5 authority, state/event/semantic bindings and bounded planner successor.
- [`validate_bh05_nested.py`](validate_bh05_nested.py) — Nested state inventory, ownership and source-frozen completion checks.
- [`test_validate_bh05_nested.py`](test_validate_bh05_nested.py) — Isolated negative authority, boundary, fixture and gate tests.
- [`record_bh05_phase5.py`](record_bh05_phase5.py) — Current nested-state and frozen historical gate recording/publication.

- [`generate_bh05_composition.py`](generate_bh05_composition.py) — Phase 4 authority and semantic input bindings.
- [`validate_bh05_composition.py`](validate_bh05_composition.py) — Phase 4 immutable predecessor, ownership, fixture and source-frozen evidence checks.
- [`test_validate_bh05_composition.py`](test_validate_bh05_composition.py) — Isolated composition evidence mutation tests.
- [`record_bh05_phase4.py`](record_bh05_phase4.py) — Complete current and frozen historical gate recording and publication.

- [`generate_bh05_schema.py`](generate_bh05_schema.py) — Phase 3 authority and accepted facade bindings.
- [`check_bh05_schema_subset.py`](check_bh05_schema_subset.py) — Pinned schema compiler/analyzer roundtrip, preserving the Phase 2 runner unchanged.
- [`validate_bh05_schema.py`](validate_bh05_schema.py) — Schema inventory, immutable predecessor and source-frozen gate checks.
- [`test_validate_bh05_schema.py`](test_validate_bh05_schema.py) — Isolated schema evidence mutation tests.
- [`record_bh05_phase3.py`](record_bh05_phase3.py) — Full current and historical schema gate recording and publication.

- [`generate_bh05_authoring.py`](generate_bh05_authoring.py) — Phase 2 authority bound to accepted Phase 1.
- [`check_bh05_subset.py`](check_bh05_subset.py) — SHA-pinned Popcorn authoring compiler/analyzer subset check (not execution parity).
- [`validate_bh05_authoring.py`](validate_bh05_authoring.py) — Phase 2 immutable predecessors, facade inventory and source-bound completion.
- [`test_validate_bh05_authoring.py`](test_validate_bh05_authoring.py) — Isolated authority, dependency, fixture and gate mutation checks.
- [`record_bh05_phase2.py`](record_bh05_phase2.py) — Current and frozen-predecessor gate recording; refuses stale or failed publication.

Index every direct child, update callers and current commands together, and use
shared root discovery for new programs. Preserve the distinction between
historical evidence and current checks. Run the full tooling sweep, verify
migration negative tests and archive links, and inspect patch hygiene before
reporting a tooling change complete.
