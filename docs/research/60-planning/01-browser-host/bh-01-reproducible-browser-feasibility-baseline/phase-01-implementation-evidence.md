---
title: "BH-01 Phase 1 Authorization, Governance, and Activation Evidence"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - bh-01
  - evidence-governance
  - implementation-evidence
  - repository-activation
aliases:
  - "BH-01 phase 1 evidence"
---

# BH-01 Phase 1 Authorization, Governance, and Activation Evidence

## Decision

BH-01 Phase 1 is complete with a `go` result for its authorization,
evidence-governance, and repository-activation gate. This result establishes
only that the approved experimental slice is controlled, independently
testable, and ready for later dependency qualification. It does not establish
that Popcorn, AtomVM, Phoenix, LiveView, LocalLiveView, a browser runtime, a DOM
renderer, or a BlazeX component works.

Phase 2 is **eligible but not authorized**. Dependency acquisition and
qualification require a separate repository-owner implementation request.

Machine-readable completion metadata is retained in the [Phase 1 completion
record](../../../assets/bh-01-baseline/blazex-bh-01-phase-01-completion-v0.1.0.json),
and command output is retained in the [Phase 1 validation
log](../../../assets/bh-01-baseline/blazex-bh-01-phase-01-validation-log-v0.1.0.txt).

## Section 1.1 — Authority and inherited contract truth

### Delivered artifacts

- [Authorization `BX-BH01-AUTHORIZATION-0.1`](../../../assets/bh-01-baseline/blazex-bh-01-authorization-v0.1.0.json)
  binds repository-owner approval, approved plan revision `d70a965`, synchronized
  activation base `cb100be`, the dedicated feature branch, four authorized
  Phase 1 outcomes, five binding conditions, and explicit non-authorizations.
- [Milestone ledger `BX-BH01-MILESTONE-LEDGER-0.1`](../../../assets/bh-01-baseline/blazex-bh-01-milestone-ledger-v0.1.0.json)
  imports all eight inputs, ten proof obligations, eight risks, five stop
  conditions, two prohibited actions, thirteen owner assignments, and every
  proof-level acceptance/budget link.
- The validator verifies the approved plan blob at its immutable Git revision,
  the BH-00 baseline and entry identities, source manifest, zero exceptions,
  three inherited artifact hashes, all seventeen BH-00 source bindings, and
  baseline ancestry.

### Result

All imported records reconcile with the accepted BH-00 governance source.
Inputs remain `required-unproven`, proofs remain `planned-unexecuted`, risks
remain open, browsers remain unsupported, and budgets remain unmeasured.
Section revision: `74f0317`.

## Section 1.2 — Evidence, finding, and stop/go governance

### Delivered artifacts

- The [evidence record schema](../../../assets/bh-01-baseline/blazex-bh-01-evidence-record.schema.json)
  defines twelve record types, stable ID namespaces, ten non-collapsing states,
  common provenance, hashes, raw evidence, normalization, limitations,
  supersession/invalidation, retention, outcome, and review fields.
- The [evidence governance contract](../../../assets/bh-01-baseline/blazex-bh-01-evidence-governance-v0.1.0.json)
  and [schema](../../../assets/bh-01-baseline/blazex-bh-01-governance.schema.json)
  assign the eight required finding domains, escalation and stop authorities,
  five severities, blocker behavior, invalidation, bounded mitigation, and
  seven changes that require explicit reapproval.
- Schema probes validate every record type. Observed/pass/fail/blocked evidence
  cannot omit timestamps, hashes, raw evidence, or normalization.

### Result

Critical findings and triggered stop conditions halt downstream work. High
findings require accepted bounded mitigation. Governance prohibits silently
weakening thresholds, omitting scenarios, turning plans into passes, deleting
negative evidence, or continuing past unresolved blockers. Section revision:
`3bf983c`.

## Section 1.3 — Minimal repository activation

### Activated boundaries

| Boundary | Kind | Phase 1 owner | Actual dependencies |
| --- | --- | --- | --- |
| `packages/blazex_runtime_popcorn` | Experimental Mix package | `runtime-owner` | None |
| `packages/blazex_host_browser` | Experimental Mix package | `browser-host-owner` | None |
| `packages/blazex_renderer_dom` | Experimental Mix package | `dom-renderer-owner` | None |
| `packages/blazex_renderer_dom_liveview` | Experimental Mix package | `liveview-adapter-owner` | None |
| `packages/blazex_phoenix` | Experimental Mix package | `server-adapter-owner` | None |
| `js/blazex_runtime` | Private experimental JavaScript package | `browser-host-owner` | None |
| `profiles/browser_phoenix` | Experimental Mix profile | `browser-profile-owner` | None |
| `integration/fixtures` | Scenario/evidence location | `quality-owner` | None |
| `integration/benchmarks` | Environment/sample/report location | `quality-owner` | None |

The [repository activation manifest](../../../assets/bh-01-baseline/blazex-bh-01-repository-activation-v0.1.0.json)
and [schema](../../../assets/bh-01-baseline/blazex-bh-01-repository-activation.schema.json)
fix this exact inventory, ownership, allowed planned edges, forbidden edges,
inactive paths, API states, and review requirements for a boundary change.

### Isolation results

- Every Mix project has a local manifest, formatter, module root, ownership
  metadata, and passing test entry point.
- The JavaScript bridge pins `npm@11.4.2`, has build/test entry points, and has
  no dependency, lockfile, loader implementation, arbitrary script escape,
  generic DOM ownership, component logic, or server authority.
- The browser/Phoenix profile reserves composition, endpoint, asset,
  development, test, runtime/release, and teardown locations without installing
  Phoenix or another candidate.
- Fixture and benchmark indexes are empty; no scenario, environment, sample,
  report, runtime result, browser result, or budget result exists.
- `blazex_core`, `blazex_effects`, `blazex_ui_tree`, `blazex_renderer`,
  `blazex_renderer_headless`, Plug/headless profiles, and the native experiment
  remain unactivated.

Section revision: `fa56f34`.

## Section 1.4 — Integration and completion evidence

### Reproducible verification

| Check | Command or method | Result |
| --- | --- | --- |
| BH-01 governance and activation | `python3 validate_bh01_activation.py` | Passed: authorization, 17 inherited bindings, 8 inputs, 10 proofs, 8 risks, 5 stops, 12 evidence types, 8 authority domains, and 9 boundaries. |
| Fail-closed behavior | `python3 -m unittest test_validate_bh01_activation.py` | Passed: 12 tests including all six required negative activation cases. |
| Activated Mix projects | `mix test` in five packages and one profile | Passed: 6 tests, 0 failures; no external dependency resolution. |
| Activated Mix formatting | `mix format --check-formatted` in all six projects | Passed. |
| JavaScript boundary | `npm test` and `npm run build` in `js/blazex_runtime` | Passed: 1 test, syntax-only build; no install or lockfile. |
| BH-00 governance freshness | Governance validator/tests and `generate_bh00_release.py --check` | Passed; inherited baseline and generated views remain current. |
| Archive structure | Archive validator and focused archive tests | Passed; indexes, links, metadata, and source records remain valid. |
| Repository and patch hygiene | Exact inventory, graph, forbidden-token, inactive-boundary, fixture-import, no-lock, status, and `git diff --check` checks | Passed. |

### Required negative cases

| Case | Expected fail-closed result |
| --- | --- |
| Missing approval | Reject before repository activation. |
| Stale synchronized-main revision | Reject because the recorded base commit is unavailable or not an ancestor. |
| Stale BH-00 source | Reject the changed bound-source SHA-256. |
| Incomplete milestone ledger | Reject any count or identity other than 8 inputs, 10 proofs, 8 risks, and 5 stops. |
| Unowned blocker | Reject when any input, proof, risk, stop, or escalation role lacks an assigned identity. |
| Unreviewed governed plan change | Reject a missing reapproval trigger or unversioned activation change. |

Every negative case leaves all active boundaries without `mix.lock`,
`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `deps`, or `node_modules`.

### Tool and execution environment

- Python `3.12.12`; `jsonschema` `4.25.1`.
- Git `2.49.0`.
- Erlang/OTP `27` / ERTS `15.2.3`; Elixir and Mix `1.18.4`.
- Node.js `24.3.0`; npm `11.4.2`.
- Linux `6.8.0-51-generic` on `x86_64`.
- Executed in the dedicated Phase 1 branch on 2026-09-03.

These tool versions describe the Phase 1 validation environment only. They are
not the qualified or pinned BH-01 runtime toolchain; that is Phase 2 work.

### Findings and stop/go result

The fail-closed validator identified one attempted edit to the hash-bound BH-00
repository-root source during Section 1.3. The edit was removed, the original
SHA-256 `a8458564c9dd2642b2ade6c288d85ceeb1d4518f6dcbe3e01a9964a41621cbaa`
was restored, and no inherited baseline was rewritten. No open blocker or
accepted exception remains from Phase 1.

No BH-01 stop condition is triggered by repository activation. The phase gate
is `go`, limited to eligibility for Phase 2 planning execution. Phase 2 remains
`not-authorized`, and all empirical proof obligations remain unexecuted.

### Delivery record

- Section 1.1 revision: `74f0317`.
- Section 1.2 revision: `3bf983c`.
- Section 1.3 revision: `fa56f34`.
- Section 1.4 is the final coherent commit in the single Phase 1 PR.
- The repository owner authorized immediate PR merge, synchronization of
  `main`, and deletion of the local and remote feature branch.

## Limitations carried into Phase 2

- No candidate dependency identity, source, license, revision, private API, or
  transitive graph has been qualified.
- No Wasm runtime, BEAM bundle, browser loader, Phoenix endpoint, LiveView
  adapter, DOM mutation, authenticated command, or fallback has executed.
- No browser, operating system, mobile device, accessibility technology,
  deployment, payload, startup, interaction, memory, reliability, or cleanup
  evidence exists.
- The new module roots and JavaScript probe are experimental ownership markers,
  not reusable framework contracts or component APIs.

## Connections

- [Phase 1 plan](phase-01-authorization-evidence-and-repository-activation.md)
- [BH-01 plan](README.md)
- [BH-00 baseline](../../../assets/bh-00-release/blazex-bh-00-release-index-v0-1-0.md)
- [BH-01 entry manifest](../../../assets/bh-00-release/blazex-bh-01-entry-manifest-v0-1-0.md)

## Sources

- [BH-01 authorization](../../../assets/bh-01-baseline/blazex-bh-01-authorization-v0.1.0.json)
- [Milestone ledger](../../../assets/bh-01-baseline/blazex-bh-01-milestone-ledger-v0.1.0.json)
- [Evidence governance](../../../assets/bh-01-baseline/blazex-bh-01-evidence-governance-v0.1.0.json)
- [Repository activation](../../../assets/bh-01-baseline/blazex-bh-01-repository-activation-v0.1.0.json)
