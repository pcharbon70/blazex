---
title: "BH-04 Phase 6 Continuity Contract"
kind: note
created: "2026-09-08"
maturity: developing
tags:
  - bh-04
  - forms
  - focus
aliases: []
---

# BH-04 Phase 6 Continuity Contract

Back to the [BH-04 plan](README.md) and [Phase 6 checklist](phase-06-form-value-focus-and-selection-continuity.md).

## Authority and prerequisite

The owner authorized Phase 6 and explicitly approved a versioned internal
form/selection prerequisite. Base is `c11a0618b66f46b868739c9958f6d9b45249afbf`;
branch is `codex/bh04-phase6-continuity`. Sections 6.1–6.4 each receive one
verified commit, then one PR, merge, main/origin synchronization and feature
branch deletion. Unrelated work stays outside that PR and is restored exactly.

`FormState` version 1 declares an owner, text/check/single/multiple kind,
controlled value, explicit choices, edit acknowledgement sequence, disabled,
readonly, required, invalid and indeterminate flags. Choices bind nonempty
binary values (128 UTF-8 bytes) to distinct descendant selection identities.
At most 32 forms/choices are accepted; text is at most 2048 bytes. Duplicate,
missing or removed selected values reject before component-state publication.
`FormOutput` version 1 wraps an unchanged `IntentSet`; legacy consumers reject
the new wrapper instead of silently dropping its controlled state.

The renderer uses an additive `blazex.dom-continuity/1` envelope containing an
unchanged v2 render transaction and the complete closed control manifest. Its
digest binds both halves; a base-control digest prevents stale manifest replay.
Acknowledgement binds the envelope digest and the ordinary v2 DOM acknowledgement.
Only explicitly attached continuity roots accept this envelope. No silent
reinterpretation of existing v1/v2 protocols, fixture.event, or Wasm profile.

## Values and composition

Value, checked and selected state are properties, not attribute snapshots.
Required/readonly/disabled map to native properties where applicable; invalid
maps to accessibility intent, never a fabricated validation result. Mixed
check state maps to indeterminate. Options use stable identities, not indexes.
Unchanged values are never redundantly assigned. A native edit newer than the
semantic edit acknowledgement is retained; a matching/newer acknowledgement
may accept or replace it. Rejected stale input is not automatically replayed.

Composition start/update/end is browser-local. Composing input does not emit a
semantic change; only an actual non-composing input does. Compatible rendering
retains the composing draft and defers conflicting semantic text. End/blur
clears composing state without inventing input. Replacement, disposal, runtime
loss and transaction rejection release composition tracking. File controls and
file-choice metadata are not authorized by the inherited path: no names, paths,
bytes, DataTransfer or file enumeration is added, and there is no implicit clear.

## Focus and selection

Capture only owned semantic identity and text range immediately before commit.
Stable keyed nodes retain focus through moves. Newly changed explicit autofocus
intent wins only within the active root (or an unowned body); it must not steal
focus from a sibling root. Disabled/hidden/incompatible targets are skipped.
When an owned target disappears, the nearest surviving restore-previous scope
selects the next eligible declared order, optionally wrapping if authored;
otherwise restore to the scope/root fallback or nowhere. No keyboard trap is
installed; wrapping applies only to recovery, not native Tab behavior.

Changed semantic text ranges win after controlled value application. Compatible
unchanged ranges preserve the user's range/direction, clamped to current text
length; unsupported input types receive no range calls. Apply values, then
selection/focus with preventScroll, before recording the accepted journal.
Only committed intent is published; rollback restores the pre-commit draft and
focus without crossing roots. No post-commit effects are executed in this phase.

## Gates and exclusions

Active Linux Chrome/Firefox automation must cover complete interaction/render
cycles, conflicting edits, composition, selection, keyboard/pointer behavior,
rollback, rejection, cleanup and isolation. Mix/Node, conformance, source and
dependency gates, archive/generator checks, JSON and whitespace checks remain
required. Phase 7 becomes eligible but unauthorized only after they pass.

No BH-10 form products, BH-13 rich controls, BH-14 uploads, styling, public API,
performance or support claims. Real ERTS evidence is distinct from a packaged
AtomVM/Wasm endpoint. [DEFERRED] Physical IME, unavailable OS/device/browser and
manual assistive-technology pairing remain with platform/device/accessibility
qualification owners, reactivating by BH-22 under the development policy.
