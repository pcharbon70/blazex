---
title: "Qt 6 desktop UI, rendering, input, and accessibility platform"
kind: source
created: "2026-09-03"
authors:
  - "The Qt Company"
  - "Qt contributors"
published: null
citation_key: "qt-project-2026-desktop-ui-platform"
container: "Qt 6.11 documentation and qtbase source"
edition: "Qt 6.11"
isbn: null
doi: null
url: "https://doc.qt.io/qt-6/topics-ui.html"
accessed: "2026-09-03"
tags:
  - accessibility
  - desktop
  - qt
  - rendering
  - toolkit
aliases:
  - "Qt native host evidence"
---

# Qt 6 desktop UI, rendering, input, and accessibility platform

## Reference

The Qt Company and Qt contributors. [User interfaces](https://doc.qt.io/qt-6/topics-ui.html),
[supported platforms](https://doc.qt.io/qt-6/supported-platforms.html),
[graphics](https://doc.qt.io/qt-6/topics-graphics.html), [accessibility](https://doc.qt.io/qt-6/accessible.html),
[QAccessible](https://doc.qt.io/qt-6/qaccessible.html), [input methods](https://doc.qt.io/qt-6/qinputmethod.html),
[high DPI](https://doc.qt.io/qt-6/highdpi.html), [threading](https://doc.qt.io/qt-6/threads-qobject.html),
[deployment](https://doc.qt.io/qt-6/deployment.html), and [licensing](https://doc.qt.io/qt-6/licensing.html).
Accessed 2026-09-03.

## Research question or contribution

Could Qt provide a complete three-OS host and renderer, and would it satisfy
BlazeX's actual-native-control goal?

## Findings

- Qt officially supports defined Windows, macOS, and Linux configurations and
  supplies two relevant UI systems: mature Qt Widgets and a GPU-backed Qt
  Quick scene graph.
- Qt integrates input methods, focus, keyboard navigation, high-DPI
  coordinates, text, graphics backends, and an accessibility object tree.
  Built-in controls expose accessibility metadata; custom controls can
  implement accessible interfaces and events.
- Qt's RHI abstracts Direct3D, Metal, Vulkan, and OpenGL for its own rendering
  layers.
- “Native look and feel” is not the same as OS-owned controls. QStyle can
  emulate platform styles, and QWidget documents that most child widgets are
  non-native or “alien” unless native-window creation is forced.
- Qt is available under commercial, LGPLv3, and GPLv3 arrangements; some
  modules are GPL-only in the open-source distribution. Deployment includes
  Qt libraries and platform/accessibility plugins.

## Relevance

**Current BlazeX disposition (2026-09-04): excluded.** This note is retained
as historical evidence for a superseded comparison. Qt is not an active
implementation, proof, benchmark, dependency, or fallback candidate. The
findings still explain why native-looking widgets cannot be counted as actual
OS-control proof merely because they look and behave conventionally.

## Limits

No Qt build, license analysis, binary measurement, or accessibility test was
performed. Qt Widgets and Qt Quick have materially different rendering and
interaction models and must be evaluated separately.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Cross-renderer portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
- [2026-09-04 direct native-control host revision](../50-journal/2026-09-04-direct-native-control-host-revision.md)
