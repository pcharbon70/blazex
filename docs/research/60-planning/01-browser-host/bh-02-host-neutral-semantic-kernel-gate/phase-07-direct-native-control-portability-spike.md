---
title: "Phase 7 - Direct Native-Control Portability Spike"
kind: note
created: "2026-09-05"
maturity: developing
tags:
  - bh-02
  - conformance
  - gtk
  - implementation-planning
  - native-controls
  - portability
aliases:
  - "BH-02 phase 7"
---

# Phase 7 - Direct Native-Control Portability Spike

Back to milestone: [README](README.md)

- [x] 7 Phase - Direct Native-Control Portability Spike.

  Exercise the established semantic and renderer contracts against actual
  platform controls without choosing a production desktop backend. Compile and
  execute GTK 4 in the available Linux environment; retain Windows/macOS and
  manual accessibility work as governed deferrals. Exclude Qt and wxWidgets.

  - [x] 7.1 Section - Authorize and freeze the native experiment.

    - [x] 7.1.1 Task - Bind authority, environment, and delivery.

      - [x] 7.1.1.1 Subtask - Record synchronized base, branch, four commits, one merged PR, synchronized-main return, and local/remote cleanup.
      - [x] 7.1.1.2 Subtask - Bind Phase 6 completion, ADR-0007, direct-native architecture, inquiry, source evidence, and deferral policy by path and SHA-256.
      - [x] 7.1.1.3 Subtask - Keep Phase 8, production native packages/profiles, stable APIs, support, Qt, wxWidgets, and custom-scene work unauthorized.

    - [x] 7.1.2 Task - Freeze exact native projection and evidence contracts.

      - [x] 7.1.2.1 Subtask - Freeze the experiment-only dependency boundary, capabilities, batch/node fields, protocol, semantic slice, and platform mappings.
      - [x] 7.1.2.2 Subtask - Require actual GTK 4 controls and automated Linux observations under Xvfb.
      - [x] 7.1.2.3 Subtask - Mark Windows/macOS execution, platform accessibility trees, manual screen readers, IME, file-dialog interaction, geometry, pixels, performance, and packaging deferred.

  - [x] 7.2 Section - Implement the portable native experiment backend.

    - [x] 7.2.1 Task - Lower semantic output to a closed native-control batch.

      - [x] 7.2.1.1 Subtask - Activate only the experiment Mix project over the four neutral packages and implement bounded capabilities.
      - [x] 7.2.1.2 Subtask - Lower all seven semantic node kinds, stack intent, accessibility, bindings, focus, selection, and file-choice intent without platform objects.
      - [x] 7.2.1.3 Subtask - Implement deterministic identity/digest, mount/update/replace/dispose lifecycle, stale rejection, and idempotent cleanup.

    - [x] 7.2.2 Task - Encode a strict platform boundary.

      - [x] 7.2.2.1 Subtask - Encode complete validated batches through the closed BXN1 tab-separated hex-UTF-8 protocol.
      - [x] 7.2.2.2 Subtask - Reject unknown records, kinds, fields, controls, invalid relationships, excessive depth/count/value, and forbidden host data.
      - [x] 7.2.2.3 Subtask - Test deterministic output and all representative slice mappings without loading a platform API.

  - [x] 7.3 Section - Implement direct platform adapters and execute GTK 4.

    - [x] 7.3.1 Task - Add three independent direct-platform materializers.

      - [x] 7.3.1.1 Subtask - Implement direct Win32 standard/common control source with no shared toolkit; retain compile/run as deferred.
      - [x] 7.3.1.2 Subtask - Implement direct AppKit control source with no shared toolkit; retain compile/run as deferred.
      - [x] 7.3.1.3 Subtask - Implement a header-independent direct GTK 4 runtime-ABI adapter and reproducible local build.

    - [x] 7.3.2 Task - Execute the available native-control proof.

      - [x] 7.3.2.1 Subtask - Materialize a real GtkWindow, GtkBox, GtkLabel, GtkButton, GtkEntry, GtkCheckButton, and GtkListBox under Xvfb.
      - [x] 7.3.2.2 Subtask - Observe control types, events, focus, entry/checkbox/list selection, accessible roles, stale rejection, and idempotent disposal.
      - [x] 7.3.2.3 Subtask - Record exact GTK/GLib/compiler/display versions and preserve unavailable platform work as deferrals rather than passes.

  - [x] 7.4 Section - Run cross-renderer reconciliation and publish evidence.

    - [x] 7.4.1 Task - Compare the headless, DOM, and native-spike surfaces.

      - [x] 7.4.1.1 Subtask - Publish versioned native scenarios and exact platform result rows.
      - [x] 7.4.1.2 Subtask - Compare kinds, identity, events, focus, selection, relationships, lifecycle, stale rejection, and disposal without requiring geometry/pixel equality.
      - [x] 7.4.1.3 Subtask - Record semantic findings and keep platform differences behind the experiment boundary.

    - [x] 7.4.2 Task - Execute and record the complete Phase 7 gate.

      - [x] 7.4.2.1 Subtask - Run all activated tests/formats, GTK build/run, Phase 1–7 and inherited validators, archive checks, JSON checks, and patch hygiene.
      - [x] 7.4.2.2 Subtask - Add fail-closed validation and negative tests for authority, hashes, surfaces, forbidden toolkits, false platform passes, and premature support or Phase 8 claims.
      - [x] 7.4.2.3 Subtask - Publish a truthful pass or stop decision and leave Phase 8 unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open and merge one pull
request only after Section 7.4 passes or records a stop decision. Experiment
code remains disposable and cannot become a production dependency or support
claim.

## Connections

- [BH-02 plan](README.md)
- [ADR-0007 — Native-control portability gate](../../../20-notes/architecture-decisions/adr-0007-native-control-portability-gate.md)
- [Direct native-host architecture](../../../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Cross-renderer inquiry](../../../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
- [Phase 7 implementation evidence](phase-07-implementation-evidence.md)

## Sources

- [Direct Windows, AppKit, and GTK native-control APIs](../../../30-sources/platform-vendors-2026-direct-native-control-apis.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
