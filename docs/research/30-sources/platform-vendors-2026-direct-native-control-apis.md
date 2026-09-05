---
title: "Direct Windows, AppKit, and GTK native-control APIs"
kind: source
created: "2026-09-04"
authors:
  - "Microsoft"
  - "Apple"
  - "GNOME Foundation"
  - "GTK contributors"
published: null
citation_key: "platform-vendors-2026-direct-native-controls"
container: "Microsoft Learn, Apple Developer Documentation, and GTK 4 API documentation"
edition: "Windows and AppKit documentation current 2026-09-04; GTK 4.23.3 documentation snapshot"
isbn: null
doi: null
url: "https://learn.microsoft.com/en-us/windows/win32/controls/window-controls"
accessed: "2026-09-04"
tags:
  - accessibility
  - appkit
  - desktop
  - gtk
  - native-controls
  - win32
aliases:
  - "Direct platform native-control evidence"
---

# Direct Windows, AppKit, and GTK native-control APIs

## Question

Can BlazeX prove its actual-native-control requirement without depending on a
cross-platform widget wrapper?

## References

### Windows

- [Windows Controls](https://learn.microsoft.com/en-us/windows/win32/controls/window-controls)
- [About Buttons](https://learn.microsoft.com/en-us/windows/win32/controls/about-buttons)
- [Edit Controls](https://learn.microsoft.com/en-us/windows/win32/controls/edit-controls)
- [About Windows](https://learn.microsoft.com/en-us/windows/win32/winmsg/about-windows)
- [Window Features](https://learn.microsoft.com/en-us/windows/win32/winmsg/window-features)
- [UI Automation Providers Overview](https://learn.microsoft.com/en-us/windows/win32/winauto/uiauto-providersoverview)

### macOS

- [NSApplication](https://developer.apple.com/documentation/appkit/nsapplication)
- [Views and Controls](https://developer.apple.com/documentation/appkit/views-and-controls)
- [NSControl](https://developer.apple.com/documentation/appkit/nscontrol)
- [NSTextField](https://developer.apple.com/documentation/appkit/nstextfield)
- [NSWindow](https://developer.apple.com/documentation/appkit/nswindow)
- [Accessibility for AppKit](https://developer.apple.com/documentation/appkit/accessibility-for-appkit)
- [NSOpenPanel](https://developer.apple.com/documentation/appkit/nsopenpanel)

### Linux

- [GTK accessibility](https://docs.gtk.org/gtk4/section-accessibility.html)
- [GtkAccessible](https://docs.gtk.org/gtk4/iface.Accessible.html)
- [GtkButton](https://docs.gtk.org/gtk4/class.Button.html)
- [GtkEntry](https://docs.gtk.org/gtk4/class.Entry.html)
- [GTK threading](https://docs.gtk.org/gtk4/section-threading.html)
- [GTK initialization](https://docs.gtk.org/gtk4/initialization.html)
- [GtkApplicationWindow](https://docs.gtk.org/gtk4/class.ApplicationWindow.html)

## Supported findings

### Windows: Win32 standard and common controls

Windows controls are windows, normally child windows, created and managed
through the Win32 window/message model. Buttons and edit controls therefore
provide concrete `HWND`-owned resources for the F0 proof rather than merely
native-looking pixels. The thread that creates a window owns its window
procedure and message dispatch, which supports keeping all control resources
inside the native host's UI thread. Destroying a parent window destroys its
descendants and invalidates their handles, so BlazeX must pair every opaque
resource identity with generation-safe disposal and stale-event rejection.

Microsoft supplies UI Automation providers for standard Win32 controls.
Custom or owner-drawn controls may require server-side providers. This makes
standard controls a useful baseline, but it does not prove BlazeX-specific
names, relationships, validation semantics, or complex custom controls.

### macOS: AppKit controls

`NSApplication` owns application event processing, windows, menus, and event
distribution. `NSControl` supplies the target-action control model, while
classes such as `NSTextField` provide concrete platform controls. `NSWindow`
and AppKit UI work are main-thread-bound, reinforcing the separate native
process and UI-thread ownership rule.

Standard AppKit controls include accessibility behavior. Custom controls need
the appropriate accessibility role protocols and values. `NSOpenPanel`
provides a platform-owned file-choice capability without exposing filesystem
paths or AppKit objects to portable component state.

### Linux: GTK 4 controls and AT-SPI

GTK is the direct platform toolkit for the Linux proof. GTK applications are
event-driven, and most GTK objects and widgets must remain on the main thread.
Standard widgets including `GtkButton`, `GtkEntry`, and `GtkListView` expose
accessibility information by default. `GtkAccessible` provides roles, states,
properties, relations, and platform accessibility integration.

GTK is not evidence for Windows or macOS control ownership in this design. It
is one of three deliberately separate platform adapters, alongside Win32 and
AppKit.

## BlazeX relevance

The same semantic fixture can be materialized by three small hosts:

| Target | Control API | Accessibility path | UI-loop owner |
| --- | --- | --- | --- |
| Windows | Win32 standard/common controls | built-in UI Automation providers plus explicit providers when custom | Win32 message-loop thread |
| macOS | AppKit `NSControl` subclasses and platform panels | built-in AppKit accessibility plus explicit custom-control protocols | `NSApplication` main thread |
| Linux | GTK 4 widgets and services | GTK accessibility mapped to AT-SPI | GTK/GLib main thread |

All three adapters can consume the same versioned semantic
snapshot/patch/event/effect protocol. Platform objects, pointers, callbacks,
and widget types stay behind the adapter boundary. Conformance should compare
semantic state, event order, identity, focus, accessibility relationships,
resource ownership, and disposal—not exact geometry or pixels.

## Limits

- This source pass did not compile or run a platform adapter.
- The exact Windows SDK, macOS SDK, deployment target, GTK release, Linux
  desktop, display server, and assistive technology remain spike inputs.
- Built-in accessibility providers do not automatically supply correct
  application semantics or complete complex-control behavior.
- Three direct implementations increase engineering, packaging, and test cost.
- “Native control” is platform-specific: Win32 and AppKit expose OS frameworks;
  GTK is the selected Linux desktop toolkit and must be tested on named Linux
  environments rather than treated as universal Linux behavior.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Host-neutral and native-renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md)
- [Can one BlazeX component model target DOM and native controls?](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
- [2026-09-04 direct native-control host revision](../50-journal/2026-09-04-direct-native-control-host-revision.md)
