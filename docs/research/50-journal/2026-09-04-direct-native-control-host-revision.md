---
title: "2026-09-04 direct native-control host revision"
kind: journal
created: "2026-09-04"
tags:
  - appkit
  - desktop
  - gtk
  - native-controls
  - research-revision
  - win32
aliases:
  - "Direct platform native-host research revision"
---

# 2026-09-04 direct native-control host revision

## Observation

The 2026-09-03 native-host study left wxWidgets as the leading actual-control
proof and Qt as an integration oracle. The current design constraint excludes
both systems from implementation and proof work. ADR-0007 does not require a
cross-platform wrapper; it requires the same portable slice to create and
exercise real native controls.

## Environment and method

- Workspace: BlazeX research corpus at the 2026-09-04 working tree.
- Research type: documentation-only design revision; no native code compiled.
- Sources: current Microsoft Learn and Apple Developer documentation accessed
  2026-09-04, plus the GTK 4.23.3 documentation snapshot.
- Historical evidence: the Qt and wxWidgets source notes and the 2026-09-03
  journal entry were retained rather than rewritten.

## Evidence

- Win32 standard controls are child-window resources owned by the creating
  thread and have Microsoft-supplied UI Automation providers.
- AppKit's application, window, control, target-action, accessibility, and
  panel APIs supply the corresponding macOS path on the application main
  thread.
- GTK 4 widgets, GLib event processing, and GTK accessibility supply the Linux
  path, with most widget work restricted to the main thread.
- These three paths can be placed behind one BlazeX semantic protocol without
  placing platform widget types in portable components.

## Decision recorded in the developing synthesis

1. Use direct Win32, AppKit, and GTK 4 adapters for the ADR-0007
   actual-native-control proof.
2. Give all three adapters the same bounded F0 semantic fixture and event,
   focus, accessibility, resource, failure, and disposal traces.
3. Keep SDL3/Skia as a separate custom-scene research path. It is not the
   owner of direct platform controls.
4. Exclude Qt and wxWidgets from active selection, prototyping, dependencies,
   integration benchmarking, and fallback recommendations.
5. Retain older Qt and wxWidgets notes only as historical evidence explaining
   the superseded comparison.

## What was not demonstrated

- No Win32, AppKit, or GTK adapter was compiled or run.
- No screen-reader, IME, packaging, cold-start, memory, or binary-size evidence
  was collected.
- No claim is made that the three adapters will share implementation code
  beyond protocol, fixtures, generated bindings, and conformance tests.
- No claim is made that GTK represents every Linux desktop configuration.

## Follow-ups

- Pin concrete SDK, compiler, GTK, OS, desktop, display-server, and assistive-
  technology versions for executable Gate C evidence.
- Define the common F0 fixture and platform control-class inventory.
- Measure adapter-specific code, extension points, lifecycle failures, and
  semantic divergence before expanding the native-control catalog.

## Threads

- [Direct Windows, AppKit, and GTK native-control APIs](../30-sources/platform-vendors-2026-direct-native-control-apis.md)
- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Can one BlazeX component model target DOM and native controls?](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
