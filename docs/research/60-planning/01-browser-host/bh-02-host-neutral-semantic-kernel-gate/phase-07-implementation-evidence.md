---
title: "BH-02 Phase 7 implementation evidence"
kind: note
created: "2026-09-05"
maturity: stable
tags:
  - bh-02
  - conformance
  - evidence
  - gtk
  - native-controls
  - renderer
aliases:
  - "BH-02 Phase 7 evidence"
---

# BH-02 Phase 7 implementation evidence

## Outcome

**Passed within the authorized development boundary.** The [Phase 7
plan](phase-07-direct-native-control-portability-spike.md) now has a bounded
native-spike renderer that lowers the same semantic output used by the
headless and DOM renderers into deterministic complete native-control batches.
The available Linux adapter compiled directly against GTK 4.14.5 and passed
under Xvfb with real GTK objects.

This is experimental portability evidence, not a production native backend or
native-host support claim. Windows and macOS compilation and execution remain
deferred because governed environments are unavailable. Platform
accessibility-tree inspection, screen readers, IME, file-dialog interaction,
geometry, pixels, performance, packaging, and broad component coverage remain
unqualified.

## Authorization and delivery

- Authorization: `BX-BH02-PHASE-07-AUTHORIZATION-0.1`
- Authorized date: 2026-09-05
- Synchronized base: `966fd5c8406cb03fb392c6ba83015ab2e9eb56ac`
- Feature branch: `codex/bh-02-phase-07-native-control-spike`
- Delivery: four ordered sections, one commit per section, one pull request

| Section | Commit | Result |
| --- | --- | --- |
| 7.1 — Authorization and contract envelope | `8dee03f` | Phase 6, ADR-0007, direct native architecture, platform sources, and exact evidence boundary bound |
| 7.2 — Portable native experiment backend | `bcac88b` | deterministic complete batches, closed BXN1 wire protocol, lifecycle, and portable lowering implemented |
| 7.3 — Direct adapters and GTK execution | `c3f41b9` | Win32 and AppKit sources added as deferrals; direct GTK 4 adapter compiled and passed locally |
| 7.4 — Reconciliation and evidence | this evidence commit | headless/DOM/native parity, fixtures, ledgers, fail-closed validation, and complete inherited gate recorded |

## Implemented boundary

- `experiments/native_renderer_spike` depends only on `blazex_core`,
  `blazex_effects`, `blazex_ui_tree`, and `blazex_renderer` and has no external
  package dependency.
- The renderer lowers all seven semantic node kinds, stack intent,
  accessibility, bindings, focus, selection, validation relationships, and
  file-choice effect intent without platform objects crossing the boundary.
- Complete mount, update, replacement, and disposal batches carry owner,
  generation, revision, transition, root, and deterministic SHA-256 digest.
- The closed BXN1 boundary rejects unknown records, kind/role/layout values,
  malformed hex, excessive bounds, invalid tree structure, duplicate IDs,
  stale updates, and trailing records before platform materialization.
- Independent direct Win32, AppKit, and GTK source adapters consume the same
  protocol. No shared cross-platform widget toolkit is used.

## Direct GTK evidence

The [GTK result](../../../../../experiments/native_renderer_spike/gtk4-result-v0.1.0.json)
records ten materialized controls: `GtkWindow`, `GtkBox`, four `GtkLabel`
instances, `GtkButton`, `GtkEntry`, `GtkCheckButton`, and `GtkListBox`. A
`GtkFileDialog` service object was also created for the opaque file-choice
intent.

The run observed one activate event, one change event, three selection events,
the controlled `Ada` entry and `0..3` text range, checked state, keyed list
selection, GTK root focus, stale-update rejection before mutation, and exactly
one disposal across two cleanup requests. The environment was Linux x86-64,
GTK 4.14.5, GLib 2.80.0, GCC 13.3.0, and `xvfb-run -a`.

GTK-derived accessible roles were recorded rather than normalized away. The
window, box, list-item labels, and status label expose GTK defaults that do not
yet equal every requested semantic role. That is an adapter finding for later
work, not a passing platform-accessibility claim.

## Cross-renderer conformance

The [native fixture set](../../../../../integration/conformance/native-control-fixtures-v0.1.0.json)
contains twenty-two scenarios spanning capabilities, all node kinds,
determinism, strict wire behavior, lifecycle, stale rejection, accessibility,
logical layout, focus, controlled text/checkbox/list selection, semantic
events, validation relationships, file choice, headless/DOM/native parity,
direct GTK execution, and governed deferrals.

The executable integration suite verifies that all three renderer paths retain
the same semantic kind order and source identities, binding set, focus and
selection counts, relationship targets, and lifecycle coordinates. Backend ID
encodings remain private, logical layout is compared without geometry, and no
pixel equivalence is inferred.

## Tool and validation environment

- Linux x86-64 development host, kernel 6.8.0-51-generic
- Erlang/OTP 27, Elixir and Mix 1.18.4
- Node.js 24.3.0 and npm 11.4.2
- Python 3.12.12, Git 2.49.0, jq 1.7
- GCC 13.3.0, GTK 4.14.5, GLib 2.80.0, Xvfb
- Google Chrome 140.0.7339.80 and Mozilla Firefox 134.0

| Gate | Result |
| --- | --- |
| `mix format --check-formatted` and `mix test` in ten activated Mix projects | passed; 91 tests |
| DOM JavaScript syntax/build and Node driver suite | passed; 7 tests |
| Real-page active Linux Chrome and Firefox matrix | passed; 7 checks per browser |
| Direct GTK build and execution under Xvfb | passed; 10 controls, 1 service object, all required observations |
| Phase 1–7 BH-02 validators and focused negative tests | passed; Phase 7 adds 18 negative tests |
| Archive, BH-00, BH-01, generated-record, JSON, no-lock, and patch-hygiene gates | passed |

The normalized command record is retained in [the Phase 7 validation
log](../../../assets/bh-02-baseline/blazex-bh-02-phase-07-validation-log-v0.1.0.txt).

## Bound artifact hashes

| Artifact | SHA-256 |
| --- | --- |
| Phase 7 authorization | `4b9e0557c10ad41fc8bc8c00f7551962ff0f3c9da9f848b31c47fe52806b6b49` |
| Phase 7 contract | `653fcd52018e3948cbb3336cde12371b3b7e55946498dc6adf61e3b2b930018f` |
| Phase 7 output ledger | `2d953c2ab3cae82a134209a06372632b223953d5c8a0d32e7135044f5023388b` |
| Native fixture set | `ba75baa9a4a4c306ac2d06b300ec2f5d951818ee48d808cc621b45c00ba4fa58` |
| Native experiment index | `8ec4f7922c4ab4825b0edd1a06ef9c759c0de4696700dc3de22bfae71332e575` |
| Direct GTK result | `3c2a5df17a899b427e909c393e8a159eed6f8a19bd62361015da13ff774578f5` |
| Phase 7 conformance index | `e163e595a4e24b1d6a22d380dcf5c2e9bd96b0af5e01a13ae0f1b9f3736d92b5` |

## Decision

The Phase 7 gate passes with no exception inside its active Linux development
scope. Windows and macOS stay deferred, and the observed GTK role gaps remain
open adapter findings. Phase 8 is planned but unauthorized; no stable API,
production native renderer, platform accessibility, native-host support,
product, release, or support claim is implied.

## Connections

- [ADR-0007 — Native-control portability gate](../../../20-notes/architecture-decisions/adr-0007-native-control-portability-gate.md)
- [Direct native-host architecture](../../../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Cross-renderer inquiry](../../../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
