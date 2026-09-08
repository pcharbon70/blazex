---
title: "BH-04 Phase 6 Implementation Evidence"
kind: note
created: "2026-09-08"
maturity: developing
tags:
  - bh-04
  - forms
  - focus
  - implementation-evidence
aliases: []
---

# BH-04 Phase 6 Implementation Evidence

## Decision and scope

Phase 6 passes its active Linux development gate. Phase 7 is eligible but
unauthorized, and BH-05 remains ineligible. The owner explicitly approved the
internal form/selection prerequisite after inspection showed the previous
model lacked controlled field values and a declared option-value universe.
This is additive experimental framework work, not a public form component API.

Section 6.1 defines `FormState`/`FormOutput` version 1 and freezes the
[continuity contract](phase-06-continuity-contract.md). Section 6.2 adds bounded
draft/composition handling and jointly acknowledged controlled rendering.
Section 6.3 restores owned focus and ranges by identity. Section 6.4 integrates
the browser/runtime suite and publishes source-bound evidence. Each section
has its own commit; one PR is merged before main synchronization and feature
branch deletion. The completion record references its introducing fourth
commit without claiming a self-referential hash. Unrelated README, BH-05 and
demo work is preserved outside the PR.

## Browser-observable results

Chrome and Firefox each pass the same 16 scenarios across two isolated roots:
typed input through real Elixir, stable keyed moves, zero redundant value
writes, explicit/clamped backward selection, overlapping edits, composition,
keyboard activation and submit, checkbox/mixed/required/invalid state, stable
single/multiple choices, focus authority and hidden ancestors, removal,
replacement and disabled targets, malformed/stale manifests, file exclusion,
rollback and complete cleanup. Choice selection uses owned checkbox properties
and aria-selected, not indexes or a newly introduced select/option backend.

Both independent replays agree on 66 proposed envelopes, 64 committed renders
and 22 semantic deliveries. Two injected rollback proposals remain provisional
and are discarded when their roots stop. Other accepted runtime state is not
promoted until the matching envelope digest and inner render acknowledgement
both agree. Raw traces include inputs, results, browser fingerprints and cleanup.
Local interaction traffic uses no HTTP, Phoenix or Plug command path.

The original Phase 4 browser matrix also passes unchanged in both browsers:
50 scenarios, 1204 rollback boundaries, 100 stale rejections and 1263 cleanups
per browser. The original Phase 5 matrix likewise passes all 13 mappings,
three roots and its queue/isolation/cleanup cases. Their historical artifacts
are not rewritten; current-run regression outputs are kept separate.

## Review findings and repairs

Integration found that an ended composition draft retained an older submitted
sequence, allowing an unrelated render to treat it as already acknowledged.
Composition now marks the draft unsubmitted until a genuine non-composing
input event supplies a sequence. Tests cover a conflicting render both during
composition and after compositionend, plus blur and runtime-loss cleanup.

Managed-value verification now checks the captured intended/draft values,
not a fresh read of possibly corrupted DOM. Readonly choices cancel native
toggles before semantic delivery. Oversize native text is not retained or
transported and rejects rendering without truncation. Future edit
acknowledgements, malformed compound acknowledgements, legacy endpoint requests
and unknown selected values reject. Some early fixture assertions failed
because a deliberate value override was still active; the fixture now clears
that override at the intended scenario boundary. No active failure was waived.

Review is implementation-agent review, not independent review. The new source
inventory is explicit; existing semantic kernels, v1/v2 transaction schemas,
renderer lowering, dependencies and profile manifests remain unchanged.
The new form output is intentionally rejected by legacy consumers. Native and
other backends need an explicit adapter before they can claim this capability.

## Runtime and qualification limits

The browser harness executes real Elixir 1.17.3 / OTP 26 in offline Docker over
a test-only Playwright DevTools/stdio carrier. It does not package the new
`blazex.host-bridge/3` endpoint into AtomVM/Wasm or upgrade the existing demo.
The compound `blazex.dom-continuity/1` envelope leaves v2 render transactions
unchanged and requires explicit continuity attachment. Old paths do not gain
support by accepting data they do not understand.

No product forms, validation engine, rich controls, uploads, file metadata,
styling, post-commit effects, performance, heap or public API qualification is
claimed. Keyboard/pointer events are browser automation; composition events
are programmatic, not physical IME testing. [DEFERRED] Physical IME, manual
assistive-technology pairings and unavailable OS/device/browser work remain
with platform/device/accessibility qualification owners, reactivating by BH-22
under the [development policy](../../development-environment-and-deferred-qualification-policy.md).
No deferred item receives pass credit; all browsers remain unsupported.

## Reproduction

- [Usage and explicit opt-in](../../../../../integration/bh-04/continuity-usage.md)
- [Authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-06-authorization-v0.1.0.json)
- [Source bindings](../../../assets/bh-04-baseline/blazex-bh-04-phase-06-source-index-v0.1.0.json)
- [Raw browser/runtime traces](../../../assets/bh-04-baseline/blazex-bh-04-phase-06-browser-results-v0.1.0.json)
- [Commands, counts and limitations](../../../assets/bh-04-baseline/blazex-bh-04-phase-06-validation-log-v0.1.0.txt)
- [Completion record](../../../assets/bh-04-baseline/blazex-bh-04-phase-06-completion-v0.1.0.json)
