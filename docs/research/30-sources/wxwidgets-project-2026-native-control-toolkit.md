---
title: "wxWidgets cross-platform native-control toolkit"
kind: source
created: "2026-09-03"
authors:
  - "wxWidgets contributors"
published: null
citation_key: "wxwidgets-project-2026-native-controls"
container: "wxWidgets website, documentation, and source"
edition: "wxWidgets 3.2.11 stable; 3.3.3 development"
isbn: null
doi: null
url: "https://wxwidgets.org/about/"
accessed: "2026-09-03"
tags:
  - accessibility
  - desktop
  - native-controls
  - toolkit
  - wxwidgets
aliases:
  - "wxWidgets native portability proof"
---

# wxWidgets cross-platform native-control toolkit

## Reference

wxWidgets contributors. [Project overview](https://wxwidgets.org/about/),
[general FAQ](https://wxwidgets.org/docs/faq/general/), [accessibility
tutorial](https://wxwidgets.org/docs/tutorials/accessibility/), [downloads
and releases](https://wxwidgets.org/downloads/), and [license
overview](https://wxwidgets.org/about/). [Configure
source](https://github.com/wxWidgets/wxWidgets/blob/master/configure.ac) and
[macOS custom-renderer accessibility issue 26808](https://github.com/wxWidgets/wxWidgets/issues/26808).
[Release announcement](https://wxwidgets.org/news/2026/07/wxwidgets-3.2.11-and-3.3.3-released/),
2026-07-07. Evidence baseline distinguishes 3.2.11 as the stable series and
3.3.3 as a development release. Accessed 2026-09-03.

## Research question or contribution

Can wxWidgets prove that BlazeX's semantic ABI maps to actual native controls
on Win32, Cocoa, and GTK?

## Findings

- wxWidgets defines one C++ API over platform ports and uses native platform
  controls and utilities where available. The relevant desktop ports are
  Win32, Cocoa, and GTK.
- The project also contains generic and owner-drawn controls, so native
  ownership is not universal and must be classified per component.
- Native stock controls inherit substantial platform text, IME, focus,
  automation, and appearance behavior. wxWidgets' documented cross-platform
  accessibility abstraction is less complete; its tutorial remains heavily
  Windows/MSAA-oriented, and current custom-renderer issues show that a native
  container does not make owner-drawn content accessible.
- The wxWindows license permits proprietary static or dynamic linking without
  requiring the application's source to be released.
- Distribution is source-build-oriented and a BlazeX integration needs a
  narrow C shim or sidecar protocol.

## Relevance

**Current BlazeX disposition (2026-09-04): excluded.** This note is retained
as historical evidence for a superseded proof proposal. wxWidgets is not an
active implementation, proof, benchmark, dependency, or fallback candidate.
The direct Win32/AppKit/GTK program now supplies the ADR-0007 actual-control
proof path.

## Limits

No native object inspection or accessibility test was run. The cited issue is
one current example, not a systematic quality measurement. Platform ports can
differ in feature and release cadence. Findings from 3.3.3 development code
must not be assumed present in the 3.2.11 stable series without verification.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [ADR-0007 native-control portability gate](../20-notes/architecture-decisions/adr-0007-native-control-portability-gate.md)
- [Cross-renderer portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
- [2026-09-04 direct native-control host revision](../50-journal/2026-09-04-direct-native-control-host-revision.md)
