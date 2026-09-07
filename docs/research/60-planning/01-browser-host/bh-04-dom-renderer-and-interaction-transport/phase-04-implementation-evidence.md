---
title: "BH-04 Phase 4 Implementation Evidence"
kind: note
created: "2026-09-07"
maturity: developing
tags:
  - bh-04
  - dom
  - implementation-evidence
aliases: []
---

# BH-04 Phase 4 Implementation Evidence

## Decision and scope

Phase 4 passes the atomic DOM application gate. Phase 5 is eligible but remains
unauthorized. BH-04 acceptance and BH-05 eligibility remain outstanding; the API
is experimental and browser support remains unsupported.

The [authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-04-authorization-v0.1.0.json)
binds accepted base `781e6c4ff870ad89ab803d84d488a2271c9e521c`, the Phase 3
reconciler and the unchanged BH-03 lifecycle. The [contract](phase-04-atomic-dom-contract.md)
defines settled atomicity and explicit quarantine. The [source index](../../../assets/bh-04-baseline/blazex-bh-04-phase-04-source-index-v0.1.0.json)
binds the additive implementation, fixtures, tests, governance, and raw browser
evidence. No historical implementation or evidence is silently rewritten.

## Implementation

`DOMRootQueues` composes real BH-03 handles with independent bounded FIFOs.
Schema/digest, owner, semantic generation, base/target revision, dependencies,
old values, topology, target ownership and resource limits are checked before
live mutation. Lifecycle generation is distinct from semantic generation.
Queues include the active transaction and never exceed 64; dependent revisions
are never coalesced. Overflow rejects the incoming request. Lifecycle changes
cancel work, and observers cannot confer commit authority or duplicate outcomes.

`AtomicDOMRoots` binds only empty, non-overlapping Element containers. The
applicator stages allocations detached, applies canonical operations, tracks
owned node identities, and restores bounded snapshots of the actual old DOM
on failure. Rollback preserves the original Elements. Failed restoration
quarantines one root, attempts one last-valid reconstruction, and otherwise
installs an empty inert fallback. There is no retry loop or sibling mutation.
Per-capability DOM ID prefixes and rewritten accessibility references keep
document-global ID resolution separate from stable semantic transaction IDs.

Buttons receive `type="button"`; only text inputs and applicable input/button
properties are admitted. Inert listeners are owned and released, existing
focus/selection intent is applied, and effect resources are rejected. Event
delivery, interaction normalization, user-value/focus continuity, effect
execution, LiveView integration and product controls remain outside Phase 4.

## Observed active evidence

The [raw browser results](../../../assets/bh-04-baseline/blazex-bh-04-phase-04-browser-results-v0.1.0.json)
record Linux Chrome `140.0.7339.80` and Playwright-compatible Firefox `153.0`.
Each browser passed:

- 50 actual Phase 3 reconciler scenarios, including real initial setup
  transactions, keyed moves, removals, root rematerialization, generation
  replacement, intent changes and disposal;
- 1,204 before/after operation failure boundaries, all restoring the prior
  projection and exact old Element identities;
- 100 seeded delayed prior-generation/revision transactions, all rejected
  without DOM mutation;
- a 64-request queue, incoming overflow rejection, no coalescing, and sibling
  progress while another root waits;
- property application/rollback, malformed digest, foreign owner/missing target,
  unsafe type, unknown capability, overlapping root and unexpected-DOM rejection;
- failed-rollback reconstruction and inert fallback, quarantined retries,
  healthy sibling progress, disposal/remount, runtime loss and shutdown; and
- 1,263 fixture cleanup cycles; every owned container and node index empties.

The exact same matrix passes in the strict fake DOM. Runtime build and all
26 JavaScript test files pass. The unchanged full-root DOM driver passes its
build and seven tests. All seven activated Elixir package suites pass (173
tests), as do 56 integration/conformance tests and exact fixture regeneration.

The [validation log](../../../assets/bh-04-baseline/blazex-bh-04-phase-04-validation-log-v0.1.0.txt)
records full research, schema, cross-language and boundary checks. The
[completion record](../../../assets/bh-04-baseline/blazex-bh-04-phase-04-completion-v0.1.0.json)
binds section provenance and all active gates.

## Failures repaired during development

Detached preparation originally rejected an existing ID that the transaction
first removed and then recreated; validated rematerialization now handles it.
Chrome exposed a reflected-property rollback ordering issue on buttons; restore
properties before restoring exact attributes, without redundant assignments.
These were real failures, corrected and rerun, not deferred qualifications.
Final integration tightened post-observer preflight, disposal effect rejection,
and property/type applicability. Distinct negative transaction IDs prevent
duplicate rejection from masking the intended negative checks.

## Limitations and retained obligations

Atomic means the synchronous settled outcome, not invisibility of intermediate
MutationObserver records. External uncontrolled DOM edits are rejected, not
merged or preserved. The bounded rollback journal contains DOM references
only for the owned root. Manual browser instrumentation or hostile same-realm
code can still tamper with the JavaScript environment; this is not a security
isolation boundary against arbitrary same-origin execution.

The harness uses controlled bridge acknowledgements with real BH-03 root
handles; this is DOM/lifecycle evidence, not new AtomVM/Wasm execution evidence.
No new dependency, public export, runtime contract, semantic kernel, native
widget adapter, or server framework was introduced. The existing full-root
renderer remains available. Review was by the implementing agent, not an
independent reviewer. Heap profiling and performance qualification were not run;
cleanup claims are deterministic owned-resource observations.

[DEFERRED] Unavailable OS/browser/device/manual-assistive-technology
qualification stays with the inherited browser, platform and accessibility
qualification owners and reactivates no later than BH-22. No deferred item is
counted as passed or supported; see the [development policy](../../development-environment-and-deferred-qualification-policy.md).

## Delivery

Sections 4.1, 4.2 and 4.3 have separate commits; Section 4.4 carries final
integration fixes and this evidence. One PR is requested, followed by merge,
main checkout and origin synchronization, then feature-branch deletion.
Unrelated user work is retained in an exact stash and restored after cleanup.
